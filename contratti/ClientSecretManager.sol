// SPDX-License-Identifier: UNLICENSED 
pragma solidity >=0.8.19;

contract ClientSecretManager {

    address owner;
    uint private counter = 0;
    string private constant CHAR_SET = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    uint private constant clientSecretLength = 128;
    //context => clientSecret
    mapping(string => string) clientSecrets;
    string[] registeredContext;

    constructor(){
        owner = msg.sender;
    }

    function generateClientSecret(string calldata context, uint256 salt) public {
        require(msg.sender == owner);
        string memory secretKey = getRandomString(salt);
        clientSecrets[context] = secretKey;
    }

    function getClientSecret(string calldata context) public view returns (string memory){
        require(msg.sender == owner);
        return clientSecrets[context];
    }

    function checkClientSecret(string calldata context, string calldata clientSecret) external view returns (bool) {
        return equalsString(clientSecrets[context], clientSecret);
    }

    // Metodo per generare una stringa casuale
    function getRandomString(uint salt) private returns (string memory) {
        bytes memory randomString = new bytes(clientSecretLength);
        uint256 charSetLength = bytes(CHAR_SET).length;
        
        for (uint256 i = 0; i < clientSecretLength; i++) {
            uint256 randomIndex = getRandomNumber(salt) % charSetLength;
            randomString[i] = bytes(CHAR_SET)[randomIndex];
        }
        
        string memory finalString = string(randomString);
        return finalString;
    }

    // Metodo per generare un numero casuale
    function getRandomNumber(uint256 seed) private returns (uint256) {
        // Genera un hash utilizzando il blocco corrente, il timestamp, il seed e l'indirizzo del chiamante
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, seed, counter++)));
        return randomHash;
    }

    // Metodo di esempio per ottenere un numero casuale entro un intervallo specificato
    function getRandomNumberInRange(uint256 seed, uint256 min, uint256 max) private returns (uint256) {
        require(max > min, "Max must be greater than min");
        uint256 randomHash = getRandomNumber(seed);
        // Mappa il numero casuale nell'intervallo specificato
        uint256 randomInRange = randomHash % (max - min + 1) + min;
        return randomInRange;
    }

    function equalsString(string memory s1, string memory s2) private pure returns(bool) {
        bool res = (keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2)));
        bytes memory bs1 = bytes(s1);
        bytes memory bs2 = bytes(s2);
        res = res && bs1.length == bs2.length && keccak256(bs1) == keccak256(bs2);
        return res;
    }
}