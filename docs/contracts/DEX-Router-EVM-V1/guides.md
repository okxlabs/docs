# DEX-Router-EVM Implementation Guides

## Getting Started

These guides will help you implement **production-ready** token swapping functionality using the DEX-Router-EVM system. Each guide is designed to be completed within 10 minutes and provides complete, working smart contracts based on real implementation examples.

**💡 Production-Ready Examples**: All code examples in these guides are derived from actual working smart contracts and are available in our [examples folder](../../../examples/DEX-Router-EVM-V1) for easy copy-paste implementation.

**📋 Seven Complete Guides**: We provide comprehensive guides covering all major swap types:
- **Guide 1**: Smart Swap with Commission System (`smartswap.sol`)
- **Guide 2**: ETH/WETH Wrapping Operations (`swapWrap.sol`)
- **Guide 3**: Pre-funded Contract Swaps (`smartswapByInvest.sol`)
- **Guide 4**: V2-Style Exact Output Swaps (`unxswapExactOutTo.sol`)
- **Guide 5**: V3-Style Exact Output Swaps (`uniswapV3SwapExactOutTo.sol`)
- **Guide 6**: Gas-Efficient V2-Style Swaps (`unxswap.sol`)
- **Guide 7**: Uniswap V3 Optimized Swaps (`uniswapV3swap.sol`)

**🔧 What's Different**: Unlike simplified tutorial examples, these guides show you the complete implementation including commission handling, proper parameter encoding, adapter configuration, and production-grade error handling.

## Prerequisites

- Basic understanding of Solidity and smart contracts
- Access to a deployed DexRouter contract
- Node.js and npm installed
- Hardhat development environment

## Guide 1: Simple Token Swap with Commission System

### Introduction
This guide demonstrates how to execute a production-ready token swap using the DexRouter with advanced features including commission handling, proper parameter encoding, and adapter-based routing. You'll learn to build a complete smart contract that can handle real-world DEX aggregation with flexible referral systems.

### What You'll Build
A comprehensive smart swap contract that exchanges tokens with configurable commission distribution, adapter routing, and production-grade parameter handling.

### Implementation

**Step 1: Complete Contract Setup**
```solidity
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
}
```

**Step 2: Implement Advanced Swap Function**
```solidity
function performTokenSwap(
    address fromToken,
    address toToken,
    uint256 amount,
    uint256 minReturn,
    address adapter,
    address poolAddress,
    bool isFromTokenCommission
) external payable {
    // Step 1: Handle ETH and token approval
    fromToken = fromToken == address(0) ? _ETH : fromToken;
    if (fromToken != _ETH) {
        IERC20(fromToken).approve(tokenApprove, type(uint256).max);
    }
    
    // Step 2: Validate commission amounts
    if (isFromTokenCommission) {
        // FromToken commission: Swap amount + commission amount = 100%
        uint256 amountTotal = amount * 10**9 / (10**9 - rate1 - rate2);
        if (msg.value > 0) {
            require(msg.value >= amountTotal, "msg.value < amountTotal");
        } else {
            require(IERC20(fromToken).balanceOf(address(this)) >= amountTotal, "balanceOf(fromToken) < amountTotal");
        }
    }

    // Step 3: Prepare swap info structure
    SwapInfo memory swapInfo;

    // Step 4: Setup base request
    swapInfo.baseRequest.fromToken = uint256(uint160(fromToken));
    swapInfo.baseRequest.toToken = toToken;
    swapInfo.baseRequest.fromTokenAmount = amount;
    swapInfo.baseRequest.minReturnAmount = minReturn;
    swapInfo.baseRequest.deadLine = block.timestamp + 300; // 5 minutes deadLine

    // Step 5: Setup batch amounts
    swapInfo.batchesAmount = new uint256[](1);
    swapInfo.batchesAmount[0] = amount;

    // Step 6: Setup routing batches
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

    // Step 7: Setup PMM extra data (empty for basic swaps)
    swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

    // Step 8: Execute the swap
    bytes memory swapData = abi.encodeWithSelector(
        dexRouter.smartSwapByOrderId.selector,
        swapInfo.orderId,
        swapInfo.baseRequest,
        swapInfo.batchesAmount,
        swapInfo.batches,
        swapInfo.extraData
    );
    
    // Step 9: Execute the swap with commission
    bytes memory data = bytes.concat(
        swapData,
        _getCommissionInfo(true, true, isFromTokenCommission, isFromTokenCommission ? fromToken : toToken)
    );
    (bool s, bytes memory res) = address(dexRouter).call{value: msg.value}(data);
    require(s, string(res));
    // returnAmount contains the actual tokens received
}
```

**Step 3: Commission Handling (Advanced Feature)**
```solidity
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
    
    return _hasNextRefer
        ? abi.encode(last, middle, first)
        : abi.encode(middle, first);
}
```

**Step 4: Usage Example**
```solidity
// Deploy the contract with commission configuration
SmartSwap swapper = new SmartSwap(
    dexRouterAddress,
    approveProxyAddress,
    0x000000000000000000000000000000000000dEaD, // refer1
    0x000000000000000000000000000000000000bEEF, // refer2
    0.0001 * 10 ** 9, // rate1 (0.01%)
    0.00002 * 10 ** 9 // rate2 (0.002%)
);

// Execute a swap with USDT → USDC
swapper.performTokenSwap(
    0xdAC17F958D2ee523a2206206994597C13D831ec7, // USDT
    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // USDC  
    1000 * 1e6, // 1000 USDT
    990 * 1e6,  // Min 990 USDC (1% slippage)
    uniV3AdapterAddress,
    uniV3PoolAddress,
    false // isFromTokenCommission (take commission from output token)
);
```

### Expected Output
- Input: 1000 USDT
- Output: ~1000 USDC (minus fees and slippage)
- Gas: ~200,000 gas units (includes commission processing)
- Commission: Automatic fee distribution to referrers based on configured rates

**Key Features Demonstrated:**
- Flexible commission configuration in constructor
- Complete swap parameter setup and encoding
- Low-level call execution with commission data
- Adapter-based routing with proper parameter validation

**📁 Complete Example**: View the [complete SmartSwap example](../../../examples/DEX-Router-EVM-V1/src/smartswap.sol) in our repository.

---

## Guide 2: ETH/WETH Swap with Native Token Handling

### Introduction
This guide demonstrates how to handle native ETH swaps using the router's built-in ETH/WETH conversion capabilities. You'll learn to use the specialized `swapWrap` function for efficient wrapping and unwrapping operations with commission handling.

### What You'll Build
A contract that can wrap ETH to WETH and unwrap WETH to ETH seamlessly using the router's optimized swap functionality.

### Implementation

**Step 1: ETH Swap Contract Setup**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interface/IDexRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SmartSwap {
    using SafeERC20 for IERC20;
    
    address internal constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant _WETH =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
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
}
```

**Step 2: Implement Swap Wrap Function**
```solidity
function performTokenSwap(
    bool unwrap,
    uint256 amount,
    uint256 orderId
) external payable {
    if (unwrap) {
        // step1 : approve WETH
        IERC20(_WETH).safeApprove(tokenApprove, amount);
    }
    
    // step2 : encode rawData
    uint256 rawData = uint256(
        bytes32(
            abi.encodePacked(
                uint8(unwrap ? 0x80 : 0x00),
                uint120(0),
                uint128(amount)
            )
        )
    );
    
    // Step 7: Execute the swap
    bytes memory swapData = abi.encodeWithSelector(
        dexRouter.swapWrap.selector,
        orderId,
        rawData
    );
    
    // Step 8: Execute the swap with commission
    bytes memory data = bytes.concat(
        swapData,
        _getCommissionInfo(true, true, true, unwrap ? _WETH : _ETH)
    );
    (bool s, bytes memory res) = address(dexRouter).call(data);
    require(s, string(res));
    // returnAmount contains the actual tokens received
}
```

**Step 3: Commission Handling for ETH/WETH**
```solidity
function _getCommissionInfo(
    bool _hasNextRefer,
    bool _isToB,
    bool _isFrom,
    address _token
) internal view returns (bytes memory data) {
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
    
    uint256 status;
    assembly {
        function _getStatus(token, isToB, hasNextRefer) -> d {
            let a := mul(eq(token, _ETH), 256)
            let b := mul(isToB, 16)
            let c := hasNextRefer
            d := add(a, add(b, c))
        }
        status := _getStatus(_token, _isToB, _hasNextRefer)
    }
    
    return _hasNextRefer
        ? abi.encode(last, middle, first)
        : abi.encode(middle, first);
}
```

**Step 4: Usage Examples**
```solidity
// Deploy the contract with commission configuration
SmartSwap ethSwapper = new SmartSwap(
    dexRouterAddress,
    approveProxyAddress,
    0x000000000000000000000000000000000000dEaD, // refer1
    0x000000000000000000000000000000000000bEEF, // refer2
    0.0001 * 10 ** 9, // rate1 (0.01%)
    0.00002 * 10 ** 9 // rate2 (0.002%)
);

// Wrap ETH to WETH
ethSwapper.performTokenSwap{value: 1 ether}(
    false,    // unwrap = false (wrap ETH to WETH)
    1 ether,  // amount
    1         // orderId
);

// Unwrap WETH to ETH
ethSwapper.performTokenSwap(
    true,     // unwrap = true (unwrap WETH to ETH)
    1 ether,  // amount
    2         // orderId
);
```

### Expected Output
- **Wrap**: 1 ETH → 1 WETH (minus commission)
- **Unwrap**: 1 WETH → 1 ETH (minus commission)
- **Gas**: ~150,000 gas units per operation
- **Commission**: Automatic fee distribution to referrers

**Key Features Demonstrated:**
- Specialized `swapWrap` function for ETH/WETH operations
- Efficient raw data encoding for wrap/unwrap operations
- Commission handling for both ETH and WETH
- Simplified interface for wrap/unwrap functionality

**📁 Complete Example**: View the [complete ETH Swap example](../../../examples/DEX-Router-EVM-V1/src/swapWrap.sol) in our repository.

---

## Guide 3: Pre-funded Contract Swaps

### Introduction
This guide shows how to use the specialized `smartSwapByInvest` function for pre-funded scenarios. This function is optimized for cases where tokens are already held by the router contract, allowing for efficient rebalancing and contract-based swap operations.

### What You'll Build
A smart contract that demonstrates direct token transfers to the DexRouter and execution of swaps optimized for pre-funded use cases where tokens are already in the router's balance.

### Implementation

**Step 1: Pre-funded Contract with smartSwapByInvest**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interface/IDexRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SmartSwap {
    using SafeERC20 for IERC20;

    DexRouter public dexRouter;
    address public tokenApprove;

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    constructor(address _dexRouter, address _tokenApprove) {
        dexRouter = DexRouter(payable(_dexRouter));
        tokenApprove = _tokenApprove;
    }

    function performTokenSwap(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 minReturn,
        address adapter,
        address poolAddress
    ) external {
        // Step 1: Transfer tokens directly to dexRouter for pre-funded swaps
        IERC20(fromToken).safeTransferFrom(
            msg.sender,
            address(dexRouter),
            amount
        );

        // Step 2: Prepare swap info structure
        SwapInfo memory swapInfo;

        // Step 3: Setup base request
        swapInfo.baseRequest.fromToken = uint256(uint160(fromToken));
        swapInfo.baseRequest.toToken = toToken;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = minReturn;
        swapInfo.baseRequest.deadLine = block.timestamp + 300; // 5 minutes deadLine

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

        // Step 7: Execute the pre-funded swap
        uint256 returnAmount = dexRouter.smartSwapByInvest(
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData,
            msg.sender // Send tokens to the user
        );

        // returnAmount contains the actual tokens received
    }
}
```

**Step 2: Usage Example**
```solidity
// Deploy pre-funded contract
SmartSwap preFundedSwap = new SmartSwap(
    dexRouterAddress, 
    approveProxyAddress
);

// Approve tokens first
IERC20(usdcAddress).approve(address(preFundedSwap), 5000 * 1e6);

// Execute pre-funded swap: USDC → DAI
preFundedSwap.performTokenSwap(
    usdcAddress,      // From USDC
    daiAddress,       // To DAI
    5000 * 1e6,       // 5000 USDC
    4950 * 1e18,      // Min 4950 DAI (1% slippage)
    curveAdapterAddress,
    curveUsdcDaiPoolAddress
);

// The DAI tokens are automatically sent to msg.sender
```

### Expected Output
- Input: 5000 USDC
- Output: ~4950 DAI (to user's wallet)
- Gas: ~180,000 gas units
- Direct token transfer to user (not to contract)

**Key Features Demonstrated:**
- `smartSwapByInvest` function usage
- Direct token transfer to DexRouter
- Simplified structure without commission handling
- Pre-funded contract workflow

**📁 Complete Example**: View the [complete Pre-funded SmartSwap example](../../../examples/DEX-Router-EVM-V1/src/smartswapByInvest.sol) in our repository.

---

## Guide 4: V2-Style Exact Output Swaps - Predictable Outcomes

### Introduction
This guide demonstrates how to use the V2-style exact output router system to execute swaps where you specify exactly how much output you want to receive and set a maximum limit on how much input you're willing to spend. This is perfect for scenarios where you need predictable outcomes with V2-compatible pools.

### What You'll Build
A smart contract that demonstrates V2-style exact output swaps with commission handling, cost protection, and proper pool configuration for Uniswap V2-compatible pools.

### Key Concepts

#### Exact Output vs Exact Input
- **Exact Input (Standard)**: "I want to swap exactly 1000 USDC for as much ETH as possible"
- **Exact Output (This Guide)**: "I want to receive exactly 1 ETH and will pay up to 3000 USDC"

#### Benefits of Exact Output
- **Predictable Outcomes**: Know exactly how much you'll receive
- **Cost Control**: Set maximum spending limits
- **DeFi Integration**: Perfect for protocols that need exact amounts
- **Payment Scenarios**: Ideal for paying exact amounts in different tokens

### Implementation

**Step 1: V2 ExactOut Contract Setup**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interface/IDexRouterExactOut.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SmartSwapExactOut {
    
    address internal constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 internal constant _ADDRESS_MASK =
        0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 internal constant _ORDER_ID_MASK = 
        0xffffffffffffffffffffffff0000000000000000000000000000000000000000;
    
    // Commission constants
    uint256 constant FROM_TOKEN_COMMISSION =
        0x3ca20afc2aaa0000000000000000000000000000000000000000000000000000;
    uint256 constant TO_TOKEN_COMMISSION =
        0x3ca20afc2bbb0000000000000000000000000000000000000000000000000000;
    uint256 constant FROM_TOKEN_COMMISSION_DUAL =
        0x22220afc2aaa0000000000000000000000000000000000000000000000000000;
    uint256 constant TO_TOKEN_COMMISSION_DUAL =
        0x22220afc2bbb0000000000000000000000000000000000000000000000000000;

    DexRouterExactOut public dexRouterExactOut;
    address public tokenApprove;
    
    address public refer1;
    address public refer2;
    uint256 public rate1;
    uint256 public rate2;

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
        
        // Validate commission rates
        require(_rate1 < 10 ** 9, "rate1 must be less than 10**9");
        require(_rate2 < 10 ** 9, "rate2 must be less than 10**9");
        require(
            _rate1 + _rate2 < 0.03 * 10 ** 9,
            "rate1 + rate2 must be less than 0.03"
        );
        
        rate1 = _rate1;
        rate2 = _rate2;
    }
}
```

**Step 2: Implement V2-style Exact Output Swap**
```solidity
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
    address toToken
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

event ExactOutputSwapExecuted(
    address indexed fromToken,
    address indexed toToken,
    uint256 exactOutputAmount,
    uint256 consumedAmount,
    uint256 maxInputAmount,
    address indexed receiver
);
```

**Step 3: Implement Uniswap V3 Exact Output Swap**
```solidity
function performV3ExactOutputSwap(
    uint256 orderId,
    address receiver,
    uint256 amountOut,
    uint256 maxConsume,
    address[] calldata pools_,
    bool[] calldata zeroForOne,
    bool receiveEth,
    bool isFromTokenCommission,
    address toToken
) external payable returns (uint256 consumeAmount) {
    require(receiver != address(0), "receiver cannot be zero address");
    require(pools_.length > 0, "pools cannot be empty");
    require(amountOut > 0, "amountOut must be greater than zero");
    require(maxConsume > 0, "maxConsume must be greater than zero");

    // Build V3 swap data
    bytes memory swapData = _buildV3SwapData(
        orderId,
        receiver,
        amountOut,
        maxConsume,
        pools_,
        zeroForOne,
        receiveEth
    );

    // Add commission information
    bytes memory commissionData = _getCommissionInfo(
        true, // hasNextRefer (dual commission)
        true, // isToB
        isFromTokenCommission,
        isFromTokenCommission ? _ETH : toToken
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
```

**Step 3: Commission Handling for ExactOut**
```solidity
function _getCommissionInfo(
    bool _hasNextRefer,
    bool _isToB,
    bool _isFrom,
    address _token
) internal view returns (bytes memory data) {
    uint256 flag = _isFrom
        ? (_hasNextRefer ? FROM_TOKEN_COMMISSION_DUAL : FROM_TOKEN_COMMISSION)
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
    
    return _hasNextRefer
        ? abi.encode(last, middle, first)
        : abi.encode(middle, first);
}
```

**Step 4: Usage Examples**
```solidity
// Deploy the ExactOut contract
SmartSwapExactOut exactOutSwap = new SmartSwapExactOut(
    dexRouterExactOutAddress,
    approveProxyAddress,
    0x000000000000000000000000000000000000dEaD, // refer1
    0x000000000000000000000000000000000000bEEF, // refer2
    0.0001 * 10 ** 9, // rate1 (0.01%)
    0.00002 * 10 ** 9 // rate2 (0.002%)
);

// Example: V2 exact output swap to receive exactly 1000 USDC
// Willing to spend up to 1010 USDT (1% slippage)
address[] memory pools = new address[](1);
pools[0] = usdtUsdcPool;

bool[] memory zeroForOne = new bool[](1);
zeroForOne[0] = true; // USDT is token0

uint256[] memory numerator = new uint256[](1);
numerator[0] = 10000; // 100% weight

exactOutSwap.performSwap(
    1,                  // Order ID
    usdtAddress,        // From USDT
    1000 * 1e6,         // Want exactly 1000 USDC
    1010 * 1e6,         // Max 1010 USDT
    msg.sender,         // Receiver
    pools,              // Routing pools
    zeroForOne,         // Direction
    numerator,          // Numerator
    false,              // receiveEth
    false,              // isFromTokenCommission
    usdcAddress         // To USDC (exact)
);
```

### Expected Output
- **Exact Output**: Always receive the exact amount specified
- **Cost Control**: Never spend more than your maximum limit
- **V2 Compatibility**: Works with Uniswap V2-style pools
- **Commission**: Integrated fee collection and distribution
- **Gas**: ~180,000 gas units for V2 exact output swaps

### Key Features Demonstrated
- **V2 Exact Output Control**: Always receive the exact amount specified using V2 pools
- **Cost Protection**: Maximum input limits prevent overspending
- **Pool Configuration**: Proper encoding for V2-style pools with numerator weights
- **Commission Integration**: Built-in referral system
- **ETH/WETH Handling**: Seamless native token conversion

### Security Considerations
- **Input Validation**: Always validate maximum input amounts
- **Slippage Calculation**: Account for price impact in max input
- **Pool Configuration**: Ensure proper pool encoding with correct numerators
- **Commission Validation**: Ensure commission rates are reasonable

### Common Use Cases
1. **Payment Systems**: Pay exact amounts using V2 pools
2. **DeFi Protocols**: Receive exact amounts for further processing
3. **Yield Farming**: Deposit exact amounts into pools
4. **Arbitrage**: Execute precise arbitrage amounts with V2 pools

**📁 Complete Example**: View the [complete V2 ExactOut example](examples/DEX-Router-EVM-V1/src/unxswapExactOutTo.sol) in our repository.

---

## Guide 5: V3-Style Exact Output Swaps - Concentrated Liquidity

### Introduction
This guide demonstrates how to use the V3-style exact output router system to execute swaps where you specify exactly how much output you want to receive using Uniswap V3 concentrated liquidity pools. This approach is optimized for precise price execution and gas efficiency with V3 pools.

### What You'll Build
A smart contract that demonstrates V3-style exact output swaps with commission handling, cost protection, and proper pool configuration for Uniswap V3 concentrated liquidity pools.

### Key Concepts

#### V3 Concentrated Liquidity Benefits
- **Precise Price Control**: Leverage concentrated liquidity for better price execution
- **Gas Efficiency**: Optimized for V3 pool interactions
- **Exact Output**: Know exactly how much you'll receive
- **Cost Control**: Set maximum spending limits

### Implementation

**Step 1: V3 ExactOut Contract Setup**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interface/IDexRouterExactOut.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SmartSwapExactOut {
    address internal constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // V3 pool configuration masks
    uint256 internal constant _REVERSE_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant _WETH_UNWRAP_MASK = 0x2000000000000000000000000000000000000000000000000000000000000000;
    uint256 internal constant _ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

    // Commission constants
    uint256 constant FROM_TOKEN_COMMISSION = 0x3ca20afc2aaa0000000000000000000000000000000000000000000000000000;
    uint256 constant TO_TOKEN_COMMISSION = 0x3ca20afc2bbb0000000000000000000000000000000000000000000000000000;
    uint256 constant FROM_TOKEN_COMMISSION_DUAL = 0x22220afc2aaa0000000000000000000000000000000000000000000000000000;
    uint256 constant TO_TOKEN_COMMISSION_DUAL = 0x22220afc2bbb0000000000000000000000000000000000000000000000000000;

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
        require(_rate1 + _rate2 < 0.03 * 10 ** 9, "rate1 + rate2 must be less than 0.03");
        rate1 = _rate1;
        rate2 = _rate2;
    }
}
```

**Step 2: Implement V3-style Exact Output Swap**
```solidity
function performSwap(
    uint256 orderId,
    address receiver,
    uint256 amountOut,
    uint256 maxConsume,
    address[] calldata pools_,
    bool[] calldata zeroForOne,
    bool receiveEth,
    bool isFromTokenCommission,
    address toToken
) external payable returns (uint256 consumeAmount) {
    require(receiver != address(0), "receiver cannot be zero address");
    require(pools_.length > 0, "pools cannot be empty");
    require(amountOut > 0, "amountOut must be greater than zero");
    require(maxConsume > 0, "maxConsume must be greater than zero");

    // Build V3 swap data
    bytes memory swapData = _buildV3SwapData(
        orderId,
        receiver,
        amountOut,
        maxConsume,
        pools_,
        zeroForOne,
        receiveEth
    );

    // Add commission information
    bytes memory commissionData = _getCommissionInfo(
        true, // hasNextRefer (dual commission)
        true, // isToB
        isFromTokenCommission,
        isFromTokenCommission ? _ETH : toToken
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
```

**Step 3: V3 Pool Configuration Helper**
```solidity
/// @notice Builds V3 swap data for exact out swaps
function _buildV3SwapData(
    uint256 orderId,
    address receiver,
    uint256 amountOut,
    uint256 maxConsume,
    address[] calldata pools_,
    bool[] calldata zeroForOne,
    bool receiveEth
) internal pure returns (bytes memory) {
    uint256 receiverWithOrderId = (orderId << 160) | uint256(uint160(receiver));

    uint256[] memory pools = new uint256[](pools_.length);
    for (uint256 i = 0; i < pools_.length; i++) {
        uint256 poolAddress = uint256(uint160(pools_[i]));
        uint256 isReverse = zeroForOne[i] ? 0 : _REVERSE_MASK;
        uint256 isReceiveEth = receiveEth ? _WETH_UNWRAP_MASK : 0;

        pools[i] = poolAddress | isReverse | isReceiveEth;
    }

    return abi.encodeWithSelector(
        DexRouterExactOut.uniswapV3SwapExactOutTo.selector,
        receiverWithOrderId,
        amountOut,
        maxConsume,
        pools
    );
}
```

**Step 4: Commission Handling for V3 ExactOut**
```solidity
function _getCommissionInfo(
    bool _hasNextRefer,
    bool _isToB,
    bool _isFrom,
    address _token
) internal view returns (bytes memory data) {
    // Handle ETH address conversion
    _token = _token == address(0) ? _ETH : _token;

    uint256 flag = _isFrom
        ? (_hasNextRefer ? FROM_TOKEN_COMMISSION_DUAL : FROM_TOKEN_COMMISSION)
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

    return _hasNextRefer
        ? abi.encode(last, middle, first)
        : abi.encode(middle, first);
}
```

**Step 5: Usage Examples**
```solidity
// Deploy the V3 ExactOut contract
SmartSwapExactOut v3ExactOutSwap = new SmartSwapExactOut(
    dexRouterExactOutAddress,
    approveProxyAddress,
    0x000000000000000000000000000000000000dEaD, // refer1
    0x000000000000000000000000000000000000bEEF, // refer2
    0.0001 * 10 ** 9, // rate1 (0.01%)
    0.00002 * 10 ** 9 // rate2 (0.002%)
);

// Example: V3 exact output swap to receive exactly 1 ETH
// Willing to spend up to 3000 USDC (sent as ETH)
address[] memory v3Pools = new address[](1);
v3Pools[0] = ethUsdcV3Pool;

bool[] memory zeroForOne = new bool[](1);
zeroForOne[0] = true; // ETH is token0

uint256 consumeAmount = v3ExactOutSwap.performSwap{value: 3000 * 1e6}(
    1,                  // Order ID
    msg.sender,         // Receiver
    1 ether,            // Want exactly 1 ETH
    3000 * 1e6,         // Max input amount
    v3Pools,            // V3 routing pools
    zeroForOne,         // Direction
    false,              // receiveEth
    true,               // isFromTokenCommission
    _ETH                // toToken
);
```

### Expected Output
- **Exact Output**: Always receive the exact amount specified
- **Cost Control**: Never spend more than your maximum limit
- **V3 Efficiency**: Optimized for concentrated liquidity pools
- **Commission**: Integrated fee collection and distribution
- **Gas**: ~200,000 gas units for V3 exact output swaps

### Key Features Demonstrated
- **V3 Exact Output Control**: Always receive the exact amount specified using V3 pools
- **Cost Protection**: Maximum input limits prevent overspending
- **Concentrated Liquidity**: Leverage V3's concentrated liquidity for better execution
- **Commission Integration**: Built-in referral system
- **ETH/WETH Handling**: Seamless native token conversion with unwrapping support

### Security Considerations
- **Input Validation**: Always validate maximum input amounts
- **Slippage Calculation**: Account for price impact in concentrated liquidity
- **Pool Configuration**: Ensure proper V3 pool encoding
- **Commission Validation**: Ensure commission rates are reasonable

### Common Use Cases
1. **Payment Systems**: Pay exact amounts using V3 concentrated liquidity
2. **DeFi Protocols**: Receive exact amounts with better price execution
3. **Arbitrage**: Execute precise arbitrage amounts with V3 efficiency
4. **Large Trades**: Benefit from concentrated liquidity for substantial swaps

**📁 Complete Example**: View the [complete V3 ExactOut example](../../../examples/DEX-Router-EVM-V1/src/uniswapV3SwapExactOutTo.sol) in our repository.

---

## Guide 6: Gas-Efficient V2-Style Swaps (unxswap)

### Introduction
This guide demonstrates how to use the `unxswapTo` function for gas-efficient swaps through Uniswap V2-style pools. This approach is optimized for scenarios where you need maximum gas efficiency and are working with V2-compatible pools.

### What You'll Build
A smart contract that executes gas-optimized swaps using the `unxswapTo` function with proper pool configuration and commission handling.

### Key Features
- **Gas Optimization**: Lower gas consumption compared to full router functionality
- **V2 Compatibility**: Works with Uniswap V2-style pools
- **Tax Token Support**: Handles tokens with transfer taxes
- **Commission Integration**: Built-in referral system
- **WETH Handling**: Seamless ETH/WETH conversion

### Implementation

**Step 1: Gas-Efficient Swap Contract Setup**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interface/IDexRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SmartSwap {
    
    address internal constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    // Pool configuration masks
    uint256 internal constant _REVERSE_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant _IS_TOKEN0_TAX = 0x1000000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant _IS_TOKEN1_TAX = 0x2000000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant _WETH_MASK = 0x4000000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant _NUMERATOR_MASK = 0x0000000000000000ffffffff0000000000000000000000000000000000000000;
    uint256 internal constant _ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    
    // Commission constants
    uint256 constant FROM_TOKEN_COMMISSION = 0x3ca20afc2aaa0000000000000000000000000000000000000000000000000000;
    uint256 constant TO_TOKEN_COMMISSION = 0x3ca20afc2bbb0000000000000000000000000000000000000000000000000000;
    uint256 constant FROM_TOKEN_COMMISSION_DUAL = 0x22220afc2aaa0000000000000000000000000000000000000000000000000000;
    uint256 constant TO_TOKEN_COMMISSION_DUAL = 0x22220afc2bbb0000000000000000000000000000000000000000000000000000;
    
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
        require(_rate1 < 10**9, "rate1 must be less than 10**9");
        require(_rate2 < 10**9, "rate2 must be less than 10**9");
        require(_rate1 + _rate2 < 0.03 * 10**9, "rate1 + rate2 must be less than 0.03");
        rate1 = _rate1;
        rate2 = _rate2;
    }
}
```

**Step 2: Implement Gas-Efficient Swap Function**
```solidity
function performTokenSwap(
    uint256 orderId,
    address srcToken_,
    uint256 amount,
    uint256 minReturn,
    address receiver,
    address[] calldata pools_,
    bool[] calldata zeroForOne,
    bool[] calldata isToken0Tax,
    bool[] calldata isToken1Tax,
    uint256[] calldata numerator,
    bool receiveEth,
    bool isFromTokenCommission,
    address toToken
) external payable {
    require(receiver != address(0), "receiver cannot be zero address");
    
    // Step 1: Handle commission validation
    if (isFromTokenCommission) {
        uint256 amountTotal = amount * 10**9 / (10**9 - rate1 - rate2);
        if (msg.value > 0) {
            require(msg.value >= amountTotal, "msg.value < amountTotal");
        } else {
            require(IERC20(srcToken_).balanceOf(address(this)) >= amountTotal, "insufficient balance");
        }
    }
    
    // Step 2: Handle ETH address conversion
    srcToken_ = srcToken_ == _ETH ? address(0) : srcToken_;
    
    // Step 3: Encode source token with order ID
    uint256 srcToken = orderId << 160 | uint256(uint160(srcToken_));
    
    // Step 4: Build pool configuration
    bytes32[] memory pools = new bytes32[](pools_.length);
    for (uint256 i = 0; i < pools_.length; i++) {
        uint256 poolAddress = uint256(uint160(pools_[i]));
        uint256 isToken0Tax_ = isToken0Tax[i] ? _IS_TOKEN0_TAX : 0;
        uint256 isToken1Tax_ = isToken1Tax[i] ? _IS_TOKEN1_TAX : 0;
        uint256 numerator_ = (numerator[i] << 160) & _NUMERATOR_MASK;
        uint256 isReverse = zeroForOne[i] ? 0 : _REVERSE_MASK;
        uint256 isReceiveEth = receiveEth ? _WETH_MASK : 0;
        
        uint256 pool = poolAddress | isToken0Tax_ | isToken1Tax_ | numerator_ | isReverse | isReceiveEth;
        pools[i] = bytes32(pool);
    }
    
    // Step 5: Execute gas-efficient swap
    bytes memory swapData = abi.encodeWithSelector(
        dexRouter.unxswapTo.selector,
        srcToken,
        amount,
        minReturn,
        receiver,
        pools
    );
    
    // Step 6: Execute with commission
    bytes memory data = bytes.concat(
        swapData,
        _getCommissionInfo(true, true, isFromTokenCommission, isFromTokenCommission ? srcToken_ : toToken)
    );
    
    (bool success, bytes memory result) = address(dexRouter).call(data);
    require(success, string(result));
    
    emit UnxSwapExecuted(srcToken_, toToken, amount, minReturn, receiver);
}

event UnxSwapExecuted(
    address indexed srcToken,
    address indexed toToken,
    uint256 amount,
    uint256 minReturn,
    address indexed receiver
);
```

**Step 3: Commission Handling Function**
```solidity
function _getCommissionInfo(
    bool _hasNextRefer,
    bool _isToB,
    bool _isFrom,
    address _token
) internal view returns (bytes memory data) {
    _token = _token == address(0) ? _ETH : _token;
    
    uint256 flag = _isFrom
        ? (_hasNextRefer ? FROM_TOKEN_COMMISSION_DUAL : FROM_TOKEN_COMMISSION)
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
    
    return _hasNextRefer
        ? abi.encode(last, middle, first)
        : abi.encode(middle, first);
}
```

**Step 4: Usage Example**
```solidity
// Deploy the gas-efficient swap contract
SmartSwap unxSwap = new SmartSwap(
    dexRouterAddress,
    approveProxyAddress,
    0x000000000000000000000000000000000000dEaD, // refer1
    0x000000000000000000000000000000000000bEEF, // refer2
    0.0001 * 10**9, // rate1 (0.01%)
    0.00002 * 10**9 // rate2 (0.002%)
);

// Execute gas-efficient swap: USDT → USDC
address[] memory pools = new address[](1);
pools[0] = usdtUsdcPool;

bool[] memory zeroForOne = new bool[](1);
zeroForOne[0] = true; // USDT is token0

bool[] memory isToken0Tax = new bool[](1);
isToken0Tax[0] = false; // USDT has no tax

bool[] memory isToken1Tax = new bool[](1);
isToken1Tax[0] = false; // USDC has no tax

uint256[] memory numerator = new uint256[](1);
numerator[0] = 10000; // 100% weight

unxSwap.performTokenSwap(
    1,                    // orderId
    usdtAddress,          // srcToken
    1000 * 1e6,          // amount (1000 USDT)
    990 * 1e6,           // minReturn (990 USDC)
    msg.sender,          // receiver
    pools,               // pools
    zeroForOne,          // zeroForOne
    isToken0Tax,         // isToken0Tax
    isToken1Tax,         // isToken1Tax
    numerator,           // numerator
    false,               // receiveEth
    false,               // isFromTokenCommission
    usdcAddress          // toToken
);
```

### Expected Output
- Input: 1000 USDT
- Output: ~990 USDC (to user's wallet)
- Gas: ~120,000 gas units (optimized)
- Commission: Automatic fee distribution to referrers

**Key Features Demonstrated:**
- Gas-optimized `unxswapTo` function usage
- Efficient pool configuration encoding
- Tax token support with proper flags
- Commission handling for gas-efficient swaps
- WETH conversion capabilities

**📁 Complete Example**: View the [complete UnxSwap example](../../../examples/DEX-Router-EVM-V1/src/unxswap.sol) in our repository.

---

## Guide 7: Uniswap V3 Optimized Swaps

### Introduction
This guide demonstrates how to use the `uniswapV3SwapTo` function for gas-efficient swaps through Uniswap V3 pools. This approach is optimized for concentrated liquidity pools and provides precise control over swap parameters.

### What You'll Build
A smart contract that executes gas-optimized V3 swaps using the `uniswapV3SwapTo` function with proper pool configuration and ETH handling.

### Key Features
- **V3 Optimization**: Optimized for Uniswap V3 concentrated liquidity
- **Gas Efficiency**: Lower gas consumption for V3 swaps
- **ETH Handling**: Seamless ETH/WETH conversion
- **Commission Integration**: Built-in referral system
- **Multi-hop Support**: Efficient multi-pool routing

### Implementation

**Step 1: V3 Swap Contract Setup**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interface/IDexRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SmartSwap {
    
    address internal constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    // V3 pool configuration masks
    uint256 internal constant _ONE_FOR_ZERO_MASK = 1 << 255;
    uint256 private constant _WETH_UNWRAP_MASK = 1 << 253;
    uint256 internal constant _ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    
    // Commission constants
    uint256 constant FROM_TOKEN_COMMISSION = 0x3ca20afc2aaa0000000000000000000000000000000000000000000000000000;
    uint256 constant TO_TOKEN_COMMISSION = 0x3ca20afc2bbb0000000000000000000000000000000000000000000000000000;
    uint256 constant FROM_TOKEN_COMMISSION_DUAL = 0x22220afc2aaa0000000000000000000000000000000000000000000000000000;
    uint256 constant TO_TOKEN_COMMISSION_DUAL = 0x22220afc2bbb0000000000000000000000000000000000000000000000000000;
    
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
        require(_rate1 < 10**9, "rate1 must be less than 10**9");
        require(_rate2 < 10**9, "rate2 must be less than 10**9");
        require(_rate1 + _rate2 < 0.03 * 10**9, "rate1 + rate2 must be less than 0.03");
        rate1 = _rate1;
        rate2 = _rate2;
    }
}
```

**Step 2: Implement V3 Swap Function**
```solidity
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
    require(receiver != address(0), "receiver cannot be zero address");
    
    // Step 1: Handle commission validation
    if (isFromTokenCommission) {
        uint256 amountTotal = amount * 10**9 / (10**9 - rate1 - rate2);
        if (msg.value > 0) {
            require(msg.value >= amountTotal, "msg.value < amountTotal");
        } else {
            require(IERC20(srcToken_).balanceOf(address(this)) >= amountTotal, "insufficient balance");
        }
    }
    
    // Step 2: Handle ETH address conversion
    srcToken_ = srcToken_ == address(0) ? _ETH : srcToken_;
    
    // Step 3: Encode source token with order ID
    uint256 srcToken = orderId << 160 | uint256(uint160(srcToken_));
    
    // Step 4: Build V3 pool configuration
    bytes32[] memory pools = new bytes32[](pools_.length);
    for (uint256 i = 0; i < pools_.length; i++) {
        uint256 poolAddress = uint256(uint160(pools_[i]));
        uint256 isReverse = zeroForOne[i] ? 0 : _ONE_FOR_ZERO_MASK;
        uint256 isReceiveEth = receiveEth ? _WETH_UNWRAP_MASK : 0;
        
        uint256 pool = poolAddress | isReverse | isReceiveEth;
        pools[i] = bytes32(pool);
    }
    
    // Step 5: Execute V3 swap
    bytes memory swapData = abi.encodeWithSelector(
        dexRouter.uniswapV3SwapTo.selector,
        receiver,
        amount,
        minReturn,
        pools
    );
    
    // Step 6: Execute with commission
    bytes memory data = bytes.concat(
        swapData,
        _getCommissionInfo(true, true, isFromTokenCommission, isFromTokenCommission ? srcToken_ : toToken)
    );
    
    (bool success, bytes memory result) = address(dexRouter).call(data);
    require(success, string(result));
    
    emit V3SwapExecuted(srcToken_, toToken, amount, minReturn, receiver);
}

event V3SwapExecuted(
    address indexed srcToken,
    address indexed toToken,
    uint256 amount,
    uint256 minReturn,
    address indexed receiver
);
```

**Step 3: Commission Handling Function**
```solidity
function _getCommissionInfo(
    bool _hasNextRefer,
    bool _isToB,
    bool _isFrom,
    address _token
) internal view returns (bytes memory data) {
    _token = _token == address(0) ? _ETH : _token;
    
    uint256 flag = _isFrom
        ? (_hasNextRefer ? FROM_TOKEN_COMMISSION_DUAL : FROM_TOKEN_COMMISSION)
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
    
    return _hasNextRefer
        ? abi.encode(last, middle, first)
        : abi.encode(middle, first);
}
```

**Step 4: Usage Example**
```solidity
// Deploy the V3 swap contract
SmartSwap v3Swap = new SmartSwap(
    dexRouterAddress,
    approveProxyAddress,
    0x000000000000000000000000000000000000dEaD, // refer1
    0x000000000000000000000000000000000000bEEF, // refer2
    0.0001 * 10**9, // rate1 (0.01%)
    0.00002 * 10**9 // rate2 (0.002%)
);

// Execute V3 swap: ETH → USDC
address[] memory pools = new address[](1);
pools[0] = ethUsdcV3Pool; // V3 pool address

bool[] memory zeroForOne = new bool[](1);
zeroForOne[0] = true; // ETH is token0

v3Swap.performTokenSwap{value: 1 ether}(
    1,                    // orderId
    address(0),          // srcToken (ETH)
    1 ether,             // amount (1 ETH)
    2900 * 1e6,          // minReturn (2900 USDC)
    msg.sender,          // receiver
    pools,               // pools
    zeroForOne,          // zeroForOne
    false,               // receiveEth
    true,                // isFromTokenCommission
    usdcAddress          // toToken
);
```

### Expected Output
- Input: 1 ETH
- Output: ~2900 USDC (to user's wallet)
- Gas: ~130,000 gas units (V3 optimized)
- Commission: Automatic fee distribution to referrers

**Key Features Demonstrated:**
- Gas-optimized `uniswapV3SwapTo` function usage
- V3 pool configuration with proper masks
- ETH/WETH handling for V3 pools
- Commission handling for V3 swaps
- Multi-hop V3 routing support

**📁 Complete Example**: View the [complete UniswapV3Swap example](../../../examples/DEX-Router-EVM-V1/src/uniswapV3swap.sol) in our repository.

---

## Common Patterns and Best Practices

### 1. Choose the Right Swap Function

#### Exact Input Swaps (Standard)
**`smartSwapByOrderId`**: For regular swaps with commission handling
```solidity
// Best for: User-initiated swaps, dApp integrations with referral systems
// Use when: You want to swap exact input amount for maximum output
returnAmount = dexRouter.smartSwapByOrderId(
    orderId,
    baseRequest,
    batchesAmount,
    batches,
    extraData
);
```

**`smartSwapByInvest`**: For pre-funded scenarios
```solidity
// Best for: Pre-funded protocols, rebalancing, when tokens are already in router
// Use when: You want to swap exact input amount for maximum output
returnAmount = dexRouter.smartSwapByInvest(
    baseRequest,
    batchesAmount,
    batches,
    extraData,
    recipient
);
```

#### Exact Output Swaps
**`unxswapExactOutTo`**: For exact output swaps with cost control
```solidity
// Best for: Payment systems, DeFi protocols requiring exact amounts
// Use when: You need exact output amount with spending limits
consumedAmount = dexRouterExactOut.unxswapExactOutTo(
    srcToken,
    exactOutputAmount,
    maxInputAmount,
    receiver,
    pools
);
```

**`uniswapV3SwapExactOutTo`**: For V3 exact output swaps
```solidity
// Best for: V3 concentrated liquidity, multi-hop exact output
// Use when: You need exact output with V3 routing
consumedAmount = dexRouterExactOut.uniswapV3SwapExactOutTo(
    receiver,
    exactOutputAmount,
    maxInputAmount,
    pools
);
```

#### Gas-Efficient Swaps
**`unxswapTo`**: For gas-optimized V2-like pool swaps
```solidity
// Best for: High-frequency trading, gas-sensitive applications, V2-like pools
// Use when: You need maximum gas efficiency with Uniswap V2-style pools
returnAmount = dexRouter.unxswapTo(
    srcToken,
    amount,
    minReturn,
    receiver,
    pools
);
```

**`uniswapV3SwapTo`**: For gas-optimized V3 pool swaps
```solidity
// Best for: Concentrated liquidity pools, precise slippage control
// Use when: You need gas efficiency with Uniswap V3-style pools
returnAmount = dexRouter.uniswapV3SwapTo(
    receiver,
    amount,
    minReturn,
    pools
);
```

#### When to Use Each Type
- **Exact Input**: Trading scenarios, maximizing output, "sell all" operations
- **Exact Output**: Payment systems, DeFi protocols, "buy exact amount" operations
- **Smart Swap**: Full-featured swaps with adapter support, commission handling
- **Unxswap**: Gas-sensitive V2-like pool swaps, high-frequency trading, tax tokens
- **Uniswap V3**: Gas-efficient concentrated liquidity swaps, precise price ranges
- **Swap Wrap**: ETH/WETH wrapping and unwrapping operations
- **By Invest**: Pre-funded scenarios, rebalancing, contract-held tokens

### 2. Commission Configuration
Set up flexible commission rates in your constructor:
```solidity
constructor(
    address _dexRouter,
    address _tokenApprove,
    address _refer1,
    address _refer2,
    uint256 _rate1,
    uint256 _rate2
) {
    // Validate commission rates
    require(_rate1 < 10 ** 9, "rate1 must be less than 10**9");
    require(_rate2 < 10 ** 9, "rate2 must be less than 10**9");
    require(
        _rate1 + _rate2 < 0.03 * 10 ** 9,
        "rate1 + rate2 must be less than 0.03"
    );
    // Set commission parameters
    rate1 = _rate1;
    rate2 = _rate2;
    refer1 = _refer1;
    refer2 = _refer2;
}
```

### 3. Proper Raw Data Encoding
Always encode raw data correctly for adapters:
```solidity
// Format: reverse(1byte) + weight(11bytes) + poolAddress(20bytes)
rawData[0] = uint256(
    bytes32(abi.encodePacked(uint8(0x00), uint88(10000), poolAddress))
);
```

### 4. Low-Level Call Execution
For advanced commission handling, use low-level calls:
```solidity
bytes memory swapData = abi.encodeWithSelector(
    dexRouter.smartSwapByOrderId.selector,
    orderId,
    baseRequest,
    batchesAmount,
    batches,
    extraData
);

bytes memory data = bytes.concat(
    swapData,
    _getCommissionInfo(hasNextRefer, isToB, isFrom, token)
);

(bool success, bytes memory result) = address(dexRouter).call(data);
require(success, string(result));
```

### 5. Token Transfer Strategies
Choose the right transfer approach:
```solidity
// For regular swaps with approval
IERC20(token).safeApprove(tokenApprove, amount);

// For pre-funded swaps (direct transfer to router)
IERC20(token).safeTransferFrom(user, address(dexRouter), amount);
```

### 6. Slippage Protection
Always set appropriate minimum return amounts:
```solidity
uint256 minReturn = (expectedAmount * 9900) / 10000; // 1% slippage tolerance
```

### 7. DeadLine Management
Set reasonable deadLines to prevent stale transactions:
```solidity
uint256 deadLine = block.timestamp + 300; // 5 minutes
```

### 8. Error Handling
Implement proper error handling for failed swaps:
```solidity
try dexRouter.smartSwapByOrderId(...) returns (uint256 amount) {
    // Handle success
} catch Error(string memory reason) {
    // Handle error
}
```

## Next Steps

### Recommended Learning Path
1. **Start with Guide 1**: Master simple swaps with commission handling
2. **Practice Guide 2**: Add ETH support to your integration
3. **Advanced Guide 3**: Build pre-funded contract applications

### Advanced Topics
1. **Custom Routing Strategies**: Build your own routing algorithms
2. **Gas Optimization**: Optimize contracts for production use
3. **MEV Protection**: Implement front-running protection
4. **Cross-chain Integration**: Extend to multi-chain environments

### Production Considerations
- **Comprehensive Testing**: Set up test suites with fork testing
- **Security Audits**: Get your integration audited before mainnet
- **Monitoring**: Implement swap monitoring and alerting
- **Upgrade Patterns**: Design for contract upgradability

## Links and References

### Example Contracts
- **Guide 1**: [SmartSwap (smartswap.sol)](../../../examples/DEX-Router-EVM-V1/src/smartswap.sol) - Full-featured swap with adapter support
- **Guide 2**: [SwapWrap (swapWrap.sol)](../../../examples/DEX-Router-EVM-V1/src/swapWrap.sol) - ETH/WETH wrapping operations
- **Guide 3**: [SmartSwapByInvest (smartswapByInvest.sol)](../../../examples/DEX-Router-EVM-V1/src/smartswapByInvest.sol) - Pre-funded contract swaps
- **Guide 4**: [UnxSwapExactOutTo (unxswapExactOutTo.sol)](examples/DEX-Router-EVM-V1/src/unxswapExactOutTo.sol) - V2 exact output swaps
- **Guide 5**: [UniswapV3SwapExactOutTo (uniswapV3SwapExactOutTo.sol)](../../../examples/DEX-Router-EVM-V1/src/uniswapV3SwapExactOutTo.sol) - V3 exact output swaps
- **Guide 6**: [UnxSwap (unxswap.sol)](../../../examples/DEX-Router-EVM-V1/src/unxswap.sol) - Gas-efficient V2-style swaps
- **Guide 7**: [UniswapV3Swap (uniswapV3swap.sol)](../../../examples/DEX-Router-EVM-V1/src/uniswapV3swap.sol) - V3 optimized swaps

### Documentation
- [Technical Reference](technical-reference.md)
- [Smart Contract Security Best Practices](https://consensys.github.io/smart-contract-best-practices/)
- [OpenZeppelin SafeERC20](https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#SafeERC20)
- [Hardhat Documentation](https://hardhat.org/getting-started/)

