// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

library PMMLib {
    struct PMMSwapRequest {
        uint256 pathIndex;
        address payer;
        address fromToken;
        address toToken;
        uint256 fromTokenAmountMax;
        uint256 toTokenAmountMax;
        uint256 salt;
        uint256 deadLine;
        bool isPushOrder;
        bytes extension;
    }
}

interface DexRouter {
    struct BaseRequest {
        uint256 fromToken;
        address toToken;
        uint256 fromTokenAmount;
        uint256 minReturnAmount;
        uint256 deadLine;
    }

    struct RouterPath {
        address[] mixAdapters;
        address[] assetTo;
        uint256[] rawData;
        bytes[] extraData;
        uint256 fromToken;
    }

    error SafeTransferFailed();

    event CommissionFromTokenRecord(
        address fromTokenAddress,
        uint256 commissionAmount,
        address referrerAddress
    );
    event CommissionToTokenRecord(
        address toTokenAddress,
        uint256 commissionAmount,
        address referrerAddress
    );
    event OrderRecord(
        address fromToken,
        address toToken,
        address sender,
        uint256 fromAmount,
        uint256 returnAmount
    );
    event SwapOrderId(uint256 id);

    receive() external payable;

    function DENOMINATOR() external view returns (uint256);
    function _APPROVE_PROXY() external view returns (address);
    function _WETH() external view returns (address);
    function _WNATIVE_RELAY() external view returns (address);
    function commissionRateLimit() external view returns (uint256);
    function smartSwapByInvest(
        BaseRequest memory baseRequest,
        uint256[] memory batchesAmount,
        RouterPath[][] memory batches,
        PMMLib.PMMSwapRequest[] memory extraData,
        address to
    ) external payable returns (uint256 returnAmount);
    function smartSwapByInvestWithRefund(
        BaseRequest memory baseRequest,
        uint256[] memory batchesAmount,
        RouterPath[][] memory batches,
        PMMLib.PMMSwapRequest[] memory extraData,
        address to,
        address refundTo
    ) external payable returns (uint256 returnAmount);
    function smartSwapByOrderId(
        uint256 orderId,
        BaseRequest memory baseRequest,
        uint256[] memory batchesAmount,
        RouterPath[][] memory batches,
        PMMLib.PMMSwapRequest[] memory extraData
    ) external payable returns (uint256 returnAmount);
    function smartSwapTo(
        uint256 orderId,
        address receiver,
        BaseRequest memory baseRequest,
        uint256[] memory batchesAmount,
        RouterPath[][] memory batches,
        PMMLib.PMMSwapRequest[] memory extraData
    ) external payable returns (uint256 returnAmount);
    function swapWrap(uint256 orderId, uint256 rawdata) external payable;
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes memory
    ) external;
    function uniswapV3SwapTo(
        uint256 receiver,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory pools
    ) external payable returns (uint256 returnAmount);
    function unxswapByOrderId(
        uint256 srcToken,
        uint256 amount,
        uint256 minReturn,
        bytes32[] memory pools
    ) external payable returns (uint256 returnAmount);
    function unxswapTo(
        uint256 srcToken,
        uint256 amount,
        uint256 minReturn,
        address receiver,
        bytes32[] memory pools
    ) external payable returns (uint256 returnAmount);
    function version() external view returns (string memory);
}
