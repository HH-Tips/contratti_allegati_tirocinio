const cinf = require("./contract_info_extractor");
const walletsBuilder = require("./wallets_builder");
const threads = require("./threads");

async function main(){
    const provider = ethers.getDefaultProvider(process.env.LOCAL_BLOCKCHAIN_RPC);
    const wallets = walletsBuilder.getWallets(provider)
    const contractInfo = cinf.contractInfo("GameData");
    var contract = new ethers.Contract(
      contractInfo.address,
      contractInfo.abi,
      wallets[0]
    );

    await contract.registerPlayer("HH-Tips");
    await threads.sleep(300);
    console.log(await contract.playerInfo(wallets[0]));
}

main()
    .catch(error => {
        console.error(error);
        process.exitCode = 1;
    });