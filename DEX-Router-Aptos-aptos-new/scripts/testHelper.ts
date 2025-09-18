/**
 * Test helper utilities for OKX DEX Aggregator
 * Provides simplified functions for building and executing swap transactions
 */

import { BCS, TxnBuilderTypes, HexString } from "aptos";
import { generalTransaction } from "./util";
import { MODULE_ADDRESS, MODULE_NAME, FA_ADDRESSES, DEFAULT_CURVE } from "./config";

/**
 * Configuration interface for Fungible Asset (FA) tokens in multi-hop swaps
 * Allows precise control over which positions use FA vs Coin standards
 */
interface FAConfig {
    /** Whether the input token is a Fungible Asset */
    inputIsFA?: boolean;
    /** Whether the first intermediate token is a Fungible Asset */
    intermediate1IsFA?: boolean;
    /** Whether the second intermediate token is a Fungible Asset */
    intermediate2IsFA?: boolean;
    /** Whether the output token is a Fungible Asset */
    outputIsFA?: boolean;
    /** Object address for input FA token */
    inputFAAddress?: string;
    /** Object address for first intermediate FA token */
    intermediate1FAAddress?: string;
    /** Object address for second intermediate FA token */
    intermediate2FAAddress?: string;
    /** Object address for output FA token */
    outputFAAddress?: string;
}

/**
 * Builds serialized arguments for the aggregator swap function
 * Handles both traditional Coin and Fungible Asset (FA) token types
 * 
 * @param params - Swap parameters including amounts, routing, and FA configuration
 * @returns Array of serialized arguments ready for transaction submission
 */
export function buildSwapArgs(params: {
    /** Input amount in token's smallest unit */
    amountIn: number;
    /** Minimum acceptable output amount */
    minAmountOut: number;
    /** Array of DEX identifiers for routing */
    dexTypes: number[];
    /** Pool type identifiers for each DEX (defaults to 1) */
    poolTypes?: number[];
    /** Swap directions for each hop (defaults to true) */
    isXToY?: boolean[];
    /** FA configuration object */
    faConfig?: FAConfig;
}) {
    const {
        amountIn,
        minAmountOut,
        dexTypes,
        poolTypes = dexTypes.map(() => 1),
        isXToY = dexTypes.map(() => true),
        faConfig = {}
    } = params;

    // Extract FA configuration with sensible defaults
    const {
        inputIsFA = false,
        intermediate1IsFA = false,
        intermediate2IsFA = false,
        outputIsFA = false,
        inputFAAddress = FA_ADDRESSES.CELL,
        intermediate1FAAddress = FA_ADDRESSES.CELL,
        intermediate2FAAddress = FA_ADDRESSES.CELL,
        outputFAAddress = FA_ADDRESSES.CELL
    } = faConfig;

    // Build asset object addresses array (4 positions: input, intermediate1, intermediate2, output)
    const assetObjects = [
        inputFAAddress,
        intermediate1FAAddress,
        intermediate2FAAddress,
        outputFAAddress
    ];

    // Build FA flags array indicating which positions use FA standard
    const isFAFlags = [
        inputIsFA,
        intermediate1IsFA,
        intermediate2IsFA,
        outputIsFA
    ];

    return [
        BCS.bcsSerializeUint64(amountIn),
        BCS.bcsSerializeUint64(minAmountOut),
        BCS.serializeVectorWithFunc(dexTypes, "serializeU8"),
        BCS.serializeVectorWithFunc(poolTypes, "serializeU64"),
        BCS.serializeVectorWithFunc(isXToY, "serializeBool"),
        BCS.serializeVectorWithFunc(
            assetObjects.map(addr => new HexString(addr).toUint8Array()),
            "serializeFixedBytes"
        ),
        BCS.serializeVectorWithFunc(isFAFlags, "serializeBool")
    ];
}

/**
 * Creates a FA configuration object with sensible defaults
 * Provides backward compatibility and simplifies common use cases
 * 
 * @param options - Configuration options for FA token handling
 * @returns Complete FAConfig object with defaults filled in
 */
export function createFAConfig(options: {
    /** Whether input token is FA */
    inputIsFA?: boolean;
    /** Whether output token is FA */
    outputIsFA?: boolean;
    /** Whether first intermediate token is FA */
    intermediate1IsFA?: boolean;
    /** Whether second intermediate token is FA */
    intermediate2IsFA?: boolean;
    /** Default FA address to use for all FA positions */
    faAddress?: string;
    /** Specific FA address for input position */
    inputFAAddress?: string;
    /** Specific FA address for output position */
    outputFAAddress?: string;
    /** Specific FA address for first intermediate position */
    intermediate1FAAddress?: string;
    /** Specific FA address for second intermediate position */
    intermediate2FAAddress?: string;
}): FAConfig {
    const defaultFA = options.faAddress || FA_ADDRESSES.CELL;
    
    return {
        inputIsFA: options.inputIsFA,
        intermediate1IsFA: options.intermediate1IsFA,
        intermediate2IsFA: options.intermediate2IsFA,
        outputIsFA: options.outputIsFA,
        inputFAAddress: options.inputFAAddress || defaultFA,
        intermediate1FAAddress: options.intermediate1FAAddress || defaultFA,
        intermediate2FAAddress: options.intermediate2FAAddress || defaultFA,
        outputFAAddress: options.outputFAAddress || defaultFA
    };
}

/**
 * Builds type arguments for the aggregator swap function
 * Supports up to 3-hop swaps with proper type parameter ordering
 * 
 * @param inputToken - Move type string for input token
 * @param outputToken - Move type string for output token  
 * @param intermediateToken - Optional first intermediate token type
 * @param intermediate2Token - Optional second intermediate token type
 * @returns Array of TypeTag objects for transaction type parameters
 */
export function buildTypeArgs(
    inputToken: string,
    outputToken: string,
    intermediateToken?: string,
    intermediate2Token?: string
) {
    const typeArgs = [];
    
    // Token type parameters: X, Y, Z, M
    typeArgs.push(new TxnBuilderTypes.TypeTagStruct(
        TxnBuilderTypes.StructTag.fromString(inputToken)
    ));
    typeArgs.push(new TxnBuilderTypes.TypeTagStruct(
        TxnBuilderTypes.StructTag.fromString(intermediateToken || outputToken)
    ));
    typeArgs.push(new TxnBuilderTypes.TypeTagStruct(
        TxnBuilderTypes.StructTag.fromString(intermediate2Token || outputToken)
    ));
    typeArgs.push(new TxnBuilderTypes.TypeTagStruct(
        TxnBuilderTypes.StructTag.fromString(outputToken)
    ));
    
    // Curve type parameters: E1, E2, E3 (using default curve)
    for (let i = 0; i < 3; i++) {
        typeArgs.push(new TxnBuilderTypes.TypeTagStruct(
            TxnBuilderTypes.StructTag.fromString(DEFAULT_CURVE)
        ));
    }
    
    return typeArgs;
}

/**
 * Executes a swap transaction through the OKX DEX Aggregator
 * Builds the complete transaction payload and submits it to the network
 * 
 * @param sender - AptosAccount that will sign and send the transaction
 * @param inputToken - Move type string for the input token
 * @param outputToken - Move type string for the output token
 * @param swapParams - Swap configuration including amounts and routing
 * @param intermediateToken - Optional first intermediate token for multi-hop
 * @param intermediate2Token - Optional second intermediate token for 3-hop
 * @returns Transaction hash string on successful submission
 */
export async function executeSwap(
    sender: any,
    inputToken: string,
    outputToken: string,
    swapParams: Parameters<typeof buildSwapArgs>[0],
    intermediateToken?: string,
    intermediate2Token?: string
) {
    const typeArgs = buildTypeArgs(inputToken, outputToken, intermediateToken, intermediate2Token);
    const functionArgs = buildSwapArgs(swapParams);
    
    const payload = new TxnBuilderTypes.TransactionPayloadEntryFunction(
        TxnBuilderTypes.EntryFunction.natural(
            `${MODULE_ADDRESS}::${MODULE_NAME}`,
            "unxswap",
            typeArgs,
            functionArgs
        )
    );
    
    return await generalTransaction(sender, payload);
}
