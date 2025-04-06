// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract YidengSwap {
    using SafeERC20 for IERC20;

    address public immutable yidengToken;
    address public immutable uniswapRouter;
    address public immutable WETH;

    constructor(address _yidengToken, address _router) {
        require(_yidengToken != address(0), "Invalid YidengToken address");
        require(_router != address(0), "Invalid router address");
        yidengToken = _yidengToken;
        uniswapRouter = _router;
        WETH = IUniswapV2Router02(_router).WETH();
    }

    // YidengToken 换其他代币（通过 WETH）
    function swapExactYidengTokenForToken(
        uint amountIn,
        uint amountOutMin,
        address tokenOut,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        require(tokenOut != yidengToken, "Invalid token out");
        require(tokenOut != WETH, "Use swapExactYidengTokenForETH for WETH");

        // 将用户的 YidengToken 转入合约
        IERC20(yidengToken).safeTransferFrom(
            msg.sender,
            address(this),
            amountIn
        );
        IERC20(yidengToken).safeApprove(uniswapRouter, amountIn);

        // 设置兑换路径：YidengToken -> WETH -> tokenOut
        address[] memory path = new address[](3);
        path[0] = yidengToken;
        path[1] = WETH;
        path[2] = tokenOut;

        return
            IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            );
    }

    // 其他代币换 YidengToken（通过 WETH）
    function swapExactTokenForYidengToken(
        address tokenIn,
        uint amountIn,
        uint amountOutMin,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        require(tokenIn != yidengToken, "Invalid token in");
        require(tokenIn != WETH, "Use swapExactETHForYidengToken for ETH");

        // 将用户的 token 转入合约
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).safeApprove(uniswapRouter, amountIn);

        // 设置兑换路径：tokenIn -> WETH -> YidengToken
        address[] memory path = new address[](3);
        path[0] = tokenIn;
        path[1] = WETH;
        path[2] = yidengToken;

        return
            IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            );
    }

    // ETH 换 YidengToken
    function swapExactETHForYidengToken(
        uint amountOutMin,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts) {
        // 设置兑换路径：WETH -> YidengToken
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = yidengToken;

        return
            IUniswapV2Router02(uniswapRouter).swapExactETHForTokens{
                value: msg.value
            }(amountOutMin, path, to, deadline);
    }

    // YidengToken 换 ETH
    function swapExactYidengTokenForETH(
        uint amountIn,
        uint amountOutMin,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        // 将用户的 YidengToken 转入合约
        IERC20(yidengToken).safeTransferFrom(
            msg.sender,
            address(this),
            amountIn
        );
        IERC20(yidengToken).safeApprove(uniswapRouter, amountIn);

        // 设置兑换路径：YidengToken -> WETH
        address[] memory path = new address[](2);
        path[0] = yidengToken;
        path[1] = WETH;

        return
            IUniswapV2Router02(uniswapRouter).swapExactTokensForETH(
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            );
    }

    // 添加 YidengToken 和 ETH 的流动性
    function addLiquidityETH(
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity)
    {
        IERC20(yidengToken).safeTransferFrom(
            msg.sender,
            address(this),
            amountTokenDesired
        );
        IERC20(yidengToken).safeApprove(uniswapRouter, amountTokenDesired);

        return
            IUniswapV2Router02(uniswapRouter).addLiquidityETH{value: msg.value}(
                yidengToken,
                amountTokenDesired,
                amountTokenMin,
                amountETHMin,
                to,
                deadline
            );
    }

    // 移除 YidengToken 和 ETH 的流动性
    function removeLiquidityETH(
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH) {
        address pair = IUniswapV2Factory(
            IUniswapV2Router02(uniswapRouter).factory()
        ).getPair(yidengToken, WETH);
        require(pair != address(0), "Liquidity pair does not exist");

        IERC20(pair).safeTransferFrom(msg.sender, address(this), liquidity);
        IERC20(pair).safeApprove(uniswapRouter, liquidity);

        return
            IUniswapV2Router02(uniswapRouter).removeLiquidityETH(
                yidengToken,
                liquidity,
                amountTokenMin,
                amountETHMin,
                to,
                deadline
            );
    }

    // 获取通过 WETH 交换其他代币的预期数量
    function getAmountViaWETH(
        uint amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint) {
        require(
            (tokenIn == yidengToken && tokenOut != yidengToken) ||
                (tokenIn != yidengToken && tokenOut == yidengToken),
            "Invalid token pair"
        );
        require(
            tokenIn != WETH && tokenOut != WETH,
            "Use direct ETH functions for WETH"
        );

        address[] memory path = new address[](3);
        path[0] = tokenIn;
        path[1] = WETH;
        path[2] = tokenOut;

        uint[] memory amounts = IUniswapV2Router02(uniswapRouter).getAmountsOut(
            amountIn,
            path
        );
        return amounts[2];
    }

    // 获取 ETH 兑换 YidengToken 的预期数量
    function getAmountOutETHForYidengToken(
        uint amountIn
    ) external view returns (uint) {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = yidengToken;

        uint[] memory amounts = IUniswapV2Router02(uniswapRouter).getAmountsOut(
            amountIn,
            path
        );
        return amounts[1];
    }

    // 获取 YidengToken 兑换 ETH 的预期数量
    function getAmountOutYidengTokenForETH(
        uint amountIn
    ) external view returns (uint) {
        address[] memory path = new address[](2);
        path[0] = yidengToken;
        path[1] = WETH;

        uint[] memory amounts = IUniswapV2Router02(uniswapRouter).getAmountsOut(
            amountIn,
            path
        );
        return amounts[1];
    }

    // 获取 YidengToken 能换到的其他代币的预期数量
    function getAmountOutYidengTokenForToken(
        uint amountIn,
        address tokenOut
    ) external view returns (uint) {
        require(tokenOut != yidengToken, "Invalid token out");
        require(tokenOut != WETH, "Use getAmountOutYidengTokenForETH for ETH");

        // 设置兑换路径：YidengToken -> WETH -> tokenOut
        address[] memory path = new address[](3);
        path[0] = yidengToken;
        path[1] = WETH;
        path[2] = tokenOut;

        uint[] memory amounts = IUniswapV2Router02(uniswapRouter).getAmountsOut(
            amountIn,
            path
        );
        return amounts[2];
    }

    // 获取其他代币能换到的 YidengToken 的预期数量
    function getAmountOutTokenForYidengToken(
        address tokenIn,
        uint amountIn
    ) external view returns (uint) {
        require(tokenIn != yidengToken, "Invalid token in");
        require(tokenIn != WETH, "Use getAmountOutETHForYidengToken for ETH");

        // 设置兑换路径：tokenIn -> WETH -> YidengToken
        address[] memory path = new address[](3);
        path[0] = tokenIn;
        path[1] = WETH;
        path[2] = yidengToken;

        uint[] memory amounts = IUniswapV2Router02(uniswapRouter).getAmountsOut(
            amountIn,
            path
        );
        return amounts[2];
    }

    receive() external payable {}
}
