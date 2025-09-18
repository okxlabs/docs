module pontem_adapter_v2::pontem_adapter_v2 {
    use aptos_framework::coin;

    use liquidswap_v05::router;

    public fun swap<X,Y,E>(
        _pool_type: u64, 
        x_in: coin::Coin<X>
    ): coin::Coin<Y> {
        router::swap_exact_coin_for_coin<X, Y, E>(x_in, 0)
    }

}