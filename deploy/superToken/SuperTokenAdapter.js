
const func = async function(hre) {

    const {deployments, getNamedAccounts} = hre;
    const {deploy} = deployments;
  
    const {deployer} = await getNamedAccounts();

    const uniswapLibrary = await deploy("UniswapLibrary", {
      from: deployer
    });
    const safeMathLibrary = await deploy("SafeMath", {
      from: deployer
    });
    const transferHelperLibrary = await deploy("TransferHelper", {
      from: deployer
    });
  
    await deploy('UniswapSTokenToTokenAdapter', {
      args: ["0x7a250d5630b4cf539739df2c5dacb4c659f2488d", "0x1f9840a85d5af5bf1d1762f925bdaddc4201f984"],
      from: deployer,
      log: true,
      libraries: {
        UniswapLibrary: uniswapLibrary.address,
        SafeMath: safeMathLibrary.address,
        TransferHelper: transferHelperLibrary.address,
      }
    });
}

module.exports = func
