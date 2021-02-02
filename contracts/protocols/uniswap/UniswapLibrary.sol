// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Factory.sol";

library UniswapLibrary {
    using SafeMath for uint256;

    function isLPToken(address token) internal view returns (bool) {
        try IUniswapV2Pair(token).token0() returns (ERC20 token0) {
            return address(token0) != address(0);
        } catch {
            return false;
        }
    }

    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn)
        internal
        pure
        returns (uint256 amount)
    {
        amount =
            sqrt(reserveIn.mul(userIn.mul(3988000) + reserveIn.mul(3988009)))
                .sub(reserveIn.mul(1997)) /
            1994;

        if (amount == 0) {
            amount = userIn / 2;
        }
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }

    function executeSwap(
        IUniswapV2Factory uniswapFactory,
        address input,
        address out,
        uint256 swapAmount,
        address to
    ) internal returns (uint256 outputAmount) {
        IUniswapV2Pair pair =
            IUniswapV2Pair(uniswapFactory.getPair(input, out));
        if (address(pair) == address(0)) {
            return 0;
        }

        if (swapAmount > 0) {
            TransferHelper.safeTransfer(input, address(pair), swapAmount);
        }

        address token0 = address(pair.token0());

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (uint256 reserveIn, uint256 reserveOut) =
            input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

        outputAmount = UniswapLibrary.getAmountOut(
            swapAmount,
            reserveIn,
            reserveOut
        );
        (uint256 amount0Out, uint256 amount1Out) =
            input == token0
                ? (uint256(0), outputAmount)
                : (outputAmount, uint256(0));

        pair.swap(amount0Out, amount1Out, to, new bytes(0));
    }
}
