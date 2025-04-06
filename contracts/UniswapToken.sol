// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Uniswap V2 Router 接口
interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function WETH() external pure returns (address);

    // 添加流动性（ETH 和 token）
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);
}

// Uniswap V2 Pair 接口（用于查询储备量）
interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

contract YidengTokenSwap is Ownable {
    IUniswapV2Router02 public uniswapRouter;
    IERC20 public yidengToken;
    address public pairAddress; // YidengToken/WETH 池子地址

    // Uniswap V2 Router 主网地址
    address public constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    event TokensSwapped(
        address buyer,
        address tokenIn,
        uint256 amountIn,
        uint256 amountOut
    );
    event LiquidityAdded(
        address provider,
        uint256 yidengAmount,
        uint256 ethAmount,
        uint256 liquidity
    );

    constructor(address _yidengToken, address _pairAddress) {
        uniswapRouter = IUniswapV2Router02(UNISWAP_V2_ROUTER);
        yidengToken = IERC20(_yidengToken);
        pairAddress = _pairAddress; // YidengToken/WETH 池子地址
    }

    // 添加流动性：YidengToken 和 ETH
    function addLiquidity(
        uint256 yidengAmount,
        uint256 amountETHMin,
        uint256 amountTokenMin
    ) external payable returns (uint256, uint256, uint256) {
        require(yidengAmount > 0, "Yideng amount must be greater than 0");
        require(msg.value > 0, "Must send ETH");

        // 从用户转入 YidengToken
        require(
            yidengToken.transferFrom(msg.sender, address(this), yidengAmount),
            "Transfer failed"
        );
        // 授权 Router 使用 YidengToken
        require(
            yidengToken.approve(address(uniswapRouter), yidengAmount),
            "Approve failed"
        );

        // 调用 Uniswap Router 添加流动性
        (uint amountToken, uint amountETH, uint liquidity) = uniswapRouter
            .addLiquidityETH{value: msg.value}(
            address(yidengToken),
            yidengAmount,
            amountTokenMin, // 最小 YidengToken 数量（防滑点）
            amountETHMin, // 最小 ETH 数量（防滑点）
            msg.sender, // 流动性代币（LP token）发送给用户
            block.timestamp + 300
        );

        emit LiquidityAdded(msg.sender, amountToken, amountETH, liquidity);
        return (amountToken, amountETH, liquidity);
    }

    // 查询 YidengToken/WETH 池子的兑换比例
    function getYidengToWETHPrice()
        external
        view
        returns (uint256 yidengPerWETH, uint256 wethPerYideng)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

        address token0 = pair.token0();
        uint256 yidengReserve;
        uint256 wethReserve;

        // 判断 token0 和 token1 哪个是 YidengToken，哪个是 WETH
        if (token0 == address(yidengToken)) {
            yidengReserve = reserve0;
            wethReserve = reserve1;
        } else {
            yidengReserve = reserve1;
            wethReserve = reserve0;
        }

        // 计算兑换比例（假设 18 位小数）
        yidengPerWETH = (wethReserve * 1e18) / yidengReserve; // 1 YidengToken 换多少 WETH
        wethPerYideng = (yidengReserve * 1e18) / wethReserve; // 1 WETH 换多少 YidengToken

        return (yidengPerWETH, wethPerYideng);
    }

    // 查询 WETH 到其他 token 的兑换比例（通过 WETH/tokenOut 池子）
    function getWETHToTokenPrice(
        address tokenOut,
        address pairAddressTokenOut
    ) external view returns (uint256 wethPerToken, uint256 tokenPerWETH) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddressTokenOut);
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

        address token0 = pair.token0();
        uint256 wethReserve;
        uint256 tokenOutReserve;

        if (token0 == uniswapRouter.WETH()) {
            wethReserve = reserve0;
            tokenOutReserve = reserve1;
        } else {
            wethReserve = reserve1;
            tokenOutReserve = reserve0;
        }

        wethPerToken = (tokenOutReserve * 1e18) / wethReserve; // 1 WETH 换多少 tokenOut
        tokenPerWETH = (wethReserve * 1e18) / tokenOutReserve; // 1 tokenOut 换多少 WETH

        return (wethPerToken, tokenPerWETH);
    }

    // 用 YidengToken 兑换其他 token（通过 WETH）
    function swapYidengForToken(
        uint256 yidengAmountIn,
        address tokenOut,
        uint256 amountOutMin
    ) external returns (uint256) {
        require(yidengAmountIn > 0, "Amount must be greater than 0");
        require(
            tokenOut != address(yidengToken),
            "Cannot swap for the same token"
        );

        require(
            yidengToken.transferFrom(msg.sender, address(this), yidengAmountIn),
            "Transfer failed"
        );
        require(
            yidengToken.approve(address(uniswapRouter), yidengAmountIn),
            "Approve failed"
        );

        address[] memory path = new address[](3);
        path[0] = address(yidengToken);
        path[1] = uniswapRouter.WETH();
        path[2] = tokenOut;

        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            yidengAmountIn,
            amountOutMin,
            path,
            msg.sender,
            block.timestamp + 300
        );

        emit TokensSwapped(
            msg.sender,
            address(yidengToken),
            yidengAmountIn,
            amounts[2]
        );
        return amounts[2];
    }

    // 用其他 token 兑换 YidengToken（通过 WETH）
    function swapTokenForYideng(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin
    ) external returns (uint256) {
        require(amountIn > 0, "Amount must be greater than 0");
        require(
            tokenIn != address(yidengToken),
            "Cannot swap for the same token"
        );

        IERC20 inputToken = IERC20(tokenIn);
        require(
            inputToken.transferFrom(msg.sender, address(this), amountIn),
            "Transfer failed"
        );
        require(
            inputToken.approve(address(uniswapRouter), amountIn),
            "Approve failed"
        );

        address[] memory path = new address[](3);
        path[0] = tokenIn;
        path[1] = uniswapRouter.WETH();
        path[2] = address(yidengToken);

        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            msg.sender,
            block.timestamp + 300
        );

        emit TokensSwapped(msg.sender, tokenIn, amountIn, amounts[2]);
        return amounts[2];
    }

    // 用 ETH 兑换 YidengToken
    function swapETHForYideng(
        uint256 amountOutMin
    ) external payable returns (uint256) {
        require(msg.value > 0, "Must send ETH");

        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = address(yidengToken);

        uint[] memory amounts = uniswapRouter.swapExactETHForTokens{
            value: msg.value
        }(amountOutMin, path, msg.sender, block.timestamp + 300);

        emit TokensSwapped(
            msg.sender,
            uniswapRouter.WETH(),
            msg.value,
            amounts[1]
        );
        return amounts[1];
    }

    // 用 YidengToken 兑换 ETH
    function swapYidengForETH(
        uint256 yidengAmountIn,
        uint256 amountOutMin
    ) external returns (uint256) {
        require(yidengAmountIn > 0, "Amount must be greater than 0");

        require(
            yidengToken.transferFrom(msg.sender, address(this), yidengAmountIn),
            "Transfer failed"
        );
        require(
            yidengToken.approve(address(uniswapRouter), yidengAmountIn),
            "Approve failed"
        );

        address[] memory path = new address[](2);
        path[0] = address(yidengToken);
        path[1] = uniswapRouter.WETH();

        uint[] memory amounts = uniswapRouter.swapExactTokensForETH(
            yidengAmountIn,
            amountOutMin,
            path,
            msg.sender,
            block.timestamp + 300
        );

        emit TokensSwapped(
            msg.sender,
            address(yidengToken),
            yidengAmountIn,
            amounts[1]
        );
        return amounts[1];
    }

    // 提取 ETH（仅限拥有者）
    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    // 提取 token（仅限拥有者）
    function withdrawToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner(), amount);
    }

    // 接收 ETH
    receive() external payable {}
}
