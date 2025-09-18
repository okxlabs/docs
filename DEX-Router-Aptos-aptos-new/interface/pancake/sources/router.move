// 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::router::swap_exact_input (APT => USDC)

module pancake::router {
    public entry fun swap_exact_input<X, Y>(
        _sender: &signer,
        _x_in: u64,
        _y_min_out: u64,
    ) {
    }
}