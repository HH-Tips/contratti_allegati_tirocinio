// SPDX-License-Identifier: UNLICENSED 
pragma solidity >=0.8.19;

interface IClientSecretManager {
    function checkClientSecret(string calldata context, string calldata clientSecret) external view returns (bool);
}

contract GameData {

    struct Item {
        uint16 id;
        string name;
        uint value;
        uint neededLevel;
    }

    address payable owner;
    address gameTrader;

    string private constant context = "No chance to survive";
    address clientSecretManager;

    address[] registeredPlayers;
    mapping(string => address) _address;
    mapping(address => string) _username;
    mapping(address => uint16[100]) _playerItems;
    mapping(address => uint8[100]) _powerUps;
    Item[100] _items;

    constructor() {
        owner = payable(msg.sender);
    }

    //Imposta l'address dello smart contract che gestisce le richieste di scambio.
    function setGameTraderContractAddress(address addr) public {
        require(msg.sender == owner);
        gameTrader = addr;
    }

    function setClientSecretManagerContractAddress(address addr) public {
        require(msg.sender == owner);
        clientSecretManager = addr;
    }

    function getRegisteredPlayers(uint count, uint offset) public view returns(address[] memory players) {
        require(offset + count <= registeredPlayers.length && count < 200);
        players = new address[](count);
        for(uint i=0; i<count; i++){
            players[i] = registeredPlayers[offset + i];
        }
        return players;
    }

    //Restituisce la lista degli item.
    function getItemList() public view returns(Item[] memory items) {
        items = new Item[](_items.length);
        for(uint i=0; i<_items.length; i++){
            items[i] = _items[i];
        }
        return items;
    }

    //Restituisce le informazioni relative all'oggetto.
    function getItemInfo(uint16 id) external view returns (Item memory item){
        return _items[id];
    }

    function setItems(Item[] calldata items) public {
        require(msg.sender == owner);
        for(uint i=0; i<items.length; i++){
            setItem(items[i]);
        }
    }

    //Inserisce un nuovo item all'interno del gioco, o lo sovrascrive.
    function setItem(Item calldata item) public {
        require(msg.sender == owner && item.id < _items.length);
        // if(item.id == _items.length){
        //     _items.push();
        // }
        _items[item.id] = item;
    }

    //Rimuove un item dal gioco.
    function removeItem(uint id) public {
        require(msg.sender == owner);
        delete _items[id];
        for(uint i=0; i<registeredPlayers.length; i++){
            address playerAddr = registeredPlayers[i];
            delete _playerItems[playerAddr][id];
        }
    }

    function isRegisteredPlayer(address player) public view returns(bool) {
        return bytes(_username[player]).length > 0;
    }

    //Registra o rinomina un giocatore.
    function registerPlayer(string calldata username) public {
        require(_address[username] == address(0) && bytes(username).length >= 3);
        string memory prevUsername = _username[msg.sender];
        if(!equalsStrings(prevUsername, "")){
            _address[prevUsername] = address(0);
        }
        else{
            registeredPlayers.push(msg.sender);
        }
        _username[msg.sender] = username;
        _address[username] = msg.sender;
    }

    function getPlayerUsername(address player) public view returns(string memory username) {
        return _username[player];
    }

    function getPlayerAddressByUsername(string calldata username) public view returns(address player) {
        return _address[username];
    }

    //Restituisce le informazioni relative ad un giocatore.
    function playerInfo(address player) public view returns(address addr, string memory username, uint16[100] memory playerItems, uint8[100] memory powerUps) {
        username = _username[player];
        playerItems = _playerItems[player];
        powerUps = _powerUps[player];
        return (player, username, playerItems, powerUps);
    }

    //Restituisce le informazioni relative ad un giocatore.
    function playerInfoByUsername(string calldata name) public view returns(address addr, string memory username, uint16[100] memory playerItems) {
        address player = _address[name];
        playerItems = _playerItems[player];
        return (player, name, playerItems);
    }

    function addItemAmountToPlayer(address player, uint itemId, uint16 amount) external {
        require(msg.sender == owner || msg.sender == gameTrader);
        this.addItemAmountToPlayerAuth(player, itemId, amount, "");
    }

    //Aggiunge la quantità specificata di un dato item al giocatore.
    function addItemAmountToPlayerAuth(address player, uint itemId, uint16 amount, string calldata clientSecret) external {
        bool hasSecret = false;
        if(clientSecretManager != address(0)){
            IClientSecretManager csm = IClientSecretManager(clientSecretManager);
            hasSecret = csm.checkClientSecret(context, clientSecret);
        }
        require((msg.sender == owner || msg.sender == gameTrader || msg.sender == address(this) || hasSecret) && amount > 0);
        _playerItems[player][itemId] += amount;
    }

    function removeItemAmountToPlayer(address player, uint itemId, uint16 amount) external {
        require(msg.sender == owner || msg.sender == gameTrader);
        this.removeItemAmountToPlayerAuth(player, itemId, amount, "");
    }

    //Rimuove la quantità specificata di un dato item al giocatore.
    function removeItemAmountToPlayerAuth(address player, uint itemId, uint16 amount, string calldata clientSecret) external {
        bool hasSecret = false;
        if(clientSecretManager != address(0)){
            IClientSecretManager csm = IClientSecretManager(clientSecretManager);
            hasSecret = csm.checkClientSecret(context, clientSecret);
        }
        require((msg.sender == owner || msg.sender == gameTrader || msg.sender == address(this) || hasSecret) && amount > 0);
        _playerItems[player][itemId] -= amount;
    }

    function setItemAmountToPlayer(address player, uint itemId, uint16 amount) public {
        require(msg.sender == owner);
        this.setItemAmountToPlayerAuth(player, itemId, amount, "");
    }

    //Imposta la quantità specificata di un dato item al giocatore.
    function setItemAmountToPlayerAuth(address player, uint itemId, uint16 amount, string calldata clientSecret) public {
        bool hasSecret = false;
        if(clientSecretManager != address(0)){
            IClientSecretManager csm = IClientSecretManager(clientSecretManager);
            hasSecret = csm.checkClientSecret(context, clientSecret);
        }
        require(msg.sender == owner || msg.sender == address(this) || hasSecret);
        _playerItems[player][itemId] = amount;
    }

    function addPowerUpsToPlayer(address player, uint[] calldata powerUpsId, uint8[] calldata powerUpsLevel) external {
        require(msg.sender == owner);
        this.addPowerUpsToPlayerAuth(player, powerUpsId, powerUpsLevel, "");
    }

    function addPowerUpsToPlayerAuth(address player, uint[] calldata powerUpsId, uint8[] calldata powerUpsLevel, string calldata clientSecret) external {
        bool hasSecret = false;
        if(clientSecretManager != address(0)){
            IClientSecretManager csm = IClientSecretManager(clientSecretManager);
            hasSecret = csm.checkClientSecret(context, clientSecret);
        }
        require((msg.sender == owner || hasSecret) && powerUpsId.length > 0 && powerUpsId.length == powerUpsLevel.length);
        for(uint i=0; i<powerUpsId.length; i++){
            uint id = powerUpsId[i];
            uint8 level = powerUpsLevel[i];
            _powerUps[player][id] += level;
        }
    }

    function removePowerUpsToPlayer(address player, uint[] calldata powerUpsId, uint8[] calldata powerUpsLevel) external {
        require(msg.sender == owner);
        this.removePowerUpsToPlayerAuth(player, powerUpsId, powerUpsLevel, "");
    }

    function removePowerUpsToPlayerAuth(address player, uint[] calldata powerUpsId, uint8[] calldata powerUpsLevel, string calldata clientSecret) external {
        bool hasSecret = false;
        if(clientSecretManager != address(0)){
            IClientSecretManager csm = IClientSecretManager(clientSecretManager);
            hasSecret = csm.checkClientSecret(context, clientSecret);
        }
        require((msg.sender == owner || msg.sender == gameTrader || hasSecret) && powerUpsId.length > 0 && powerUpsId.length == powerUpsLevel.length);
        for(uint i=0; i<powerUpsId.length; i++){
            uint id = powerUpsId[i];
            uint8 level = powerUpsLevel[i];
            _powerUps[player][id] -= level;
        }
    }

    //Restituisce per ogni oggetto (id) la quantità posseduta dal giocatore.
    function getPlayerItems(address player) external view returns(uint16[100] memory items) {
        return _playerItems[player];
    }

    function equalsStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

}