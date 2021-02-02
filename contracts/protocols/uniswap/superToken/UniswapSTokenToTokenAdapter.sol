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

contract UniswapSTokenToTokenAdapter is Receiver, ReverseENS {
    using SafeMath for uint256;

    IUniswapV2Factory public immutable uniswapFactory;
    ERC20 private immutable outputToken;

    constructor(IUniswapV2Router01 _uniswapRouter, ERC20 _outputToken) public {
        uniswapFactory = _uniswapRouter.factory();
        outputToken = _outputToken;
    }

    /**
     * Ex: Assume this is a Uni Uniswap contract
     * If fDAIx is sent to this, it will downgrade it to fDAI
     * interact with the UNI/fDAI uniswap pool & it will swap to Uni
     * then transfer the UNI back to the `from` address
     */
    function _tokensReceived(
        IERC777 _token,
        address from,
        uint256 amount,
        bytes memory /*data*/
    ) internal override {
        ISuperToken superToken = ISuperToken(address(_token));
        ERC20 unwrappedInput = ERC20(superToken.getUnderlyingToken());
        // unwrap amount
        superToken.downgrade(amount);

        uint256 outputAmount =
           UniswapLibrary.executeSwap(
                uniswapFactory,
                address(unwrappedInput),
                address(outputToken),
                amount,
                from
            );

        require(outputAmount > 0, "NO_PAIR");
    }

}
