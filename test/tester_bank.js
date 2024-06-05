const dc = require("./dollar_converter");
const cinf = require("./contract_info_extractor");
const threads = require("./threads");
const walletsBuilder = require("./wallets_builder");

async function main(){
    // const provider = new ethers.EtherscanProvider("sepolia", process.env.ETHERSCAN_API_KEY);
    const localProvider = ethers.getDefaultProvider(process.env.LOCAL_BLOCKCHAIN_RPC);
    const wallets = walletsBuilder.getWallets(localProvider);
    const contractInfo = cinf.contractInfo("BloodPointsBank");
    const bank = new ethers.Contract(
        contractInfo.address,
        contractInfo.abi,
        wallets[0]
    );

    const balanceBeforeTx = await localProvider.getBalance(wallets[0]);
    console.log(`Bilancio iniziale: ${dc.weiToDollar(balanceBeforeTx)}$, ${await bank.getBalance(wallets[0])} BloodPoints.`);
    const options = {value: dc.dollarToWei(30)};
    await wallets[0].sendTransaction({"to": bank.getAddress(), "value": options.value});
    await threads.sleep(300);
    const balanceAfterTx = await localProvider.getBalance(wallets[0]);
    const spent = balanceBeforeTx-balanceAfterTx;
    console.log(`Sono stati rimossi: ${spent} WEI dal tuo wallet, l'equivalente di ${dc.weiToDollar(spent)}$.`);
    const bp = await bank.getBalance(wallets[0]);
    console.log(`Bilancio finale: ${dc.weiToDollar(await localProvider.getBalance(wallets[0]))}$, ${bp} BloodPoints.`);
}

main()
    .catch(error => console.error(error));