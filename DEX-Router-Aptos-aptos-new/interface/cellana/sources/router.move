
module cellana::router {

    use aptos_framework::coin;
    use aptos_framework::fungible_asset::{Self, FungibleAsset, Metadata, MintRef, TransferRef, BurnRef};
    use aptos_framework::object::{Self, Object, object_address};

    public entry fun swap_entry(
        _user: &signer,
        _amount_in: u64,
        _amount_out_min: u64,
        _from_token: Object<Metadata>,
        _to_token: Object<Metadata>,
        _is_stable: bool,
        _recipient: address,
    ) {
    }

    public entry fun swap_coin_for_asset_entry<FromCoin>(
        _user: &signer,
        _amount_in: u64,
        _amount_out_min: u64,
        _to_token: Object<Metadata>,
        _is_stable: bool,
        _recipient: address,
    ) {
    }

    public entry fun swap_asset_for_coin_entry<ToCoin>(
        _user: &signer,
        _amount_in: u64,
        _amount_out_min: u64,
        _from_token: Object<Metadata>,
        _is_stable: bool,
        _recipient: address,
    ) {
    }

    public entry fun swap_coin_for_coin_entry<FromCoin, ToCoin>(
        _user: &signer,
        _amount_in: u64,
        _amount_out_min: u64,
        _is_stable: bool,
        _recipient: address,
    ) {
    }

}