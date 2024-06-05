function getWallets(provider){
    const wallets = [];
    const wallet1 = new ethers.Wallet(
        process.env.HH_PR_KEY_1,
        provider
    );
    const wallet2 = new ethers.Wallet(
        process.env.HH_PR_KEY_2,
        provider
    );
    const wallet3 = new ethers.Wallet(
        process.env.HH_PR_KEY_3,
        provider
    );
    const walletSepolia1 = new ethers.Wallet(
        process.env.PRIVATE_KEY,
        provider
    );
    const walletSepolia2 = new ethers.Wallet(
        process.env.PRIVATE_KEY_2,
        provider
    );
    wallets.push(wallet1);
    wallets.push(wallet2);
    wallets.push(wallet3);
    wallets.push(walletSepolia1);
    wallets.push(walletSepolia2);
    return wallets;
}

module.exports = {
    getWallets
}