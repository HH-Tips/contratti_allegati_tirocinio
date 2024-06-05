const ethers = require("ethers");

function etherToDollar(amount) {
    return amount * 3000;
}

function weiToDollar(amount){
    const eths = ethers.formatEther(amount);
    return etherToDollar(eths);
}

function dollarToEther(amount){
    return amount/3000;
}

function dollarToWei(amount){
    const value = `${dollarToEther(amount)}`;
    const tokens = value.split(".");
    return ethers.parseUnits(value.substring(0, (tokens[0].length+1)+18), "ether");
}

module.exports = {
    etherToDollar,
    weiToDollar,
    dollarToEther,
    dollarToWei
}