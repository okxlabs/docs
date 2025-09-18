module dexrouter::router {

    // Friends
    friend dexrouter::aggregator;

    // library

    use dexrouter::proxy;

    use aptos_framework::coin;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object::Object;
    use aptos_framework::primary_fungible_store;
    use std::signer;

    use pontem_adapter::pontem_adapter;
    use pontem_adapter_v2::pontem_adapter_v2;
    use pancake_adapter::pancake_adapter;
    use cellana_adapter::cellana_adapter;
    use hyperion_adapter::hyperion_adapter;


    // DEX type
    const DEX_HIPPO: u8 = 1;
    const DEX_ECONIA: u8 = 2;
    const DEX_PONTEM: u8 = 3;
    const DEX_BASIQ: u8 = 4;
    const DEX_UNISWAP: u8 = 5;
    const DEX_ANIME: u8 = 6;
    const DEX_PANCAKE: u8 = 7;
    const DEX_PONTEM_V2: u8 = 8;
    const DEX_CELLANA: u8 = 9;
    const DEX_HYPERION: u8 = 10;

    // ERRORS
    const E_NORMAL: u64 = 0;
    const E_NOT_ADMIN:u64 = 1;
    const E_UNKNOWN_DEX: u64 = 3;
    const E_FA_NOT_SUPPORTED: u64 = 4;

    /**
        Add core logic when invoke adapter for different assets swapping
        By now, only the cellana dex could handle the FA type token,
        so the workflow for other dex remain the same
    */
    public (friend) fun swap<X, Y, E>(
        dex_type: u8,
        pool_type: u64,
        _is_x_to_y: bool,
        asset_object_in: Object<Metadata>,
        asset_object_out: Object<Metadata>,
        is_in_FA: bool,
        is_out_FA: bool
    ): u64 {
        let pda = proxy::get_pda_manager();
        proxy::pda_register_coins<X,Y>(&pda);

        let status: u64 = if (dex_type == DEX_PONTEM) {
            // Check FA flag for FA non-support dex
            assert!(!is_in_FA && !is_out_FA, E_FA_NOT_SUPPORTED);
            let x_in_amount = coin::balance<X>(signer::address_of(&pda));
            let x_in = coin::withdraw<X>(&pda, x_in_amount);
            let y_output = pontem_adapter::swap<X,Y,E>(pool_type, x_in);
            coin::deposit<Y>(signer::address_of(&pda), y_output);
            E_NORMAL
        } else if (dex_type == DEX_PONTEM_V2) {
            assert!(!is_in_FA && !is_out_FA, E_FA_NOT_SUPPORTED);
            let x_in_amount = coin::balance<X>(signer::address_of(&pda));
            let x_in = coin::withdraw<X>(&pda, x_in_amount);
            let y_output = pontem_adapter_v2::swap<X,Y,E>(pool_type, x_in);
            coin::deposit<Y>(signer::address_of(&pda), y_output);
            E_NORMAL
        } else if (dex_type == DEX_PANCAKE) {
            assert!(!is_in_FA && !is_out_FA, E_FA_NOT_SUPPORTED);
            let x_in_amount = coin::balance<X>(signer::address_of(&pda));
            // swap
            pancake_adapter::swap<X,Y>(&pda, x_in_amount, 0);
            E_NORMAL
        } else if(dex_type == DEX_CELLANA) {
            let x_in_amount: u64;
            if (is_in_FA) {
                x_in_amount = primary_fungible_store::balance(signer::address_of(&pda), asset_object_in);
            } else {
                x_in_amount = coin::balance<X>(signer::address_of(&pda));
            };

            cellana_adapter::swap<X,Y>(&pda, x_in_amount, asset_object_in, asset_object_out, pool_type, is_in_FA, is_out_FA);
            E_NORMAL
        } else if (dex_type == DEX_HYPERION) {
            let x_in_amount: u64;
            if (is_in_FA) {
                x_in_amount = primary_fungible_store::balance(signer::address_of(&pda), asset_object_in);
            } else {
                x_in_amount = coin::balance<X>(signer::address_of(&pda));
            };

            hyperion_adapter::swap<X,Y>(&pda, asset_object_in, asset_object_out, pool_type, x_in_amount, is_in_FA, is_out_FA);
            E_NORMAL
        }
        else {
            E_UNKNOWN_DEX
        };

        status
    }
}