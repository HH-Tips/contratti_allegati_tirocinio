const cinf = require("./contract_info_extractor");
const dc = require("./dollar_converter");
const fs = require("fs");
const threads = require("./threads.js");
const walletsBuilder = require("./wallets_builder");

const provider = ethers.getDefaultProvider(process.env.LOCAL_BLOCKCHAIN_RPC);
const wallets = walletsBuilder.getWallets(provider);

async function main() {

    const bankInfo = cinf.contractInfo("BloodPointsBank");
    var bank = new ethers.Contract(
        bankInfo.address,
        bankInfo.abi,
        wallets[0]
    );

    const gameDataInfo = cinf.contractInfo("GameData");
    var gameData = new ethers.Contract(
        gameDataInfo.address,
        gameDataInfo.abi,
        wallets[0]
    );

    const gameTraderInfo = cinf.contractInfo("GameTrader");
    var gameTrader = new ethers.Contract(
        gameTraderInfo.address,
        gameTraderInfo.abi,
        wallets[0]
    );

    const csmInfo = cinf.contractInfo("ClientSecretManager");
    var csm = new ethers.Contract(
        csmInfo.address,
        csmInfo.abi,
        wallets[0]
    );

    await bindContracts(gameData, gameTrader, bank, csm);
    await testSendAndAcceptOffer(wallets, gameData, gameTrader, bank);
}

async function testClientSecret(gameData, gameTrader, bank, csm, wallets){
    const context = "No chance to survive";
    await csm.generateClientSecret(context, 54821);
    await threads.sleep(300);
    var clientSecret = await csm.getClientSecret(context);
    console.log("Valid secret: ", await csm.checkClientSecret(context, clientSecret));
    var gd = gameData.connect(wallets[1]);
    console.log(await gameData.playerInfo(wallets[1]));
    await threads.sleep(300);
    try{await gd.addItemAmountToPlayerAuth(wallets[1], 0, 21, clientSecret);} catch(e){console.error(e)}
    console.log(await gd.playerInfo(wallets[1]));
}

async function testSendAndAcceptOffer(wallets, gameData, gameTrader, bank){
    await gameData.registerPlayer("HH-Tips");
    gameData = gameData.connect(wallets[1]);
    console.log("Utente HH-Tips registrato.");
    await threads.sleep(300);
    await gameData.registerPlayer("Drea");
    gameData = gameData.connect(wallets[0]);
    console.log("Utente Drea registrato.");
    

    await threads.sleep(300);
    await addItems(gameData);
    await threads.sleep(300);
    console.log(`Dati utente wallets[0]: ${await gameData.playerInfo(wallets[0])}`);
    console.log(`Dati utente wallets[1]: ${await gameData.playerInfo(wallets[1])}`);

    if(await bank.getBalance(wallets[0]) < 1000){
        await threads.sleep(300);
        await wallets[0].sendTransaction({"to": await bank.getAddress(), "value": dc.dollarToWei(10)});
    }
    console.log(`Bilancio di wallets[0]: ${await bank.getBalance(wallets[0])} BloodPoints`);

    await threads.sleep(300);
    gameTrader = gameTrader.connect(wallets[1]);
    await inviaProposta(gameTrader);
    gameTrader = gameTrader.connect(wallets[0]);
    await threads.sleep(300);
    console.log("Proposta inviata.");

    console.log(`Pending Trades di wallets[0]: ${await gameTrader.getPendingTrades()}`);

    await threads.sleep(300);
    await gameTrader.acceptTradeOffer(0);
    console.log("Proposta accettata.");
    console.log(`wallets[0]: ${await gameData.playerInfo(wallets[0])}`);
    console.log(`Bilancio di wallets[0]: ${await bank.getBalance(wallets[0])} BloodPoints`);
    console.log(`wallets[1]: ${await gameData.playerInfo(wallets[1])}`);
    console.log(`Bilancio di wallets[1]: ${await bank.getBalance(wallets[1])} BloodPoints`);
}

async function inviaProposta(gameTrader){
    trade = {
        "from": wallets[1],
        "to": wallets[0],
        "offer": {
            "bloodPoints": 0,
            "itemIds": [1],
            "amounts": [10]
        },
        "request": {
            "bloodPoints": 1000,
            "itemIds": [0],
            "amounts": [1]
        },
        "timestamp": 0
    }

    await gameTrader.proposeTrade(trade);
}

async function bindContracts(gameData, gameTrader, bloodPointsBank, csm){
    await gameTrader.setGameDataContractAddress(await gameData.getAddress());
    await threads.sleep(500);
    await gameTrader.setBloodPointsBankContractAddress(await bloodPointsBank.getAddress());
    await threads.sleep(500);

    await gameData.setGameTraderContractAddress(await gameTrader.getAddress());
    await threads.sleep(500);
    await gameData.setClientSecretManagerContractAddress(await csm.getAddress());
    await threads.sleep(500);

    await bloodPointsBank.setGameTraderContractAddress(await gameTrader.getAddress());
    await threads.sleep(500);
    await bloodPointsBank.setClientSecretManagerContractAddress(await csm.getAddress());
    await threads.sleep(500);
}

async function addItems(gameData){
    items = JSON.parse(fs.readFileSync("./jsonData/items.json"));
    await gameData.setItems(items);
    await threads.sleep(500);
    gameData.addItemAmountToPlayer(wallets[0], 0, 3);
    await threads.sleep(500);
    gameData.addItemAmountToPlayer(wallets[1], 1, 30);
}

main()
    .catch(error => console.error(error));