/**
 * Configuration file for OKX DEX Aggregator test suite
 * Contains all constants and configuration values used across tests
 */

/** Main aggregator module configuration */
export const MODULE_ADDRESS = "0x3faf7a406a14b9cdeb842f9caf23826eb19cc78d11997298b7e0115b193be8a1";
export const MODULE_NAME = "aggregator";

/** 
 * DEX type identifiers used in routing
 * Each DEX has a unique numeric identifier for the aggregator contract
 */
export const DEX = {
    PONTEM: 3,
    PONTEM_V2: 8,
    PANCAKE: 7,
    CELLANA: 9,
    HYPERION: 10,
} as const;

/**
 * Common token type addresses on Aptos mainnet
 * These represent the Move module paths for standard coin types
 */
export const TOKENS = {
    APT: "0x1::aptos_coin::AptosCoin",
    USDC: "0x5e156f1207d0ebfa19a9eeff00d62a282278fb8719f4fab3a586a0a2c0fffbea::coin::T",
    USDT: "0xf22bede237a07e121b56d91a491eb7bcdfd1f5907926a9e58338f964a01b17fa::asset::USDT",
    USDT_HYPERION: "0x50788befc1107c0cc4473848a92e5c783c635866ce3c98de71d2eeb7d2a34f85::usdt_coin::USDTether",
    UPTOS: "0x4fbed3f8a3fd8a11081c8b6392152a8b0cb14d70d0414586f0c9b858fcd2d6a7::UPTOS::UPTOS",
} as const;

/**
 * Fungible Asset (FA) addresses for tokens that support the FA standard
 * These are object addresses, not Move module paths
 */
export const FA_ADDRESSES = {
    CELL: "0x2ebb2ccac5e027a87fa0e2e5f656a3a4238d6a48d93ec9b610d570fc0aa0df12",
    USDT_FA: "0x357b0b74bc833e95a115ad22604854d6b0fca151cecd94111770e5d6ffc9dc2b",
} as const;

/** Default curve type used for AMM pools */
export const DEFAULT_CURVE = "0x163df34fccbf003ce219d3f1d9e70d140b60622cb9dd47599c25fb2f797ba6e::curves::Uncorrelated";