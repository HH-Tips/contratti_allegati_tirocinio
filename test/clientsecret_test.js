const ethers = require("ethers");
const walletsBuilder = require("./wallets_builder");
const cinf = require("./contract_info_extractor");
const threads = require("./threads");

const provider = ethers.getDefaultProvider(process.env.LOCAL_BLOCKCHAIN_RPC);
const wallets = walletsBuilder.getWallets(provider);

async function main(){
    const contractInfo = cinf.contractInfo("ClientSecretManager");
    var contractCS = new ethers.Contract(
        contractInfo.address,
        contractInfo.abi,
        wallets[1]
    );

    const testCsmInfo = cinf.contractInfo("TestCSM");
    var testCsm = new ethers.Contract(
        testCsmInfo.address,
        testCsmInfo.abi,
        wallets[1]
    );

    const context = "No chance to survive";

    await test(context, contractCS, testCsm, wallets);
}


async function test(context, csm, testCsm, wallets){
    const testCsm0 = testCsm.connect(wallets[0]);
    await testCsm0.setClientSecretManagerContractAddress(await csm.getAddress());
    
    await threads.sleep(300);

    const csm0 = csm.connect(wallets[0]);
    await csm0.generateClientSecret(context, 54821);
    var clientSecret = await csm0.getClientSecret(context);

    await threads.sleep(300);

    console.log("Valid csm secret: ", await csm.checkClientSecret(context, clientSecret));
    console.log("Valid TestCSM secret: ", await testCsm.checkClientSecret(clientSecret));    
}

main();