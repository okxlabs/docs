// 0xc7efb4076dbe143cbcd98cfaaa929ecfc8f299203dfff63b95ccb6bfe19850fa::router::swap_exact_input (APT => USDC)

module pancake_adapter::pancake_adapter {
    use pancake::router;
    // Pool Type
    public fun swap<X,Y> (
        sender: &signer,
        x_in: u64,
        y_min_out: u64,
    ) {
        router::swap_exact_input<X,Y>(sender, x_in, y_min_out);
    }
}