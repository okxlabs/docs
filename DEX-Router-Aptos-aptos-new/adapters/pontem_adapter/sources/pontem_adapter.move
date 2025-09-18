module pontem_adapter::pontem_adapter {
    use aptos_framework::coin;

    use pontem::router_v2;

    public fun swap<X,Y,E>(
        _pool_type: u64, 
        x_in: coin::Coin<X>
    ): coin::Coin<Y> {
        router_v2::swap_exact_coin_for_coin<X, Y, E>(x_in, 0)
    }
}