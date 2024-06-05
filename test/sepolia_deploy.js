const fs = require("fs");

async function main() {
    var stdin = process.openStdin();
    // console.log("Contract names (separated by spaces):");
    // process.stdout.write(">> ");
    stdin.addListener("data", function(d){
        length = d.toString().length;
        const args = d.toString().slice(0, length-1).split(" ");
        // console.log(args);
        deployContracts(args);
        process.stdin.destroy();
    });
}

async function deployContracts(args){
    if(args.length < 1){
        console.error("Error: no contract name given.")
        process.exitCode = 1;
        return;
    }
    const addresses = [];
    
    for(i=0; i<args.length; i++){
        //Il signer sarà il mio primo wallet.
        const contract = await ethers.getContractFactory(args[i]);
        const deployedContract = await contract.deploy();

        addresses[i] = deployedContract.target;
        console.log(`Contract "${args[i]}" deployed to: ${deployedContract.target}`);
    }
    saveAddresses(args, addresses);
}

async function saveAddress(contract, address){
    const addresses = fs.existsSync(process.env.SEPOLIA_DEPLOYED_CONTRACTS_ADDRESSES) ? JSON.parse(fs.readFileSync(process.env.SEPOLIA_DEPLOYED_CONTRACTS_ADDRESSES).toString()) : {};
    addresses[contract] = address;
    fs.writeFileSync(process.env.SEPOLIA_DEPLOYED_CONTRACTS_ADDRESSES, JSON.stringify(addresses));
}

async function saveAddresses(contracts, addresses){
    const json = fs.existsSync(process.env.SEPOLIA_DEPLOYED_CONTRACTS_ADDRESSES) ? JSON.parse(fs.readFileSync(process.env.SEPOLIA_DEPLOYED_CONTRACTS_ADDRESSES).toString()) : {};
    for(i=0; i<contracts.length; i++){
        json[contracts[i]] = addresses[i];
    }
    fs.writeFileSync(process.env.SEPOLIA_DEPLOYED_CONTRACTS_ADDRESSES, JSON.stringify(json));
}

main()
    .catch(error => {
        console.error(error);
        process.exitCode = 1;
    });