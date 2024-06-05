const walletsBuilder = require("./wallets_builder.js");

async function main(){
    const provider = ethers.getDefaultProvider(process.env.LOCAL_BLOCKCHAIN_RPC);

    const wallets = walletsBuilder.getWallets(provider);

    const from = [wallets[0], wallets[1]];
    const to = [wallets[3], wallets[4]];
    const value = ethers.parseUnits("5000", "ether");

    for(i=0; i<from.length; i++){
        const signer = from[i];
        
        const tx = {
            "from": signer,
            "to": to[i],
            "value": value
        }
    
        const response = await signer.sendTransaction(tx);
        console.log(`Richiesta di trasferimento di ${ethers.formatEther(value)} ETH`);
        console.log(`da: ${signer.toString()}`);
        console.log(`a: ${to[i].toString()}`);
        console.log(`bilancio mittente: ${ethers.formatEther(await provider.getBalance(signer))} ETH`);
        console.log(`bilancio destinatario: ${ethers.formatEther(await provider.getBalance(to[i]))} ETH`);
    }
}

main()
    .catch(error => console.error(error));