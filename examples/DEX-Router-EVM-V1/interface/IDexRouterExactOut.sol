// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface DexRouterExactOut {
    error SafeTransferFailed();

    event AdminChanged(address newAdmin);
    event CommissionFromTokenRecord(address fromTokenAddress, uint256 commissionAmount, address referrerAddress);
    event CommissionToTokenRecord(address toTokenAddress, uint256 commissionAmount, address referrerAddress);
    event Initialized(uint8 version);
    event OrderRecord(address fromToken, address toToken, address sender, uint256 fromAmount, uint256 returnAmount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event PriorityAddressChanged(address priorityAddress, bool valid);
    event Swap(address indexed srcToken, address indexed dstToken, address indexed payer, uint256 amount);
    event Swap(
        address indexed srcToken, address indexed dstToken, address indexed payer, uint256 returnAmount, uint256 amount
    );
    event SwapOrderId(uint256 id);
    event Unpaused(address account);

    receive() external payable;

    function DENOMINATOR() external view returns (uint256);
    function _APPROVE_PROXY() external view returns (address);
    function _WETH() external view returns (address);
    function _WNATIVE_RELAY() external view returns (address);
    function commissionRateLimit() external view returns (uint256);
    function initialize() external;
    function owner() external view returns (address);
    function paused() external view returns (bool);
    function renounceOwnership() external;
    function swapWrap(uint256 orderId, uint256 rawdata) external payable;
    function transferOwnership(address newOwner) external;
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes memory data) external;
    function uniswapV3SwapExactOutTo(uint256 receiver, uint256 amountOut, uint256 maxConsume, uint256[] memory pools)
        external
        payable
        returns (uint256 consumeAmount);
    function unxswapExactOutTo(
        uint256 srcToken,
        uint256 amount,
        uint256 maxConsume,
        address receiver,
        bytes32[] memory pools
    ) external payable returns (uint256 consumeAmount);
    function unxswapExactOutToByOrderID(uint256 srcToken, uint256 amount, uint256 maxConsume, bytes32[] memory pools)
        external
        payable
        returns (uint256 consumeAmount);
    function version() external view returns (string memory);
}
