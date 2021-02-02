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

    // fUSDCx
    const outputToken = "0x8aE68021f6170E5a766bE613cEA0d75236ECCa9a"

    await deploy('UniswapSTokenToSTokenAdapter', {
      args: ["0x7a250d5630b4cf539739df2c5dacb4c659f2488d", outputToken],
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
