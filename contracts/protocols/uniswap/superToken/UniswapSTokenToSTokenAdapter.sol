// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "../../../ens/ReverseENS.sol";
import "../../../Receiver.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Router01.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../UniswapLibrary.sol";
import "../interfaces/ISuperToken.sol";

contract UniswapSTokenToSTokenAdapter is Receiver, ReverseENS {
    using SafeMath for uint256;

    IUniswapV2Factory public immutable uniswapFactory;
    ISuperToken private immutable outputToken;
    ERC20 public immutable outputUnderlyingToken;

    constructor(IUniswapV2Router01 _uniswapRouter, ISuperToken _outputToken) public {
        uniswapFactory = _uniswapRouter.factory();
        outputToken = _outputToken;
        outputUnderlyingToken = ERC20(_outputToken.getUnderlyingToken());
    }

    /**
     * Ex: Assume this is a fUSDC output Uniswap contract
     * If fDAIx is sent to this, it will downgrade it to fDAI
     * interact with the fDAI/fUSDC uniswap pool & it will swap to fUSDC
     * upgrade fUSDC to fUSDx then transfer fUSDCx to the `from` address
     */
    function _tokensReceived(
        IERC777 _token,
        address from,
        uint256 amount,
        bytes memory /*data*/
    ) internal override {
        ISuperToken superToken = ISuperToken(address(_token));
        ERC20 unwrappedInput = ERC20(superToken.getUnderlyingToken());
        
        superToken.downgrade(amount);

        uint256 outputAmount =
            UniswapLibrary.executeSwap(
                uniswapFactory,
                address(unwrappedInput),
                address(outputUnderlyingToken),
                amount,
                address(this)
            );
            
        require(outputAmount > 0, "NO_PAIR");
        // contract approve 
        outputUnderlyingToken.approve(address(outputToken), outputAmount);
        outputToken.upgradeTo(from, outputAmount, "");
    }

}
