module hyperion_adapter::hyperion_adapter {
    use std::string::utf8;

    use aptos_framework::signer;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object::Object;
    use aptos_framework::timestamp;

    use dex_contract::utils;
    use dex_contract::tick_math;
    use dex_contract::partnership;

    const ORDER_SOURCE: vector<u8> = b"OKX";

    public fun swap<X,Y> (
        user: &signer,
        from_asset: Object<Metadata>,
        to_asset: Object<Metadata>,
        pool_type: u64, // treat pool_type as the index of FEE_RATE_VEC
        amount_in: u64,
        is_in_FA: bool, // is input a Fungile Asset
        is_out_FA: bool // is output Fungile Asset
    ) {
        let recipient = signer::address_of(user);
        let deadline = timestamp::now_seconds() + 60;
        let sqrt_price_limit = if (utils::is_sorted(from_asset, to_asset)) {
            tick_math::min_sqrt_price()
        } else {
            tick_math::max_sqrt_price()
        };

        // fee_tier parameter is the index of FEE_RATE_VEC
        // const FEE_RATE_VEC: vector<u64> = vector[100, 500, 3000, 10000, 1000];
        if ( is_in_FA ) {
            if ( is_out_FA ) {
                // FA -> FA
                partnership::exact_input_swap_entry(
                    user,
                    pool_type as u8,
                    amount_in,
                    0,  // amount_out_min
                    sqrt_price_limit,
                    from_asset,
                    to_asset,
                    recipient,
                    // Reuested by the hyperion team for them to identify the order source
                    utf8(ORDER_SOURCE), 
                    deadline
                )
            } else {
                // FA -> coin
                partnership::exact_input_asset_for_coin_entry<Y>(
                    user,
                    pool_type as u8,
                    amount_in,
                    0,  // amount_out_min
                    sqrt_price_limit,
                    from_asset,
                    recipient,
                    // Reuested by the hyperion team for them to identify the order source
                    utf8(ORDER_SOURCE),
                    deadline
                )
            }
        } else {
            if ( is_out_FA ) {
                // coin -> FA
                partnership::exact_input_coin_for_asset_entry<X>(
                    user,
                    pool_type as u8,
                    amount_in,
                    0,  // amount_out_min
                    sqrt_price_limit,
                    to_asset,
                    recipient,
                    // Reuested by the hyperion team for them to identify the order source
                    utf8(ORDER_SOURCE),
                    deadline
                )
            } else {
                // coin -> coin
                partnership::exact_input_coin_for_coin_entry<X, Y>(
                    user,
                    pool_type as u8,
                    amount_in,
                    0,  // amount_out_min
                    sqrt_price_limit,
                    recipient,
                    // Reuested by the hyperion team for them to identify the order source
                    utf8(ORDER_SOURCE),
                    deadline
                )
            }
        }
    }
}