// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "../interface/IDexRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SmartSwap {
    address internal constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 internal constant _ADDRESS_MASK =
        0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 constant FROM_TOKEN_COMMISSION =
        0x3ca20afc2aaa0000000000000000000000000000000000000000000000000000;
    uint256 constant TO_TOKEN_COMMISSION =
        0x3ca20afc2bbb0000000000000000000000000000000000000000000000000000;
    uint256 constant FROM_TOKEN_COMMISSION_DUAL =
        0x22220afc2aaa0000000000000000000000000000000000000000000000000000;
    uint256 constant TO_TOKEN_COMMISSION_DUAL =
        0x22220afc2bbb0000000000000000000000000000000000000000000000000000;
    uint256 constant _TO_B_COMMISSION_MASK =
        0x8000000000000000000000000000000000000000000000000000000000000000;

    address public refer1;
    address public refer2;
    uint256 public rate1;
    uint256 public rate2;

    DexRouter public dexRouter;
    address public tokenApprove;

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    constructor(
        address _dexRouter,
        address _tokenApprove,
        address _refer1,
        address _refer2,
        uint256 _rate1,
        uint256 _rate2
    ) {
        dexRouter = DexRouter(payable(_dexRouter));
        tokenApprove = _tokenApprove;
        refer1 = _refer1;
        refer2 = _refer2;
        require(_rate1 < 10 ** 9, "rate1 must be less than 10**9");
        require(_rate2 < 10 ** 9, "rate2 must be less than 10**9");
        require(
            _rate1 + _rate2 < 0.03 * 10 ** 9,
            "rate1 + rate2 must be less than 0.03"
        );
        rate1 = _rate1;
        rate2 = _rate2;
    }

    function performTokenSwap(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 minReturn,
        address adapter,
        address poolAddress,
        bool isFromTokenCommission
    ) external payable {
        // Step 1: Approve tokens for spending
        // fromToken == _ETH means ETH
        fromToken = fromToken == address(0) ? _ETH : fromToken;
        if (fromToken != _ETH) {
            IERC20(fromToken).approve(tokenApprove, type(uint256).max);
        }
        // validate
        if (isFromTokenCommission) {
            // FromToken commission: Swap amount + commission amount = 100 %
            uint swapAmount = amount;
            uint amountTotal = (amount * 10 ** 9) / (10 ** 9 - rate1 - rate2);
            if (msg.value > 0) {
                require(msg.value >= amountTotal, "msg.value < amountTotal");
            } else {
                require(
                    IERC20(fromToken).balanceOf(address(this)) >= amountTotal,
                    "balanceOf(fromToken) < amountTotal"
                );
            }
        }

        // Step 2: Prepare swap info structure
        SwapInfo memory swapInfo;

        // Step 3: Setup base request
        swapInfo.baseRequest.fromToken = uint256(uint160(fromToken));
        swapInfo.baseRequest.toToken = toToken;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = minReturn;
        swapInfo.baseRequest.deadLine = block.timestamp + 300; // 5 minutes deadline

        // Step 4: Setup batch amounts
        swapInfo.batchesAmount = new uint256[](1);
        swapInfo.batchesAmount[0] = amount;

        // Step 5: Setup routing batches
        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);

        // Setup adapter
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = adapter;

        // Setup asset destination - tokens go to adapter
        swapInfo.batches[0][0].assetTo = new address[](1);
        swapInfo.batches[0][0].assetTo[0] = adapter;

        // Setup raw data with correct encoding: reverse(1byte) + weight(11bytes) + poolAddress(20bytes)
        swapInfo.batches[0][0].rawData = new uint256[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(
            bytes32(abi.encodePacked(uint8(0x00), uint88(10000), poolAddress))
        );

        // Setup adapter-specific extra data
        swapInfo.batches[0][0].extraData = new bytes[](1);
        swapInfo.batches[0][0].extraData[0] = abi.encode(
            bytes32(uint256(uint160(fromToken))),
            bytes32(uint256(uint160(toToken)))
        );

        swapInfo.batches[0][0].fromToken = uint256(uint160(fromToken));

        // Step 6: Setup PMM extra data (empty for basic swaps)
        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        // Step 7: Execute the swap
        bytes memory swapData = abi.encodeWithSelector(
            dexRouter.smartSwapByOrderId.selector,
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );
        // Step 8: Execute the swap with commission
        bytes memory data = bytes.concat(
            swapData,
            _getCommissionInfo(
                true,
                true,
                isFromTokenCommission,
                isFromTokenCommission ? fromToken : toToken
            )
        );
        (bool s, bytes memory res) = address(dexRouter).call{value: msg.value}(
            data
        );
        require(s, string(res));
        // returnAmount contains the actual tokens received
    }

    function _getCommissionInfo(
        bool _hasNextRefer,
        bool _isToB,
        bool _isFrom,
        address _token
    ) internal view returns (bytes memory data) {
        // _token == _ETH means ETH
        _token = _token == address(0) ? _ETH : _token;
        uint256 flag = _isFrom
            ? (
                _hasNextRefer
                    ? FROM_TOKEN_COMMISSION_DUAL
                    : FROM_TOKEN_COMMISSION
            )
            : (_hasNextRefer ? TO_TOKEN_COMMISSION_DUAL : TO_TOKEN_COMMISSION);

        bytes32 first = bytes32(
            flag + uint256(rate1 << 160) + uint256(uint160(refer1))
        );
        bytes32 middle = bytes32(
            abi.encodePacked(uint8(_isToB ? 0x80 : 0), uint88(0), _token)
        );
        bytes32 last = bytes32(
            flag + uint256(rate2 << 160) + uint256(uint160(refer2))
        );

        return
            _hasNextRefer
                ? abi.encode(last, middle, first)
                : abi.encode(middle, first);
    }
}
