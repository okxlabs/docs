
/**
 * Utility functions for Aptos blockchain interactions
 * Provides core transaction handling and account management
 */

import { AptosClient, AptosAccount, FaucetClient, BCS, TxnBuilderTypes, HexString } from "aptos";
import dotenv from "dotenv";

dotenv.config();

/** Aptos mainnet RPC endpoint */
export const NODE_URL = "https://fullnode.mainnet.aptoslabs.com";

/** Global Aptos client instances */
export const client = new AptosClient(NODE_URL);

/**
 * Executes a general transaction on the Aptos blockchain
 * Handles the complete flow: generation, signing, submission, and confirmation
 * 
 * @param sender - The account that will sign and send the transaction
 * @param entryFunctionPayload - The transaction payload to execute
 * @returns Promise resolving to the transaction hash
 */
export async function generalTransaction(sender: AptosAccount, entryFunctionPayload: TxnBuilderTypes.TransactionPayload) {
    // Create a raw transaction out of the transaction payload
    const rawTxn = await client.generateRawTransaction(sender.address(), entryFunctionPayload);

    // Sign the raw transaction with sender's private key
    const bcsTxn = AptosClient.generateBCSTransaction(sender, rawTxn);

    // Submit the transaction to the network
    const transactionRes = await client.submitSignedBCSTransaction(bcsTxn);

    // Wait for the transaction to be confirmed
    await client.waitForTransaction(transactionRes.hash);
    return transactionRes.hash;
}

/**
 * Transfers APT tokens between two accounts
 * Uses the standard coin::transfer function from the Aptos framework
 * 
 * @param sender - Account sending the tokens
 * @param receiver - Account receiving the tokens  
 * @param amount - Amount to transfer in octas (1 APT = 100,000,000 octas)
 */
export async function transferToken(sender: AptosAccount, receiver: AptosAccount, amount: number) {
    // Define the APT coin type for the transfer function
    const token = new TxnBuilderTypes.TypeTagStruct(TxnBuilderTypes.StructTag.fromString("0x1::aptos_coin::AptosCoin"));
    
    const entryFunctionPayload = new TxnBuilderTypes.TransactionPayloadEntryFunction(
        TxnBuilderTypes.EntryFunction.natural(
            "0x1::coin",
            "transfer",
            [token],
            [BCS.bcsToBytes(TxnBuilderTypes.AccountAddress.fromHex(receiver.address())), BCS.bcsSerializeUint64(amount)],
        ),
    );

    await generalTransaction(sender, entryFunctionPayload);
} 

/**
 * Creates a test user account from environment variables
 * Reads the private key from PRIVATE_USER environment variable
 * 
 * @returns Promise resolving to an AptosAccount for testing
 * @throws Error if PRIVATE_USER environment variable is not set
 */
export async function getUser() {
    const hexString = process.env.PRIVATE_USER;
    if (!hexString) {
        throw new Error("PRIVATE_USER environment variable is required");
    }
    
    const hex = Uint8Array.from(Buffer.from(hexString, 'hex'));
    const account = new AptosAccount(hex);
    console.log("User account:", account.address().hex());
    return account;
}

/**
 * Creates a deployer account from environment variables
 * Reads the private key from PRIVATE_DEPLOYER environment variable
 * 
 * @returns Promise resolving to an AptosAccount for deployment
 * @throws Error if PRIVATE_DEPLOYER environment variable is not set
 */
export async function getDeployer() {
    const hexString = process.env.PRIVATE_DEPOLYER; // Note: keeping original typo for compatibility
    if (!hexString) {
        throw new Error("PRIVATE_DEPOLYER environment variable is required");
    }
    
    const hex = Uint8Array.from(Buffer.from(hexString, 'hex'));
    const deployer = new AptosAccount(hex);
    return deployer;
}
