/**
 * Multi-hop swap tests for OKX DEX Aggregator
 * Tests complex routing scenarios across multiple DEX adapters
 */

import { executeSwap, createFAConfig } from "../testHelper";
import { TOKENS, DEX, FA_ADDRESSES } from "../config";
import { getUser } from "../util";

/**
 * Tests 2-hop swap: UPTOS -> APT -> CELL (FA)
 * Demonstrates multi-hop routing from Coin to Fungible Asset
 */
export async function testMultiHop_UPTOS_APT_CELL() {
    console.log("\n=== Multi-hop: UPTOS -> APT -> CELL ===");
    console.log("Route: UPTOS --(PontemV2)--> APT --(Cellana)--> CELL");
    
    const user = await getUser();
    
    try {
        const txHash = await executeSwap(
            user,
            TOKENS.UPTOS,
            TOKENS.APT,  // Output token type (FA also needs placeholder)
            {
                amountIn: 100000000000,   // 1000 UPTOS
                minAmountOut: 10000000,
                dexTypes: [DEX.PONTEM_V2, DEX.CELLANA],
                poolTypes: [1, 1],
                isXToY: [true, true],
                faConfig: createFAConfig({
                    outputIsFA: true,
                    outputFAAddress: FA_ADDRESSES.CELL
                })
            },
            TOKENS.APT  // Intermediate token
        );
        
        console.log("✅ Success:", txHash);
        console.log(`https://explorer.aptoslabs.com/txn/${txHash}?network=mainnet`);
    } catch (error) {
        console.error("❌ Failed:", error.message);
    }
}

/**
 * Tests complex FA -> Coin -> FA multi-hop swap
 * Demonstrates advanced routing between different Fungible Assets
 */
export async function testMultiHop_FA_to_FA() {
    console.log("\n=== Multi-hop: FA -> APT -> FA ===");
    console.log("Route: USDT_FA --(Hyperion)--> APT --(Cellana)--> CELL_FA");
    
    const user = await getUser();
    
    try {
        const txHash = await executeSwap(
            user,
            TOKENS.UPTOS,  // Input placeholder type
            TOKENS.UPTOS,  // Output placeholder type
            {
                amountIn: 10000,   // 0.01 FA USDT
                minAmountOut: 1000000,  // 0.01 CELL
                dexTypes: [DEX.HYPERION, DEX.CELLANA],
                poolTypes: [1, 1],
                isXToY: [false, true],  // First hop reversed, second hop normal
                faConfig: createFAConfig({
                    inputIsFA: true,
                    outputIsFA: true,
                    inputFAAddress: FA_ADDRESSES.USDT_FA,
                    outputFAAddress: FA_ADDRESSES.CELL
                })
            },
            TOKENS.APT  // Intermediate token
        );
        
        console.log("✅ Success:", txHash);
        console.log(`https://explorer.aptoslabs.com/txn/${txHash}?network=mainnet`);
    } catch (error) {
        console.error("❌ Failed:", error.message);
    }
}

/**
 * Runs all multi-hop swap tests sequentially
 * Executes comprehensive test suite for complex routing scenarios
 */
export async function runAllMultiHopTests() {
    // await testMultiHop_UPTOS_APT_CELL();
    await testMultiHop_FA_to_FA();
}

if (require.main === module) {
    runAllMultiHopTests().catch(console.error);
}
