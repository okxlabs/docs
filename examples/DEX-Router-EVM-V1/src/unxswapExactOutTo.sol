// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "../interface/IDexRouterExactOut.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract unxswapExactOutTo {
    address internal constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant _WETH =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // Masks for pool configuration
    uint256 internal constant _REVERSE_MASK =
        0x8000000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant _WETH_MASK =
        0x4000000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant _NUMERATOR_MASK =
        0x0000000000000000ffffffff0000000000000000000000000000000000000000;
    uint256 internal constant _ADDRESS_MASK =
        0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 private constant _WETH_UNWRAP_MASK =
        0x2000000000000000000000000000000000000000000000000000000000000000;

    // Commission constants
    uint256 constant FROM_TOKEN_COMMISSION =
        0x3ca20afc2aaa0000000000000000000000000000000000000000000000000000;
    uint256 constant TO_TOKEN_COMMISSION =
        0x3ca20afc2bbb0000000000000000000000000000000000000000000000000000;
    uint256 constant FROM_TOKEN_COMMISSION_DUAL =
        0x22220afc2aaa0000000000000000000000000000000000000000000000000000;
    uint256 constant TO_TOKEN_COMMISSION_DUAL =
        0x22220afc2bbb0000000000000000000000000000000000000000000000000000;

    address public refer1;
    address public refer2;
    uint256 public rate1;
    uint256 public rate2;

    DexRouterExactOut public dexRouterExactOut;
    address public tokenApprove;

    constructor(
        address _dexRouterExactOut,
        address _tokenApprove,
        address _refer1,
        address _refer2,
        uint256 _rate1,
        uint256 _rate2
    ) {
        dexRouterExactOut = DexRouterExactOut(payable(_dexRouterExactOut));
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

    /// @notice Performs an exact output swap with commission handling
    /// @param orderId Unique identifier for the swap order
    /// @param srcToken_ Source token address (use address(0) for ETH)
    /// @param amountOut Exact amount of output tokens to receive
    /// @param maxConsume Maximum amount of source tokens to consume (slippage protection)
    /// @param receiver Address to receive the output tokens
    /// @param pools_ Array of pool addresses for the swap route
    /// @param zeroForOne Array indicating swap direction for each pool
    /// @param numerator Array of numerators for each pool
    /// @param receiveEth Whether to receive ETH instead of WETH
    /// @param isFromTokenCommission Whether commission is taken from source token
    /// @param toToken Target token address (used for commission calculation)
    /// @param isV3 Whether to use Uniswap V3 protocol
    /// @return consumeAmount Actual amount of source tokens consumed
    function performSwap(
        uint256 orderId,
        address srcToken_,
        uint256 amountOut,
        uint256 maxConsume,
        address receiver,
        address[] calldata pools_,
        bool[] calldata zeroForOne,
        uint256[] calldata numerator,
        bool receiveEth,
        bool isFromTokenCommission,
        address toToken,
        bool isV3
    ) external payable returns (uint256 consumeAmount) {
        require(receiver != address(0), "receiver cannot be zero address");
        require(pools_.length > 0, "pools cannot be empty");
        require(amountOut > 0, "amountOut must be greater than zero");
        require(maxConsume > 0, "maxConsume must be greater than zero");

        // Handle ETH input
        srcToken_ = srcToken_ == _ETH ? address(0) : srcToken_;

        bytes memory swapData = _buildV2SwapData(
            orderId,
            srcToken_,
            amountOut,
            maxConsume,
            receiver,
            pools_,
            zeroForOne,
            numerator,
            receiveEth
        );

        // Add commission information
        bytes memory commissionData = _getCommissionInfo(
            true, // hasNextRefer (dual commission)
            true, // isToB
            isFromTokenCommission,
            isFromTokenCommission ? srcToken_ : toToken
        );

        bytes memory data = bytes.concat(swapData, commissionData);

        // Execute the swap
        (bool success, bytes memory result) = address(dexRouterExactOut).call{
            value: msg.value
        }(data);
        require(success, string(result));

        // Decode the return value
        consumeAmount = abi.decode(result, (uint256));

        return consumeAmount;
    }

    /// @notice Builds V2 swap data for exact out swaps
    function _buildV2SwapData(
        uint256 orderId,
        address srcToken_,
        uint256 amountOut,
        uint256 maxConsume,
        address receiver,
        address[] calldata pools_,
        bool[] calldata zeroForOne,
        uint256[] calldata numerator,
        bool receiveEth
    ) internal pure returns (bytes memory) {
        uint256 srcToken = (orderId << 160) | uint256(uint160(srcToken_));

        bytes32[] memory pools = new bytes32[](pools_.length);
        for (uint256 i = 0; i < pools_.length; i++) {
            uint256 poolAddress = uint256(uint160(pools_[i]));
            uint256 numerator_ = (numerator[i] << 160) & _NUMERATOR_MASK;
            uint256 isReverse = zeroForOne[i] ? 0 : _REVERSE_MASK;
            uint256 isReceiveEth = receiveEth ? _WETH_MASK : 0;

            uint256 pool = poolAddress | numerator_ | isReverse | isReceiveEth;
            pools[i] = bytes32(pool);
        }

        return
            abi.encodeWithSelector(
                DexRouterExactOut.unxswapExactOutTo.selector,
                srcToken,
                amountOut,
                maxConsume,
                receiver,
                pools
            );
    }

    /// @notice Builds commission information for the swap
    function _getCommissionInfo(
        bool _hasNextRefer,
        bool _isToB,
        bool _isFrom,
        address _token
    ) internal view returns (bytes memory data) {
        // Handle ETH address conversion
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
