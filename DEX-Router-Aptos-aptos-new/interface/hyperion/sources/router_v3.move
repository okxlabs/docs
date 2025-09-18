module dex_contract::router_v3 {

    use aptos_framework::object::{Object};
    use aptos_framework::fungible_asset::{Metadata};

    /////////////////////////////////////////////////// USERS /////////////////////////////////////////////////////////
    /// Swap an amount of fungible assets for another fungible asset. User can specifies the minimum amount they
    /// expect to receive. If the actual amount received is less than the minimum amount, the transaction will fail.
    public entry fun exact_input_swap_entry(
        _user: &signer,
        _fee_tier: u8,
        _amount_in: u64,
        _amount_out_min: u64,
        _sqrt_price_limit: u128,
        _from_token: Object<Metadata>,
        _to_token: Object<Metadata>,
        _recipient: address,
        _deadline: u64
    ) {
        abort(0);
    }

    /// Swap an amount of coins for fungible assets. User can specifies the minimum amount they expect to receive.
    public entry fun exact_input_coin_for_asset_entry<FromCoin>(
        _user: &signer,
        _fee_tier: u8,
        _amount_in: u64,
        _amount_out_min: u64,
        _sqrt_price_limit: u128,
        _to_token: Object<Metadata>,
        _recipient: address,
        _deadline: u64
    ) {
        abort(0);
    }

    /// Swap an amount of fungible assets for coins. User can specifies the minimum amount they expect to receive.
    public entry fun exact_input_asset_for_coin_entry<ToCoin>(
        _user: &signer,
        _fee_tier: u8,
        _amount_in: u64,
        _amount_out_min: u64,
        _sqrt_price_limit: u128,
        _from_token: Object<Metadata>,
        _recipient: address,
        _deadline: u64
    ) {
        abort(0);
    }

    /// Swap an amount of coins for another coin. User can specifies the minimum amount they expect to receive.
    public entry fun exact_input_coin_for_coin_entry<FromCoin, ToCoin>(
        _user: &signer,
        _fee_tier: u8,
        _amount_in: u64,
        _amount_out_min: u64,
        _sqrt_price_limit: u128,
        _recipient: address,
        _deadline: u64
    ) {
        abort(0);
    }

    public entry fun swap_batch_coin_entry<T>(
        _user: &signer,
        _lp_path: vector<address>,
        _from_token: Object<Metadata>,
        _to_token: Object<Metadata>,
        _amount_in: u64,
        _amount_out_min: u64,
        _recipient: address,
    ) {
        abort(0)
    }

    public entry fun swap_batch(
        _user: &signer,
        _lp_path: vector<address>,
        _from_token: Object<Metadata>,
        _to_token: Object<Metadata>,
        _amount_in: u64,
        _amount_out_min: u64,
        _recipient: address,
    ) {
        abort(0);
    }
}