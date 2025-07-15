# DEX-Router-Solana Technical Reference

## Program Overview

The DEX-Router-Solana is a sophisticated smart contract system that provides DEX aggregation and optimal routing capabilities on the Solana blockchain. This document provides complete technical specifications for all exported instructions and data structures.

> **📝 Program-Generated Documentation**: This technical reference is generated from the Anchor IDL and source code. For the most up-to-date information, refer to the source contracts.

### Main Program
- **Name**: dex-solana
- **Program ID**: `6m2CDdhRgxpH4WjvdzxAYbGxwdGUz5MziiL5jek2kBma`
- **Anchor Version**: 0.31.1
- **Solana Version**: 1.18.20+

## Core Data Structures

### SwapArgs Structure
```rust
#[derive(AnchorSerialize, AnchorDeserialize, Clone)]
pub struct SwapArgs {
    pub amount_in: u64,              // Amount of input tokens
    pub expect_amount_out: u64,      // Expected output amount
    pub min_return: u64,             // Minimum acceptable return
    pub amounts: Vec<u64>,           // Split amounts for each route
    pub routes: Vec<Vec<Route>>,     // Routing paths for multi-hop swaps
}
```

### CommissionSwapArgs Structure
```rust
#[derive(AnchorSerialize, AnchorDeserialize, Clone)]
pub struct CommissionSwapArgs {
    pub amount_in: u64,              // Amount of input tokens
    pub expect_amount_out: u64,      // Expected output amount
    pub min_return: u64,             // Minimum acceptable return
    pub amounts: Vec<u64>,           // Split amounts for each route
    pub routes: Vec<Vec<Route>>,     // Routing paths
    pub commission_rate: u16,        // Commission rate in basis points
    pub trim_rate: u16,              // Trim rate for fee adjustments
}
```

### CommissionWrapUnwrapArgs Structure
```rust
#[derive(AnchorSerialize, AnchorDeserialize, Clone)]
pub struct CommissionWrapUnwrapArgs {
    pub amount_in: u64,              // Amount to wrap/unwrap
    pub commission_rate: u16,        // Commission rate in basis points
    pub is_unwrap: bool,             // Whether to unwrap (true) or wrap (false)
}
```

### BridgeToArgs Structure
```rust
#[derive(AnchorSerialize, AnchorDeserialize, Clone)]
pub struct BridgeToArgs {
    pub destination_chain: u16,      // Target blockchain ID
    pub recipient: Vec<u8>,          // Recipient address on target chain
    pub amount: u64,                 // Amount to bridge
}
```

### PlatformFeeWrapUnwrapArgs Structure
```rust
#[derive(AnchorSerialize, AnchorDeserialize, Clone)]
pub struct PlatformFeeWrapUnwrapArgs {
    pub amount_in: u64,              // Amount to wrap/unwrap
    pub commission_rate: u16,        // Commission rate in basis points
    pub platform_fee_rate: u16,     // Platform fee rate in basis points
    pub is_unwrap: bool,             // Whether to unwrap (true) or wrap (false)
}
```

### Route Structure
```rust
#[derive(AnchorSerialize, AnchorDeserialize, Clone)]
pub struct Route {
    pub dexes: Vec<Dex>,    // DEX protocol identifiers
    pub weights: Vec<u8>,   // Weight distribution (must sum to 100)
}
```

## DEX Protocol Enumeration

### Supported DEX Protocols
```rust
#[derive(AnchorSerialize, AnchorDeserialize, Copy, Clone, PartialEq, Eq, Debug)]
pub enum Dex {
    // Core AMM Protocols
    SplTokenSwap,           // 0
    StableSwap,             // 1
    Whirlpool,              // 2
    MeteoraDynamicpool,     // 3
    RaydiumSwap,            // 4
    RaydiumStableSwap,      // 5
    RaydiumClmmSwap,        // 6
    
    // Legacy Protocols
    AldrinExchangeV1,       // 7
    AldrinExchangeV2,       // 8
    LifinityV1,             // 9
    LifinityV2,             // 10
    
    // Advanced Protocols
    RaydiumClmmSwapV2,      // 11
    FluxBeam,               // 12
    MeteoraDlmm,            // 13
    RaydiumCpmmSwap,        // 14
    OpenBookV2,             // 15
    WhirlpoolV2,            // 16
    Phoenix,                // 17
    ObricV2,                // 18
    
    // Sanctum LST Protocols
    SanctumAddLiq,          // 19
    SanctumRemoveLiq,       // 20
    SanctumNonWsolSwap,     // 21
    SanctumWsolSwap,        // 22
    SanctumRouter,          // 26
    
    // Meme Token Platforms
    PumpfunBuy,             // 23
    PumpfunSell,            // 24
    PumpfunammBuy,          // 35
    PumpfunammSell,         // 36
    BoopfunBuy,             // 46
    BoopfunSell,            // 47
    
    // Stablecoin Protocols
    StabbleSwap,            // 25
    
    // Vault and Yield Protocols
    MeteoraVaultDeposit,    // 27
    MeteoraVaultWithdraw,   // 28
    MeteoraLst,             // 29
    
    // Additional Protocols
    Solfi,                  // 30
    QualiaSwap,             // 31
    Zerofi,                 // 32
    Virtuals,               // 33
    VertigoBuy,             // 34
    VertigoSell,            // 37
    
    // Perpetuals
    PerpetualsAddLiq,       // 38
    PerpetualsRemoveLiq,    // 39
    PerpetualsSwap,         // 40
    
    // Launchpads
    RaydiumLaunchpad,       // 41
    LetsBonkFun,            // 42
    
    // Additional DEXs
    Woofi,                  // 43
    MeteoraDbc,             // 44
    MeteoraDlmmSwap2,       // 45
    MeteoraDAMMV2,          // 48
    Gavel,                  // 49
    MeteoraDbc2,            // 50
    GooseFX,                // 51
    Dooar,                  // 52
    Numeraire,              // 53
    
    // Saber Wrapper
    SaberDecimalWrapperDeposit,    // 54
    SaberDecimalWrapperWithdraw,   // 55
    
    // Extended Protocols
    SarosDlmm,              // 56
    OneDexSwap,             // 57
}
```

## Public Instructions

### Basic Swap Instructions

#### `swap`
Executes a basic token swap with smart routing.

```rust
pub fn swap<'a>(
    ctx: Context<'_, '_, 'a, 'a, SwapAccounts<'a>>,
    data: SwapArgs,
    order_id: u64,
) -> Result<()>
```

**Parameters:**
- `ctx`: Anchor context containing all required accounts
- `data`: SwapArgs containing swap parameters
- `order_id`: Unique identifier for the swap transaction

**Accounts:**
- `payer`: Signer - Account paying for the transaction
- `source_token_account`: Mutable - Source token account to swap from
- `destination_token_account`: Mutable - Destination token account to receive tokens
- `source_mint`: Source token mint
- `destination_mint`: Destination token mint

#### `swap2`
Alternative swap function with identical functionality to `swap`.

```rust
pub fn swap2<'a>(
    ctx: Context<'_, '_, 'a, 'a, SwapAccounts<'a>>,
    data: SwapArgs,
    order_id: u64,
) -> Result<()>
```

### Commission-based Swap Instructions

#### `commission_spl_swap`
Executes an SPL token swap with commission collection.

```rust
pub fn commission_spl_swap<'a>(
    ctx: Context<'_, '_, 'a, 'a, CommissionSPLAccounts<'a>>,
    data: CommissionSwapArgs,
    order_id: u64,
) -> Result<()>
```

**Parameters:**
- `ctx`: Anchor context with commission-specific accounts
- `data`: CommissionSwapArgs containing swap and commission parameters
- `order_id`: Unique identifier for the swap transaction

**Accounts:**
- `payer`: Signer - Account paying for the transaction
- `source_token_account`: Mutable - Source token account
- `destination_token_account`: Mutable - Destination token account
- `source_mint`: Source token mint
- `destination_mint`: Destination token mint
- `commission_token_account`: Mutable - Account to receive commission
- `commission_recipient`: Commission recipient authority

#### `commission_spl_swap2`
Alternative commission SPL swap function with identical functionality.

```rust
pub fn commission_spl_swap2<'a>(
    ctx: Context<'_, '_, 'a, 'a, CommissionSPLAccounts<'a>>,
    data: CommissionSwapArgs,
    order_id: u64,
) -> Result<()>
```

#### `commission_sol_swap`
Executes a SOL/WSOL swap with commission collection.

```rust
pub fn commission_sol_swap<'a>(
    ctx: Context<'_, '_, 'a, 'a, CommissionSOLAccounts<'a>>,
    data: CommissionSwapArgs,
    order_id: u64,
) -> Result<()>
```

**Special Features:**
- Handles native SOL to WSOL conversion automatically
- Commission can be collected in SOL or WSOL
- Automatic unwrapping of WSOL to SOL when needed

#### `commission_sol_swap2`
Alternative commission SOL swap function with identical functionality.

```rust
pub fn commission_sol_swap2<'a>(
    ctx: Context<'_, '_, 'a, 'a, CommissionSOLAccounts<'a>>,
    data: CommissionSwapArgs,
    order_id: u64,
) -> Result<()>
```

#### `commission_wrap_unwrap`
Handles wrapping/unwrapping of SOL to WSOL with commission collection.

```rust
pub fn commission_wrap_unwrap<'a>(
    ctx: Context<'_, '_, 'a, 'a, CommissionWrapUnwrapAccounts<'a>>,
    data: CommissionWrapUnwrapArgs,
    order_id: u64,
) -> Result<()>
```

**Parameters:**
- `ctx`: Anchor context with wrap/unwrap accounts
- `data`: CommissionWrapUnwrapArgs containing wrap/unwrap parameters
- `order_id`: Unique identifier for the transaction

### Bridge and Cross-chain Instructions

#### `from_swap_log`
Executes a swap and logs bridge information for cross-chain operations.

```rust
pub fn from_swap_log<'a>(
    ctx: Context<'_, '_, 'a, 'a, FromSwapAccounts<'a>>,
    args: SwapArgs,
    bridge_to_args: BridgeToArgs,
    offset: u8,
    len: u8,
) -> Result<()>
```

**Parameters:**
- `ctx`: Anchor context for cross-chain swap
- `args`: SwapArgs containing swap parameters
- `bridge_to_args`: BridgeToArgs containing bridge destination information
- `offset`: Log offset for bridge data
- `len`: Length of bridge data

### Proxy Swap Instructions

#### `proxy_swap`
Executes a swap through the proxy system for enhanced routing.

```rust
pub fn proxy_swap<'a>(
    ctx: Context<'_, '_, 'a, 'a, ProxySwapAccounts<'a>>,
    data: SwapArgs,
    order_id: u64,
) -> Result<()>
```

#### `commission_sol_proxy_swap`
Executes a SOL proxy swap with commission collection.

```rust
pub fn commission_sol_proxy_swap<'a>(
    ctx: Context<'_, '_, 'a, 'a, CommissionSOLProxySwapAccounts<'a>>,
    data: SwapArgs,
    commission_rate: u16,
    commission_direction: bool,
    order_id: u64,
) -> Result<()>
```

**Parameters:**
- `data`: SwapArgs containing swap parameters
- `commission_rate`: Commission rate in basis points (max 10000)
- `commission_direction`: true for input-based, false for output-based commission
- `order_id`: Unique identifier for the swap transaction

#### `commission_spl_proxy_swap`
Executes an SPL proxy swap with commission collection.

```rust
pub fn commission_spl_proxy_swap<'a>(
    ctx: Context<'_, '_, 'a, 'a, CommissionSPLProxySwapAccounts<'a>>,
    data: SwapArgs,
    commission_rate: u16,
    commission_direction: bool,
    order_id: u64,
) -> Result<()>
```

#### `commission_sol_from_swap`
Executes a SOL swap with commission for cross-chain operations.

```rust
pub fn commission_sol_from_swap<'a>(
    ctx: Context<'_, '_, 'a, 'a, CommissionSOLFromSwapAccounts<'a>>,
    args: SwapArgs,
    commission_rate: u16,
    bridge_to_args: BridgeToArgs,
    offset: u8,
    len: u8,
) -> Result<()>
```

#### `commission_spl_from_swap`
Executes an SPL swap with commission for cross-chain operations.

```rust
pub fn commission_spl_from_swap<'a>(
    ctx: Context<'_, '_, 'a, 'a, CommissionSPLFromSwapAccounts<'a>>,
    args: SwapArgs,
    commission_rate: u16,
    bridge_to_args: BridgeToArgs,
    offset: u8,
    len: u8,
) -> Result<()>
```

### Platform Fee Instructions

#### `platform_fee_sol_proxy_swap`
Executes a SOL proxy swap with platform fee collection.

```rust
pub fn platform_fee_sol_proxy_swap<'a>(
    ctx: Context<'_, '_, 'a, 'a, CommissionSOLProxySwapAccounts<'a>>,
    args: SwapArgs,
    commission_info: u16,
    platform_fee_rate: u16,
    order_id: u64,
) -> Result<()>
```

**Parameters:**
- `args`: SwapArgs containing swap parameters
- `commission_info`: Combined commission rate and direction information
- `platform_fee_rate`: Platform fee rate in basis points
- `order_id`: Unique identifier for the swap transaction

#### `platform_fee_spl_proxy_swap`
Executes an SPL proxy swap with platform fee collection.

```rust
pub fn platform_fee_spl_proxy_swap<'a>(
    ctx: Context<'_, '_, 'a, 'a, CommissionSPLProxySwapAccounts<'a>>,
    args: SwapArgs,
    commission_info: u16,
    platform_fee_rate: u16,
    order_id: u64,
) -> Result<()>
```

#### `platform_fee_sol_wrap_unwrap`
Handles SOL wrap/unwrap with platform fee collection.

```rust
pub fn platform_fee_sol_wrap_unwrap<'a>(
    ctx: Context<'_, '_, 'a, 'a, PlatformFeeWrapUnwrapAccounts<'a>>,
    args: PlatformFeeWrapUnwrapArgs,
    order_id: u64,
) -> Result<()>
```

### Platform Fee V2 Instructions

#### `platform_fee_sol_proxy_swap_v2`
Enhanced SOL proxy swap with platform fee and trim rate support.

```rust
pub fn platform_fee_sol_proxy_swap_v2<'a>(
    ctx: Context<'_, '_, 'a, 'a, CommissionSOLProxySwapAccounts<'a>>,
    args: SwapArgs,
    commission_info: u32,
    platform_fee_rate: u32,
    trim_rate: u8,
    order_id: u64,
) -> Result<()>
```

**Parameters:**
- `commission_info`: 32-bit combined commission rate and direction
- `platform_fee_rate`: Platform fee rate (32-bit for higher precision)
- `trim_rate`: Trim rate for excess amount handling

#### `platform_fee_spl_proxy_swap_v2`
Enhanced SPL proxy swap with platform fee and trim rate support.

```rust
pub fn platform_fee_spl_proxy_swap_v2<'a>(
    ctx: Context<'_, '_, 'a, 'a, CommissionSPLProxySwapAccounts<'a>>,
    args: SwapArgs,
    commission_info: u32,
    platform_fee_rate: u32,
    trim_rate: u8,
    order_id: u64,
) -> Result<()>
```

#### `platform_fee_sol_wrap_unwrap_v2`
Enhanced SOL wrap/unwrap with platform fee and trim rate support.

```rust
pub fn platform_fee_sol_wrap_unwrap_v2<'a>(
    ctx: Context<'_, '_, 'a, 'a, PlatformFeeWrapUnwrapAccountsV2<'a>>,
    args: PlatformFeeWrapUnwrapArgsV2,
    order_id: u64,
) -> Result<()>
```

### US Platform Fee Instructions

#### `us_platform_fee_sol_proxy_swap`
US-compliant SOL proxy swap with platform fee collection.

```rust
pub fn us_platform_fee_sol_proxy_swap<'a>(
    ctx: Context<'_, '_, 'a, 'a, UsCommissionSOLProxySwapAccounts<'a>>,
    args: SwapArgs,
    commission_info: u32,
    platform_fee_rate: u32,
    trim_rate: u8,
    order_id: u64,
) -> Result<()>
```

#### `us_platform_fee_spl_proxy_swap`
US-compliant SPL proxy swap with platform fee collection.

```rust
pub fn us_platform_fee_spl_proxy_swap<'a>(
    ctx: Context<'_, '_, 'a, 'a, UsCommissionSPLProxySwapAccounts<'a>>,
    args: SwapArgs,
    commission_info: u32,
    platform_fee_rate: u32,
    trim_rate: u8,
    order_id: u64,
) -> Result<()>
```

#### `us_platform_fee_sol_wrap_unwrap`
US-compliant SOL wrap/unwrap with platform fee collection.

```rust
pub fn us_platform_fee_sol_wrap_unwrap<'a>(
    ctx: Context<'_, '_, 'a, 'a, UsPlatformFeeWrapUnwrapAccounts<'a>>,
    args: UsPlatformFeeWrapUnwrapArgs,
    order_id: u64,
) -> Result<()>
```

### V3 Swap Instructions

#### `swap_v3`
Latest version swap with enhanced fee management and platform fee support.

```rust
pub fn swap_v3<'a>(
    ctx: Context<'_, '_, 'a, 'a, CommissionProxySwapAccountsV3<'a>>,
    args: SwapArgs,
    commission_info: u32,
    platform_fee_rate: u16,
    order_id: u64,
) -> Result<()>
```

**Parameters:**
- `args`: SwapArgs containing swap parameters
- `commission_info`: 32-bit commission information (rate + direction)
- `platform_fee_rate`: Platform fee rate in basis points
- `order_id`: Unique identifier for the swap transaction

**Features:**
- Enhanced fee calculation algorithms
- Optimized gas usage
- Platform fee integration
- Better error handling

#### `swap_tob_v3`
V3 swap with Transfer-on-Behalf (TOB) functionality.

```rust
pub fn swap_tob_v3<'a>(
    ctx: Context<'_, '_, 'a, 'a, CommissionProxySwapAccountsV3<'a>>,
    args: SwapArgs,
    commission_info: u32,
    trim_rate: u8,
    platform_fee_rate: u16,
    order_id: u64,
) -> Result<()>
```

**Parameters:**
- `trim_rate`: Rate for handling excess amounts
- Additional parameters same as `swap_v3`

**Features:**
- Transfer-on-Behalf (TOB) capability
- Trim rate for excess amount handling
- Enhanced authority management
- Swap Authority (SA) integration

**TOB Functionality:**
- Allows transfers to be executed on behalf of users
- Uses Swap Authority (SA) for secure token transfers
- Supports both token and SOL transfers
- Automatic ATA (Associated Token Account) handling

## Global Configuration Instructions

#### `init_global_config`
Initializes the global configuration for the program.

```rust
pub fn init_global_config(
    ctx: Context<InitGlobalConfig>,
    trade_fee: u64,
) -> Result<()>
```

#### `set_admin`
Updates the program administrator.

```rust
pub fn set_admin(
    ctx: Context<UpdateGlobalConfig>,
    admin: Pubkey,
) -> Result<()>
```

#### `add_resolver`
Adds a new resolver to the system.

```rust
pub fn add_resolver(
    ctx: Context<UpdateGlobalConfig>,
    resolver: Pubkey,
) -> Result<()>
```

#### `remove_resolver`
Removes a resolver from the system.

```rust
pub fn remove_resolver(
    ctx: Context<UpdateGlobalConfig>,
    resolver: Pubkey,
) -> Result<()>
```

#### `set_trade_fee`
Updates the global trade fee.

```rust
pub fn set_trade_fee(
    ctx: Context<UpdateGlobalConfig>,
    trade_fee: u64,
) -> Result<()>
```

#### `pause`
Pauses all trading operations.

```rust
pub fn pause(ctx: Context<UpdateGlobalConfig>) -> Result<()>
```

#### `unpause`
Resumes all trading operations.

```rust
pub fn unpause(ctx: Context<UpdateGlobalConfig>) -> Result<()>
```

#### `set_fee_multiplier`
Sets the fee multiplier for dynamic fee calculation.

```rust
pub fn set_fee_multiplier(
    ctx: Context<UpdateGlobalConfig>,
    fee_multiplier: u8,
) -> Result<()>
```

## Limit Order Instructions

#### `place_order`
Places a new limit order in the system.

```rust
pub fn place_order(
    ctx: Context<PlaceOrder>,
    order_id: u64,
    making_amount: u64,
    expect_taking_amount: u64,
    min_return_amount: u64,
    deadline: u64,
    trade_fee: u64,
) -> Result<()>
```

**Parameters:**
- `order_id`: Unique identifier for the order
- `making_amount`: Amount being offered
- `expect_taking_amount`: Expected amount to receive
- `min_return_amount`: Minimum acceptable return
- `deadline`: Order expiration timestamp
- `trade_fee`: Fee for the trade

#### `update_order`
Updates an existing limit order.

```rust
pub fn update_order(
    ctx: Context<UpdateOrder>,
    order_id: u64,
    expect_taking_amount: u64,
    min_return_amount: u64,
    deadline: u64,
    increase_fee: u64,
) -> Result<()>
```

#### `cancel_order`
Cancels an existing limit order.

```rust
pub fn cancel_order(
    ctx: Context<CancelOrder>,
    order_id: u64,
    tips: u64,
) -> Result<()>
```

#### `fill_order_by_resolver`
Fills a limit order through a resolver.

```rust
pub fn fill_order_by_resolver<'a>(
    ctx: Context<'_, '_, 'a, 'a, FillOrder<'a>>,
    order_id: u64,
    tips: u64,
    args: SwapArgs,
) -> Result<()>
```

#### `commission_fill_order`
Fills a limit order with commission collection.

```rust
pub fn commission_fill_order<'a>(
    ctx: Context<'_, '_, 'a, 'a, CommissionFillOrder<'a>>,
    order_id: u64,
    tips: u64,
    args: SwapArgs,
    commission_info: u32,
) -> Result<()>
```

## Account Structures

### SwapAccounts
```rust
#[derive(Accounts)]
pub struct SwapAccounts<'info> {
    pub payer: Signer<'info>,
    
    #[account(
        mut,
        token::mint = source_mint,
        token::authority = payer,
    )]
    pub source_token_account: InterfaceAccount<'info, TokenAccount>,
    
    #[account(
        mut,
        token::mint = destination_mint,
    )]
    pub destination_token_account: InterfaceAccount<'info, TokenAccount>,
    
    pub source_mint: InterfaceAccount<'info, Mint>,
    pub destination_mint: InterfaceAccount<'info, Mint>,
}
```

### CommissionProxySwapAccountsV3
```rust
#[derive(Accounts)]
pub struct CommissionProxySwapAccountsV3<'info> {
    #[account(mut)]
    pub payer: Signer<'info>,

    #[account(
        mut,
        token::mint = source_mint,
        token::authority = payer,
    )]
    pub source_token_account: Box<InterfaceAccount<'info, TokenAccount>>,

    #[account(
        mut,
        token::mint = destination_mint,
    )]
    pub destination_token_account: Box<InterfaceAccount<'info, TokenAccount>>,

    pub source_mint: Box<InterfaceAccount<'info, Mint>>,
    pub destination_mint: Box<InterfaceAccount<'info, Mint>>,

    /// CHECK: commission account
    #[account(mut)]
    pub commission_account: Option<AccountInfo<'info>>,

    /// CHECK: platform fee account
    #[account(mut)]
    pub platform_fee_account: Option<AccountInfo<'info>>,

    /// CHECK: swap authority
    #[account(mut)]
    pub sa_authority: Option<UncheckedAccount<'info>>,

    #[account(mut)]
    pub source_token_sa: Option<UncheckedAccount<'info>>,

    #[account(mut)]
    pub destination_token_sa: Option<UncheckedAccount<'info>>,

    pub source_token_program: Option<Interface<'info, TokenInterface>>,
    pub destination_token_program: Option<Interface<'info, TokenInterface>>,
    pub associated_token_program: Option<Program<'info, AssociatedToken>>,
    pub system_program: Option<Program<'info, System>>,
}
```

### CommissionSPLAccounts
```rust
#[derive(Accounts)]
pub struct CommissionSPLAccounts<'info> {
    #[account(mut)]
    pub payer: Signer<'info>,
    
    #[account(
        mut,
        token::mint = source_mint,
        token::authority = payer,
    )]
    pub source_token_account: InterfaceAccount<'info, TokenAccount>,
    
    #[account(
        mut,
        token::mint = destination_mint,
    )]
    pub destination_token_account: InterfaceAccount<'info, TokenAccount>,
    
    pub source_mint: InterfaceAccount<'info, Mint>,
    pub destination_mint: InterfaceAccount<'info, Mint>,
    
    #[account(mut)]
    pub commission_token_account: InterfaceAccount<'info, TokenAccount>,
    
    pub commission_recipient: Signer<'info>,
}
```

### CommissionSOLAccounts
```rust
#[derive(Accounts)]
pub struct CommissionSOLAccounts<'info> {
    #[account(mut)]
    pub payer: Signer<'info>,
    
    #[account(mut)]
    pub source_token_account: InterfaceAccount<'info, TokenAccount>,
    
    #[account(
        mut,
        token::mint = destination_mint,
    )]
    pub destination_token_account: InterfaceAccount<'info, TokenAccount>,
    
    pub source_mint: InterfaceAccount<'info, Mint>,
    pub destination_mint: InterfaceAccount<'info, Mint>,
    
    #[account(mut)]
    pub commission_token_account: InterfaceAccount<'info, TokenAccount>,
    
    pub commission_recipient: Signer<'info>,
    
    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
}
```

## State Management

### Position Structure
```rust
#[account(zero_copy(unsafe))]
#[derive(Debug)]
pub struct Position {
    pub position_id: u64,
    pub owner: Pubkey,
    pub base_token_vault: Pubkey,
    pub quote_token_vault: Pubkey,
    pub base_token_mint: Pubkey,
    pub quote_token_mint: Pubkey,
    pub base_token_program: Pubkey,
    pub quote_token_program: Pubkey,
    pub total_base_amount: u64,
    pub remain_base_amount: u64,
    pub total_quote_amount: u64,
    pub remain_quote_amount: u64,
    pub entry_price: u64,
    pub entry_ts: i64,
    pub update_ts: i64,
    pub bump: u8,
    pub strategy_hashes: StrategyHashes,
    pub padding: [u8; 256],
}
```

### OrderV1 Structure
```rust
#[account]
#[derive(Debug)]
pub struct OrderV1 {
    pub bump: u8,
    pub order_id: u64,
    pub maker: Pubkey,
    pub making_amount: u64,
    pub expect_taking_amount: u64,
    pub min_return_amount: u64,
    pub escrow_token_account: Pubkey,
    pub input_token_mint: Pubkey,
    pub output_token_mint: Pubkey,
    pub input_token_program: Pubkey,
    pub output_token_program: Pubkey,
    pub create_ts: u64,
    pub deadline: u64,
    pub padding: [u8; 128],
}
```

### Global Configuration
```rust
#[account(zero_copy(unsafe))]
#[derive(Debug)]
pub struct GlobalConfig {
    pub bump: u8,
    pub admin: Pubkey,
    pub resolvers: [Pubkey; 5],
    pub trade_fee: u64,
    pub paused: bool,
    pub fee_multiplier: u8,
    pub padding: [u8; 127],
}
```

## Events and Logging

### SwapEvent
```rust
#[event]
#[derive(Debug)]
pub struct SwapEvent {
    pub dex: Dex,
    pub amount_in: u64,
    pub amount_out: u64,
}
```

### OrderEvent
```rust
#[event]
#[derive(Debug)]
pub struct OrderEvent {
    pub order_id: u64,
    pub maker: Pubkey,
    pub input_mint: Pubkey,
    pub output_mint: Pubkey,
    pub amount_in: u64,
    pub amount_out: u64,
}
```

## Error Codes

### Common Errors
```rust
#[error_code]
pub enum ErrorCode {
    #[msg("Too many hops")]
    TooManyHops,                              // 6000
    
    #[msg("Min return not reached")]
    MinReturnNotReached,                      // 6001
    
    #[msg("amount_in must be greater than 0")]
    AmountInMustBeGreaterThanZero,           // 6002
    
    #[msg("min_return must be greater than 0")]
    MinReturnMustBeGreaterThanZero,          // 6003
    
    #[msg("invalid expect amount out")]
    InvalidExpectAmountOut,                   // 6004
    
    #[msg("amounts and routes must have the same length")]
    AmountsAndRoutesMustHaveTheSameLength,   // 6005
    
    #[msg("total_amounts must be equal to amount_in")]
    TotalAmountsMustBeEqualToAmountIn,       // 6006
    
    #[msg("dexes and weights must have the same length")]
    DexesAndWeightsMustHaveTheSameLength,    // 6007
    
    #[msg("weights must sum to 100")]
    WeightsMustSumTo100,                     // 6008
    
    #[msg("Invalid commission rate")]
    InvalidCommissionRate,                    // 6009
    
    #[msg("Invalid platform fee rate")]
    InvalidPlatformFeeRate,                   // 6010
    
    #[msg("Invalid trim rate")]
    InvalidTrimRate,                          // 6011
    
    #[msg("Invalid commission token account")]
    InvalidCommissionTokenAccount,            // 6012
    
    #[msg("Invalid platform fee account")]
    InvalidPlatformFeeAccount,                // 6013
    
    #[msg("Invalid trim account")]
    InvalidTrimAccount,                       // 6014
    
    #[msg("Invalid SA authority")]
    InvalidSaAuthority,                       // 6015
    
    #[msg("Invalid source token SA")]
    InvalidSourceTokenSa,                     // 6016
    
    #[msg("Invalid destination token SA")]
    InvalidDestinationTokenSa,                // 6017
    
    #[msg("Source token program is none")]
    SourceTokenProgramIsNone,                 // 6018
    
    #[msg("Destination token program is none")]
    DestinationTokenProgramIsNone,            // 6019
    
    #[msg("Invalid fee token account")]
    InvalidFeeTokenAccount,                   // 6020
    
    #[msg("Invalid platform fee amount")]
    InvalidPlatformFeeAmount,                 // 6021
    
    #[msg("Calculation error")]
    CalculationError,                         // 6022
}
```

## Constants and Configuration

### Program Constants
```rust
pub const MAX_HOPS: usize = 20;
pub const TOTAL_WEIGHT: u8 = 100;
pub const SEED_SA: &[u8] = b"swap_authority";
pub const BUMP_SA: u8 = 255;
pub const SA_AUTHORITY_SEED: &[&[u8]] = &[&[SEED_SA, &[BUMP_SA]]];
```

### Commission Configuration
```rust
pub const COMMISSION_RATE_LIMIT_V2: u32 = 100_000;        // 10%
pub const COMMISSION_DENOMINATOR_V2: u32 = 1_000_000;     // 100%
pub const PLATFORM_FEE_RATE_LIMIT_V3: u64 = 100_000;      // 10%
pub const PLATFORM_FEE_DENOMINATOR_V3: u64 = 1_000_000;   // 100%
pub const TRIM_RATE_LIMIT_V2: u8 = 100;                   // 10%
pub const TRIM_DENOMINATOR_V2: u8 = 1_000;                // 100%
```

### Fee Structures

#### Commission Calculation
- **Input-based Commission**: `commission = amount_in * rate / (denominator - rate)`
- **Output-based Commission**: `commission = amount_out * rate / denominator`

#### Platform Fee Calculation
- **Platform Fee**: `platform_fee = commission * platform_fee_rate / platform_fee_denominator`
- **Net Commission**: `net_commission = commission - platform_fee`

#### Trim Calculation
- **Trim Limit**: `trim_limit = amount_out * trim_rate / trim_denominator`
- **Trim Amount**: `min(actual_excess, trim_limit)`

### Compute Unit Budgets
```rust
pub const SWAP_COMPUTE_BUDGET: u32 = 200_000;
pub const COMMISSION_SWAP_COMPUTE_BUDGET: u32 = 250_000;
pub const MULTI_HOP_COMPUTE_BUDGET: u32 = 400_000;
pub const V3_SWAP_COMPUTE_BUDGET: u32 = 300_000;
```

## Advanced Features

### Transfer-on-Behalf (TOB)
TOB functionality allows the program to execute transfers on behalf of users through the Swap Authority (SA):

- **SA Authority**: A program-derived address that can authorize token transfers
- **Token Handling**: Automatically handles both SPL tokens and native SOL
- **ATA Support**: Seamlessly works with Associated Token Accounts
- **Security**: Uses program-controlled seeds for secure authorization

### Trim Rate Mechanism
The trim rate mechanism handles excess amounts from swaps:

- **Purpose**: Captures value when actual output exceeds expected output
- **Calculation**: Limited by configurable trim rate percentage
- **Distribution**: Excess amounts can be distributed to specified accounts
- **Fairness**: Ensures users receive at least their expected amount

### Multi-hop Routing
Advanced routing capabilities for complex swaps:

- **Route Optimization**: Automatically finds optimal paths across multiple DEXs
- **Weight Distribution**: Splits trades across multiple routes for better execution
- **Hop Limits**: Configurable maximum number of hops per route
- **Gas Optimization**: Efficient execution of multi-step swaps

### Platform Fee Structure
Hierarchical fee structure supporting multiple fee recipients:

- **Commission**: Primary fee paid to integrators
- **Platform Fee**: Secondary fee collected from commission
- **Trim Fee**: Additional fee from excess swap amounts
- **Flexibility**: Configurable rates and recipients for each fee type

## Security Considerations

### Account Validation
- All accounts are validated for proper ownership and mint matching
- Token account authorities are verified
- Signer requirements are strictly enforced
- PDA (Program Derived Address) validation for secure operations

### Numerical Safety
- All arithmetic operations use safe math with overflow protection
- Precision is maintained for token operations with proper decimal handling
- Fee calculations include bounds checking
- Rate limits prevent excessive fees

### Access Control
- Commission recipients must be signers for accountability
- Swap authority PDA protects intermediate accounts
- Proper token program validation prevents unauthorized operations
- Admin-only functions for global configuration changes

### Rate Limiting
- Commission rates are capped at reasonable maximums
- Platform fee rates have upper bounds
- Trim rates are limited to prevent excessive captures
- Global pause functionality for emergency stops

## Integration Guide

### Basic Integration
1. **Simple Swap**: Use `swap` or `swap2` for basic token swaps
2. **Commission Integration**: Use `commission_spl_swap` or `commission_sol_swap` for fee collection
3. **Platform Integration**: Use `platform_fee_*` functions for platform-specific fee structures

### Advanced Integration
1. **V3 Integration**: Use `swap_v3` or `swap_tob_v3` for latest features
2. **Cross-chain**: Implement `from_swap_log` for bridge operations
3. **Limit Orders**: Integrate limit order functionality for advanced trading

### Best Practices
1. **Account Setup**: Ensure proper token account initialization
2. **Fee Configuration**: Set reasonable fee rates and validate recipients
3. **Error Handling**: Implement comprehensive error handling for all failure cases
4. **Gas Optimization**: Use appropriate compute budgets for complex operations
5. **Testing**: Thoroughly test all integration points with various scenarios

