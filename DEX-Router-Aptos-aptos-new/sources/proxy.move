module dexrouter::proxy {
    use std::signer;
    use aptos_framework::account;
    use aptos_framework::coin;

    friend dexrouter::router;
    friend dexrouter::aggregator;

    const SEED: vector<u8> = b"okx.dex.escrow.account.5";

    struct ResourceAccount has key, store {
        signer_cap: account::SignerCapability,
    }

    public entry fun init(deployer: &signer) {
        let(_, resource_signer_cap) = account::create_resource_account(deployer, SEED);

        move_to(deployer, ResourceAccount {
            signer_cap: resource_signer_cap
        });
    }

    public (friend) fun get_pda_manager(): signer acquires ResourceAccount {
        let resourceAccount = borrow_global<ResourceAccount>(@deployer);
        let accountSigner = account::create_signer_with_capability(&(resourceAccount.signer_cap));
        accountSigner
    }

    public (friend) fun pda_register_coins<X,Y>(accountSigner: &signer) {
        // check pda is registered
        if (!coin::is_account_registered<X>(signer::address_of(accountSigner))) {
            coin::register<X>(accountSigner);
        };
        if (!coin::is_account_registered<Y>(signer::address_of(accountSigner))) {
            coin::register<Y>(accountSigner);
        };
    }
}