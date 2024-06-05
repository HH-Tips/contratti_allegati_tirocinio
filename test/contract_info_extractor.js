const fs = require("fs");

function main(){
    // console.log(contractInfo("GameData").abi);
    // console.log(contractInfo("BloodPointsBank").abi)
    // console.log(contractInfo("GameTrader").abi)
}

function contractInfo(contract){
    const compiledFile = fs.readFileSync(`artifacts/contracts/${contract}.sol/${contract}.json`);;
    const addressesFile = fs.readFileSync(process.env.DEPLOYED_CONTRACTS_ADDRESSES);
    const info = JSON.parse(compiledFile.toString());
    const addresses = JSON.parse(addressesFile.toString());
    info.address = addresses[contract];
    return info;
}

module.exports = {
    contractInfo
}

main();