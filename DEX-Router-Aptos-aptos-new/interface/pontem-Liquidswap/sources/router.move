
module pontem::router_v2 {
    use aptos_framework::coin::{Self, Coin};
    public fun swap_exact_coin_for_coin<X, Y, Curve>(
        coin_in: Coin<X>,
        _coin_out_min_val: u64,
    ): Coin<Y> {
        coin::destroy_zero(coin_in);
        coin::zero<Y>()
    }
}