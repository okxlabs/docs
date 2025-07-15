// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "../interface/IDexRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SmartSwap {
    address internal constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant _WETH =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 internal constant _ONE_FOR_ZERO_MASK = 1 << 255; // Mask for identifying if the swap is one-for-zero
    uint256 private constant _WETH_UNWRAP_MASK = 1 << 253; // Mask for identifying if WETH should be unwrapped to ETH

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
        uint256 orderId,
        address srcToken_,
        uint256 amount,
        uint256 minReturn,
        address receiver,
        address[] calldata pools_,
        bool[] calldata zeroForOne,
        bool receiveEth,
        bool isFromTokenCommission,
        address toToken
    ) external payable {
        // validate
        if (isFromTokenCommission) {
            // FromToken commission: Swap amount + commission amount = 100 %
            uint swapAmount = amount;
            uint amountTotal = (amount * 10 ** 9) / (10 ** 9 - rate1 - rate2);
            if (msg.value > 0) {
                require(msg.value >= amountTotal, "msg.value < amountTotal");
            } else {
                require(
                    IERC20(srcToken_).balanceOf(address(this)) >= amountTotal,
                    "balanceOf(fromToken) < amountTotal"
                );
            }
        }
        require(receiver != address(0), "not addr(0)");
        // srcToken_ == _ETH means ETH
        srcToken_ = srcToken_ == address(0) ? _ETH : srcToken_;
        uint srcToken = (orderId << 160) | uint256(uint160(srcToken_));
        bytes32[] memory pools = new bytes32[](pools_.length);
        for (uint i = 0; i < pools_.length; i++) {
            uint poolAddress = uint256(uint160(pools_[i]));

            uint isReverse = zeroForOne[i] ? 0 : _ONE_FOR_ZERO_MASK;
            uint isReceiveEth = receiveEth ? _WETH_UNWRAP_MASK : 0;
            uint pool = poolAddress | isReverse | isReceiveEth;
            pools[i] = bytes32(pool);
        }
        bytes memory swapData = abi.encodeWithSelector(
            dexRouter.uniswapV3SwapTo.selector,
            receiver,
            amount,
            minReturn,
            pools
        );
        bytes memory data = bytes.concat(
            swapData,
            _getCommissionInfo(
                true,
                true,
                isFromTokenCommission,
                isFromTokenCommission ? srcToken_ : toToken
            )
        );
        (bool s, bytes memory res) = address(dexRouter).call(data);
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
