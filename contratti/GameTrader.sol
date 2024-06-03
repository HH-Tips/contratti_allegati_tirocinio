// SPDX-License-Identifier: UNLICENSED 
pragma solidity >=0.8.19;

interface IBloodPointsBank {
    function getBalance(address addr) external view returns(uint balance);
    function sendBP(address to, uint amount) external;
    function moveBP(address from, address to, uint amount) external;
}

interface IGameData {
    function addItemAmountToPlayer(address player, uint itemId, uint16 amount) external;
    function removeItemAmountToPlayer(address player, uint itemId, uint16 amount) external;
    function getPlayerItems(address player) external view returns(uint16[100] memory items);
}

contract GameTrader {

    address payable owner;
    address gameDataContractAddr;
    address bloodPointsBankContractAddr;

    struct Trade {
        address payable from;
        address payable to;
        Offer offer;
        Offer request;
        uint timestamp;
    }

    struct Offer {
        uint bloodPoints;
        uint16[] itemIds;
        uint16[] amounts;
    }

    mapping(address => Trade[]) pendingTrades;
    mapping(address => Trade[]) trades;

    constructor() {
        owner = payable(msg.sender);
    }

    //Imposta l'address dello smart contract che contiene le informazioni sui giocatori.
    function setGameDataContractAddress(address addr) public {
        require(msg.sender == owner);
        gameDataContractAddr = addr;
    }

    //Imposta l'address dello smart contract che gestisce i blood points.
    function setBloodPointsBankContractAddress(address addr) public {
        require(msg.sender == owner);
        bloodPointsBankContractAddr = addr;
    }

    function getPendingTrade(uint index) public view returns(Trade memory trade) {
        require(index < pendingTrades[msg.sender].length);
        return pendingTrades[msg.sender][index];
    }

    function getPendingTrades() public view returns(Trade[] memory pending) {
        pending = new Trade[](pendingTrades[msg.sender].length);
        for(uint i=0; i<pendingTrades[msg.sender].length; i++){
            pending[i] = pendingTrades[msg.sender][i];
        }
        return pending;
    }

    function getTrade(uint index) public view returns(Trade memory trade) {
        require(index < trades[msg.sender].length);
        return trades[msg.sender][index];
    }

    function getTrades() public view returns(Trade[] memory myTrades){
        myTrades = new Trade[](trades[msg.sender].length);
        for(uint i=0; i<myTrades.length; i++){
            myTrades[i] = getTrade(i);
        }
        return myTrades;
    }

    //Registra una proposta di scambio (non necessariamente valida nel momento dell'invio, viene valutata solo durante l'accettazione).
    function proposeTrade(Trade memory tradeProposal) public {
        require(msg.sender == tradeProposal.from);
        require(tradeProposal.offer.itemIds.length == tradeProposal.offer.amounts.length);
        require(tradeProposal.request.itemIds.length == tradeProposal.request.amounts.length);

        // Trade memory trade = tradeProposal;
        tradeProposal.timestamp = block.timestamp;

        pendingTrades[msg.sender].push(tradeProposal);
        pendingTrades[tradeProposal.to].push(tradeProposal);
    }

    //Accetta la richiesta di scambio all'indice proposalIndex delle proprie pendingTrades.
    function acceptTradeOffer(uint proposalIndex) public {
        Trade memory proposal = pendingTrades[msg.sender][proposalIndex];
        require(msg.sender == proposal.to);
        if(isValidTradeProposal(proposal)){
            IBloodPointsBank bpBankContract = IBloodPointsBank(bloodPointsBankContractAddr);

            //Invio degli items da colui che ha effettuato la proposta a chi l'ha accettata.
            uint16[] memory itemsToReceive = proposal.offer.itemIds;
            uint16[] memory amountsToReceive = proposal.offer.amounts;
            sendItems(proposal.from, proposal.to, itemsToReceive, amountsToReceive);

            //Invio degli items da colui che ha accettato la proposta a chi l'ha mandata.
            uint16[] memory itemsToSend = proposal.request.itemIds;
            uint16[] memory amountsToSend = proposal.request.amounts;
            sendItems(proposal.to, proposal.from, itemsToSend, amountsToSend);

            //Trasferimento dei blood points.
            uint bpToSend = proposal.request.bloodPoints;
            uint bpToReceive = proposal.offer.bloodPoints;
            if(bpToSend > bpToReceive){
                uint amount = bpToSend - bpToReceive;
                bpBankContract.moveBP(proposal.to, proposal.from, amount);
            }
            else if(bpToSend < bpToReceive) {
                uint amount = bpToReceive - bpToSend;
                bpBankContract.moveBP(proposal.from, proposal.to, amount);
            }
        }

        //Salvo la transazione effettuata.
        trades[msg.sender].push(proposal);
        trades[proposal.from].push(proposal);

        //Tolgo la transazione dalla lista delle transazioni ancora in attesa di essere accettate/rifiutate.
        deleteTradeProposal(msg.sender, proposalIndex);
    }

    //Rifiutare o eliminare una proposta.
    function cancelTradeOffer(uint proposalIndex) public {
        deleteTradeProposal(msg.sender, proposalIndex);
    }

    //Valuta se una proposta è valida. (Ho fatto i controlli in questo modo schifoso per cercare di ridurre al minimo le operazioni per capire se la proposta è valida)
    function isValidTradeProposal(Trade memory proposal) private view returns(bool valid) {
        IGameData gdContract = IGameData(gameDataContractAddr);
        IBloodPointsBank bpBankContract = IBloodPointsBank(bloodPointsBankContractAddr);

        if(bpBankContract.getBalance(proposal.from) < proposal.offer.bloodPoints || bpBankContract.getBalance(proposal.to) < proposal.request.bloodPoints){
            return false;
        }

        uint16[100] memory senderAvailableItems = gdContract.getPlayerItems(proposal.from);
        bool validSender = verifyItemsAvailability(proposal.offer.itemIds, proposal.offer.amounts, senderAvailableItems);
        if(!validSender) return false;

        uint16[100] memory receiverAvailableItems = gdContract.getPlayerItems(proposal.to);
        return verifyItemsAvailability(proposal.request.itemIds, proposal.request.amounts, receiverAvailableItems);
    }

    function verifyItemsAvailability(uint16[] memory itemIds, uint16[] memory amounts, uint16[100] memory availableItems) private pure returns(bool valid) {
        for(uint16 i=0; i<itemIds.length; i++) {
            uint16 itemId = itemIds[i];
            uint16 amount = amounts[i];
            if(availableItems[itemId] < amount){
                return false;
            }
        }
        return true;
    }

    function sendItems(address from, address to, uint16[] memory items, uint16[] memory amounts) private {
        IGameData gdContract = IGameData(gameDataContractAddr);
        
        for(uint i=0; i<items.length; i++){
                uint16 itemId = items[i];
                uint16 amount = amounts[i];
                if(amount > 0){
                    gdContract.removeItemAmountToPlayer(from, itemId, amount);
                    gdContract.addItemAmountToPlayer(to, itemId, amount);
                }
        }
    }

    function deleteTradeProposal(address requestBy, uint proposalIndex) private {
        Trade storage proposal = pendingTrades[requestBy][proposalIndex];
        Trade[] storage pending;
        if(requestBy == proposal.from){
            pending = pendingTrades[proposal.to];
        }
        else {
            pending = pendingTrades[proposal.from];
        }
        for(uint i=0; i<pending.length; i++){
            if(equalsTrade(proposal, pending[i])){
                if(pending.length > 1){
                    pending[i] = pending[pending.length-1];
                }
                pending.pop();
                break;
            }
        }
        if(pendingTrades[requestBy].length > 1){
            pendingTrades[requestBy][proposalIndex] = pendingTrades[requestBy][pendingTrades[requestBy].length-1];
        }
        pendingTrades[requestBy].pop();
    }

    function equalsTrade(Trade memory t1, Trade memory t2) private pure returns(bool equals) {
        if(t1.timestamp != t2.timestamp){
            return false;
        }
        if(t1.from != t2.from || t1.to != t2.to){
            return false;
        }
        if(t1.offer.itemIds.length != t2.offer.itemIds.length || t1.request.itemIds.length != t2.request.itemIds.length){
            return false;
        }
        //Controllo che le offerte siano uguali.
        for(uint i=0; i<t1.offer.itemIds.length; i++){
            if(t1.offer.itemIds[i] != t2.offer.itemIds[i] || t1.offer.amounts[i] != t2.offer.amounts[i]){
                return false;
            }
        }
        if(t1.offer.bloodPoints != t2.offer.bloodPoints){
            return false;
        }
        //Controllo che le richieste siano uguali.
        for(uint i=0; i<t1.offer.itemIds.length; i++){
            if(t1.request.itemIds[i] != t2.request.itemIds[i] || t1.request.amounts[i] != t2.request.amounts[i]){
                return false;
            }
        }
        if(t1.request.bloodPoints != t2.request.bloodPoints){
            return false;
        }

        return true;
    }
}