// SPDX-License-Identifier: UNLICENSED 
pragma solidity >=0.8.19;

interface IClientSecretManager {
    function checkClientSecret(string calldata context, string calldata clientSecret) external view returns (bool);
}

contract BloodPointsBank {

    address payable owner;
    address gameTraderContractAddr;
    address classificaContractAddr;
    uint bpValue = 333333333333; //TODO: assegnare un valore sensato.
    
    string context = "No chance to survive";
    address clientSecretManager;

    //La quantità di BloodPoints in circolazione inizialmente la imposto al numero totale di Euro in circolo: 1.5 * 10^3 * 1.000.000.000 = 1.500.000.000.000;
    mapping(address => uint) balance;

    constructor(){
        owner = payable(msg.sender);
        balance[address(this)] = 1500000000000;
    }

    fallback() external payable {
        buyMax();
    }

    receive() external payable {
        buyMax();
    }

    function setClientSecretManagerContractAddress(address addr) public {
        require(msg.sender == owner);
        clientSecretManager = addr;
    }

    function setGameTraderContractAddress(address addr) public {
        require(msg.sender == owner);
        gameTraderContractAddr = addr;
    }

    function setClassificaContractAddress(address addr) public {
        require(msg.sender == owner);
        classificaContractAddr = addr;
    }

    function buyMax() private {
        require(msg.value >= bpValue);
        uint bpAmount = msg.value / bpValue;
        buy(bpAmount);
    }

    function buy(uint amount) public payable {
        require(msg.value >= bpValue * amount);
        (payable(msg.sender)).transfer(msg.value - (bpValue * amount));
        this.sendBP(msg.sender, amount);
    }

    function setBPValue(uint value) public {
        require(msg.sender == owner);
        bpValue = value;
    }

    function getBPValue() public view returns(uint value){
        return bpValue;
    }

    //Inietta una data quantità di BloodPoints (crearli).
    function injectBP(uint amount) public {
        require(msg.sender == owner, "Permesso negato.");
        balance[address(this)] += amount;
    }

    //Brucia una data quantità di BloodPoints (distruggerli).
    function burnBP(uint amount) public {
        require(msg.sender == owner);
        balance[address(this)] -= amount;
    }

    function moveBP(address from, address to, uint amount) external {
        require(msg.sender == address(this) || msg.sender == owner || msg.sender == gameTraderContractAddr);
        this.moveBPAuth(from, to, amount, "");
    }

    function moveBPAuth(address from, address to, uint amount, string calldata clientSecret) external {
        bool hasSecret = false;
        if(clientSecretManager != address(0)){
            IClientSecretManager csm = IClientSecretManager(clientSecretManager);
            hasSecret = csm.checkClientSecret(context, clientSecret);
        }
        require((msg.sender == address(this) || msg.sender == owner || msg.sender == gameTraderContractAddr || hasSecret) && balance[from] >= amount, "Transazione non valida.");
        if(msg.sender == to){
            return;
        }
        balance[from] -= amount;
        balance[to] += amount;
    }

    function sendBP(address to, uint amount) external {
        // balance[msg.sender] -= amount;
        // balance[to] += amount;
        this.moveBP(msg.sender, to, amount);
    }

    function getBalance(address addr) external view returns(uint userBalance) {
        return balance[addr];
    }

}