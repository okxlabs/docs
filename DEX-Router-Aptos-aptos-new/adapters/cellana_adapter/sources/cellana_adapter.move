
module cellana_adapter::cellana_adapter {
    use aptos_framework::coin;
    use aptos_framework::fungible_asset::{Self, FungibleAsset, Metadata, MintRef, TransferRef, BurnRef};
    use aptos_framework::object::{Self, Object, object_address};
    use std::signer;
    
    use cellana::router;

    public fun swap<X,Y> (
        user: &signer,
        amount_in: u64,
        from_asset: Object<Metadata>,
        to_asset: Object<Metadata>,
        pool_type: u64,
        is_in_FA: bool,
        is_out_FA: bool
    ) {
        let amount_out_min: u64 = 0;
        let is_stable: bool = pool_type == 0;
        if ( is_in_FA ) {
            if ( is_out_FA ) {
                // Asset to asset swap
                router::swap_entry(user, amount_in, amount_out_min, from_asset, to_asset, is_stable, signer::address_of(user))
            } else {
                // Asset to coin swap
                router::swap_asset_for_coin_entry<Y>(user, amount_in, amount_out_min, from_asset, is_stable, signer::address_of(user))
            }
        } else {
            if ( is_out_FA ) {
                // Coin to asset swap
                router::swap_coin_for_asset_entry<X>(user, amount_in, amount_out_min, to_asset, is_stable, signer::address_of(user))
            } else {
                // Coin to coin swap
                router::swap_coin_for_coin_entry<X, Y>(user, amount_in, amount_out_min, is_stable, signer::address_of(user))
            }
        }
    }

}