module dexrouter::aggregator {
    use aptos_framework::coin;
    use aptos_framework::timestamp;
    use aptos_framework::fungible_asset::Metadata;
    use aptos_framework::object::Object;
    use aptos_framework::primary_fungible_store;
    use aptos_framework::event;

    use aptos_std::type_info::{TypeInfo, type_of};
    use std::signer;
    use std::vector;

    use dexrouter::router;
    use dexrouter::proxy;

    // ERRORS
    // const E_UNKNOWN_POOL_TYPE: u64 = 1;          #delete-redundancy-variables
    const E_OUTPUT_LESS_THAN_MINIMUM: u64 = 2;
    const E_UNKNOWN_DEX: u64 = 3;
    const E_NOT_ADMIN: u64 = 4;
    const E_OUT_HOP: u64 = 5;
    const E_DEX_POOL_LENGTH_MISMATCH: u64 = 6;        // dex_types & pool_types length mismatch
    const E_POOL_DIRECTION_LENGTH_MISMATCH: u64 = 7;  // pool_types & is_x_to_y length mismatch
    const E_FAULT_OUT_AMOUNT: u64 = 8;
    const E_INVALID_ASSET_OBJECTS_LENGTH: u64 = 9;   
    const E_INVALID_FA_FLAGS_LENGTH: u64 = 10;        
    const E_INVALID_MIN_OUT: u64 = 11;

    //const
    const FA_INFO_LENGTH: u64 = 4;

    #[event]
    struct OrderRecord has drop, store {
        dex_type: u8,
        pool_type: u64,
        // input coin type
        x_type_info: TypeInfo,
        // output coin type
        y_type_info: TypeInfo,
        asset_object_in: Object<Metadata>,
        asset_object_out: Object<Metadata>,
        is_in_FA: bool,
        is_out_FA: bool,
        input_amount: u64,
        output_amount: u64,
        time_stamp: u64
    }

    fun emit_swap_hop_event<Input, Output>(
        dex_type: u8,
        pool_type: u64,
        asset_object_in: Object<Metadata>,
        asset_object_out: Object<Metadata>,
        is_in_FA: bool,
        is_out_FA: bool,
        input_amount: u64,
        output_amount: u64
    ) {
        event::emit(
            OrderRecord {
                dex_type,
                pool_type,
                x_type_info: type_of<coin::Coin<Input>>(),
                y_type_info: type_of<coin::Coin<Output>>(),
                asset_object_in,
                asset_object_out,
                is_in_FA,
                is_out_FA,
                input_amount,
                output_amount,
                time_stamp: timestamp::now_microseconds()
            }
        );
    }


    fun get_intermediate_output<X, Y, E>(
        dex_type: u8,
        pool_type: u64,
        is_x_to_y: bool,
        asset_object_in: Object<Metadata>,
        asset_object_out: Object<Metadata>,
        is_in_FA: bool,
        is_out_FA: bool
    ) {
        let pda = proxy::get_pda_manager();

        // originally, this function should not involve operation on coin/FA, but for emitting event, we did it.
        let in_amount: u64;
        
        // Add getAmountIn
        if (is_in_FA) {
            in_amount = primary_fungible_store::balance(signer::address_of(&pda), asset_object_in);
        } else {
            in_amount = coin::balance<X>(signer::address_of(&pda));
        };

        let swap_status = router::swap<X, Y, E>(dex_type, pool_type, is_x_to_y, asset_object_in, asset_object_out, is_in_FA, is_out_FA);
        if (swap_status == E_UNKNOWN_DEX) {
            abort E_UNKNOWN_DEX
        };

        let out_amount: u64;

        // Add getAmountOut
        if (is_out_FA) {
            out_amount = primary_fungible_store::balance(signer::address_of(&pda), asset_object_out);
        } else {
            out_amount = coin::balance<Y>(signer::address_of(&pda));
        };

        emit_swap_hop_event<X, Y>(
            dex_type,
            pool_type,
            asset_object_in,
            asset_object_out,
            is_in_FA,
            is_out_FA,
            in_amount,
            out_amount
        );

    }

    fun check_and_deposit<X>(sender: &signer, coin: coin::Coin<X>) {
        let sender_addr = signer::address_of(sender);
        if (!coin::is_account_registered<X>(sender_addr)) {
            coin::register<X>(sender);
        };
        coin::deposit(sender_addr, coin);
    }

    fun one_step_internal<X, Y, E>(
        dex_type: u8,
        pool_type: u64,
        is_x_to_y: bool,
        asset_object_in: Object<Metadata>,
        asset_object_out: Object<Metadata>,
        is_in_FA: bool,
        is_out_FA: bool
    ) {
        get_intermediate_output<X, Y, E>(dex_type, pool_type, is_x_to_y, asset_object_in, asset_object_out, is_in_FA, is_out_FA)
    }

    fun two_step_direct<X, Y, Z, E1, E2>(
        first_dex_type: u8,
        first_pool_type: u64,
        first_is_x_to_y: bool,  // first trade uses normal order
        second_dex_type: u8,
        second_pool_type: u64,
        second_is_x_to_y: bool, // second trade uses normal order
        first_asset_object: Object<Metadata>,
        second_asset_object: Object<Metadata>,
        third_asset_object: Object<Metadata>,
        first_is_FA: bool,
        second_is_FA: bool,
        third_is_FA: bool
    ) {
        get_intermediate_output<X, Y, E1>(first_dex_type, first_pool_type, first_is_x_to_y, first_asset_object, second_asset_object, first_is_FA, second_is_FA);
        get_intermediate_output<Y, Z, E2>(second_dex_type, second_pool_type, second_is_x_to_y, second_asset_object, third_asset_object, second_is_FA, third_is_FA);
    }

    fun three_step_direct<X, Y, Z, M, E1, E2, E3>(
        first_dex_type: u8,
        first_pool_type: u64,
        first_is_x_to_y: bool,  // first trade uses normal order
        second_dex_type: u8,
        second_pool_type: u64,
        second_is_x_to_y: bool, // second trade uses normal order
        third_dex_type: u8,
        third_pool_type: u64,
        third_is_x_to_y: bool,  // third trade uses normal order
        first_asset_object: Object<Metadata>,
        second_asset_object: Object<Metadata>,
        third_asset_object: Object<Metadata>,
        fourth_asset_object: Object<Metadata>,
        first_is_FA: bool,
        second_is_FA: bool,
        third_is_FA: bool,
        fourth_is_FA: bool,
    ) {
        get_intermediate_output<X, Y, E1>(first_dex_type, first_pool_type, first_is_x_to_y, first_asset_object, second_asset_object, first_is_FA, second_is_FA);
        get_intermediate_output<Y, Z, E2>(second_dex_type, second_pool_type, second_is_x_to_y, second_asset_object, third_asset_object, second_is_FA, third_is_FA);
        get_intermediate_output<Z, M, E3>(third_dex_type, third_pool_type, third_is_x_to_y, third_asset_object, fourth_asset_object, third_is_FA, fourth_is_FA);
    }

    fun public_unxswap<X, Y, Z, M, E1, E2, E3>(
        dex_types: vector<u8>,
        pool_types: vector<u64>,
        is_x_to_y: vector<bool>,
        asset_objects: vector<Object<Metadata>>,
        is_FA: vector<bool>
    ) {
        // Add necessary params extraction from vector
        if (vector::length(&dex_types) == 1) {
            let dex_type_0 = *vector::borrow(&dex_types, 0);
            let pool_type_0 = *vector::borrow(&pool_types, 0);
            let is_x_to_y_0 = *vector::borrow(&is_x_to_y, 0);
            let asset_object_0 = *vector::borrow(&asset_objects, 0);
            let asset_object_3 = *vector::borrow(&asset_objects, 3);
            let is_FA_0 = *vector::borrow(&is_FA, 0);
            let is_FA_3 = *vector::borrow(&is_FA, 3);
            one_step_internal<X, M, E1>(
                dex_type_0,
                pool_type_0, 
                is_x_to_y_0,
                asset_object_0,
                asset_object_3,
                is_FA_0,
                is_FA_3
            );

        }
        else if (vector::length(&dex_types) == 2) {
            let dex_type_0 = *vector::borrow(&dex_types, 0);
            let pool_type_0 = *vector::borrow(&pool_types, 0);
            let is_x_to_y_0 = *vector::borrow(&is_x_to_y, 0);
            let asset_object_0 = *vector::borrow(&asset_objects, 0);
            let is_FA_0 = *vector::borrow(&is_FA, 0);
            let dex_type_1 = *vector::borrow(&dex_types, 1);
            let pool_type_1 = *vector::borrow(&pool_types, 1);
            let is_x_to_y_1 = *vector::borrow(&is_x_to_y, 1);
            let asset_object_1 = *vector::borrow(&asset_objects, 1);
            let is_FA_1 = *vector::borrow(&is_FA, 1);
            let asset_object_3 = *vector::borrow(&asset_objects, 3);
            let is_FA_3 = *vector::borrow(&is_FA, 3);

            two_step_direct<X, Y, M, E1, E2>(
                dex_type_0,
                pool_type_0,
                is_x_to_y_0,
                dex_type_1,
                pool_type_1,
                is_x_to_y_1,
                asset_object_0,
                asset_object_1,
                asset_object_3,
                is_FA_0,
                is_FA_1,
                is_FA_3
            );

        }
        else if (vector::length(&dex_types) == 3) {
            let dex_type_0 = *vector::borrow(&dex_types, 0);
            let pool_type_0 = *vector::borrow(&pool_types, 0);
            let is_x_to_y_0 = *vector::borrow(&is_x_to_y, 0);
            let asset_object_0 = *vector::borrow(&asset_objects, 0);
            let is_FA_0 = *vector::borrow(&is_FA, 0);
            let dex_type_1 = *vector::borrow(&dex_types, 1);
            let pool_type_1 = *vector::borrow(&pool_types, 1);
            let is_x_to_y_1 = *vector::borrow(&is_x_to_y, 1);
            let asset_object_1 = *vector::borrow(&asset_objects, 1);
            let is_FA_1 = *vector::borrow(&is_FA, 1);
            let dex_type_2 = *vector::borrow(&dex_types, 2);
            let pool_type_2 = *vector::borrow(&pool_types, 2);
            let is_x_to_y_2 = *vector::borrow(&is_x_to_y, 2);
            let asset_object_2 = *vector::borrow(&asset_objects, 2);
            let is_FA_2 = *vector::borrow(&is_FA, 2);
            let asset_object_3 = *vector::borrow(&asset_objects, 3);
            let is_FA_3 = *vector::borrow(&is_FA, 3);
            // swap
            three_step_direct<X, Y, Z, M, E1, E2, E3>(
                dex_type_0,
                pool_type_0,
                is_x_to_y_0,
                dex_type_1,
                pool_type_1,
                is_x_to_y_1,
                dex_type_2,
                pool_type_2,
                is_x_to_y_2,
                asset_object_0,
                asset_object_1,
                asset_object_2,
                asset_object_3,
                is_FA_0,
                is_FA_1,
                is_FA_2,
                is_FA_3
            );
        }
        else {
            abort E_OUT_HOP
        }
    }

    //   Main Function
    // Add asset_objects and is_FA to handle the token in Fungible asset format
    public entry fun unxswap<X, Y, Z, M, E1, E2, E3>(
        sender: &signer,
        x_in: u64,
        min_out: u64,
        dex_types: vector<u8>,
        pool_types: vector<u64>,
        is_x_to_y: vector<bool>,
        asset_objects: vector<Object<Metadata>>,
        is_FA: vector<bool>
    ) {
        // Ensure the consistency in lengths of DEX, pool types, and directional vectors
        assert!(vector::length(&dex_types) == vector::length(&pool_types), E_DEX_POOL_LENGTH_MISMATCH);
        assert!(vector::length(&pool_types) == vector::length(&is_x_to_y), E_POOL_DIRECTION_LENGTH_MISMATCH);
        assert!(vector::length(&dex_types) <= 3, E_OUT_HOP);
        // Confirm that the length of asset objects and fungible asset flags matches the predefined FA_INFO_LENGTH
        assert!(vector::length(&asset_objects) == FA_INFO_LENGTH, E_INVALID_ASSET_OBJECTS_LENGTH);
        assert!(vector::length(&is_FA) == FA_INFO_LENGTH, E_INVALID_FA_FLAGS_LENGTH);

        // To ensure the slippage check works well
        assert!(min_out > 0, E_INVALID_MIN_OUT);

        // get PDA
        let pda = proxy::get_pda_manager();
        // To see if fromToken is in FA format
        if (*vector::borrow(&is_FA, 0)) {
            // transfer user assets
            let asset_object_0 = *vector::borrow(&asset_objects, 0);

            let asset_x = primary_fungible_store::withdraw(sender, asset_object_0, x_in);
            primary_fungible_store::deposit(signer::address_of(&pda), asset_x);
        } else {
            proxy::pda_register_coins<X,X>(&pda);

            // transfer user assets
            let coin_x = coin::withdraw<X>(sender, x_in);
            coin::deposit<X>(signer::address_of(&pda), coin_x);
        };
        // core swap
        public_unxswap<X, Y, Z, M, E1, E2, E3>(dex_types, pool_types, is_x_to_y, asset_objects, is_FA);

        // check the slippage and transfer output to user
        // To see if toToken is in FA format
        if (*vector::borrow(&is_FA, 3)) {
            let asset_object_3 = *vector::borrow(&asset_objects, 3);

            let asset_y_amount = primary_fungible_store::balance(signer::address_of(&pda), asset_object_3);
            assert!(asset_y_amount >= min_out, E_OUTPUT_LESS_THAN_MINIMUM);

            let asset_y = primary_fungible_store::withdraw(&pda, asset_object_3, asset_y_amount);
            primary_fungible_store::deposit(signer::address_of(sender), asset_y);
        } else {
            let coin_y_amount = coin::balance<M>(signer::address_of(&pda));
            assert!(coin_y_amount >= min_out, E_OUTPUT_LESS_THAN_MINIMUM);

            let coin_y = coin::withdraw<M>(&pda, coin_y_amount);
            check_and_deposit(sender, coin_y);
        }
    }
}