module loyalty_token_addr::loyalty_token {
    use std::signer;
    use std::string;
    use aptos_std::table;
    use aptos_framework::coin;
    use aptos_framework::event;
    use aptos_framework::object::Self;
    use aptos_framework::timestamp;

    const E_NOT_ADMIN: u64 = 1;
    const E_TOKEN_EXIST: u64 = 2;
    const E_NO_TOKEN_EXIST: u64 = 3;
    const E_TOKEN_EXPIRED: u64 = 4;
    const E_NO_TOKEN_EXPIRED: u64 = 5;

    struct LoyaltyToken has store, drop {}

    struct Config has key {
        mint_cap: coin::MintCapability<LoyaltyToken>,
        burn_cap: coin::BurnCapability<LoyaltyToken>,
    }

    struct RewardRecord has key {
        record: table::Table<address, object::ExtendRef>,
    }

    struct Reward has key, drop {
        amount: u64,
        expiry_sec: u64,
    }

    #[event]
    struct MintTokenEvent has drop, store {
        to: address,
        amount: u64,
        expiry_sec: u64,
    }

    #[event]
    struct RedeemTokenEvent has drop, store {
        by: address,
        amount: u64,
    }

    #[event]
    struct BurnExpiredTokenEvent has drop, store {
        user: address,
        amount: u64,
    }

    fun init_module(admin: &signer) {
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<LoyaltyToken>(
            admin,
            string::utf8(b"LayaltyToken"),
            string::utf8(b"LTY"),
            6,
            true);
        coin::destroy_freeze_cap(freeze_cap);
        move_to(admin, Config {
            mint_cap,
            burn_cap,
        });
        move_to(admin, RewardRecord {
            record: table::new()
        });
    }

    fun is_admin(admin_addr: address) {
        assert!(admin_addr == @loyalty_token_addr && exists<Config>(@loyalty_token_addr), E_NOT_ADMIN);
    }

    public entry fun mint(
        admin: &signer,
        user: address,
        amount: u64,
        expiry_sec: u64
    ) acquires Config, RewardRecord {
        let admin_addr = signer::address_of(admin);
        is_admin(admin_addr);

        let config = borrow_global<Config>(@loyalty_token_addr);
        let reward_record = borrow_global_mut<RewardRecord>(@loyalty_token_addr);

        assert!(!reward_record.record.contains(user), E_TOKEN_EXIST);

        let reward_obj_ref = &object::create_object(user);
        let reward_obj_signer = &object::generate_signer(reward_obj_ref);
        let reward_obj_addr = object::address_from_constructor_ref(reward_obj_ref);
        let reward_obj_ext_ref = object::generate_extend_ref(reward_obj_ref);

        expiry_sec = timestamp::now_seconds() + expiry_sec;
        let reward = Reward { amount, expiry_sec };

        let minted = coin::mint<LoyaltyToken>(amount, &config.mint_cap);
        coin::deposit<LoyaltyToken>(reward_obj_addr, minted);

        move_to(reward_obj_signer, reward);
        reward_record.record.add(user, reward_obj_ext_ref);
        event::emit(MintTokenEvent { to: user, amount, expiry_sec });
    }

    public entry fun redeem(user: &signer) acquires RewardRecord, Reward {
        let user_addr = signer::address_of(user);
        let reward_record = borrow_global_mut<RewardRecord>(@loyalty_token_addr);

        assert!(reward_record.record.contains(user_addr), E_NO_TOKEN_EXIST);

        let reward_obj_ext_ref = reward_record.record.borrow(user_addr);
        let reward_obj_signer = object::generate_signer_for_extending(reward_obj_ext_ref);
        let reward_obj_addr = object::address_from_extend_ref(reward_obj_ext_ref);

        let expiry_sec = borrow_global<Reward>(reward_obj_addr).expiry_sec;
        let now = timestamp::now_seconds();

        assert!(expiry_sec >= now, E_TOKEN_EXPIRED);
        let reward = move_from<Reward>(reward_obj_addr);
        coin::transfer<LoyaltyToken>(&reward_obj_signer, user_addr, reward.amount);
        reward_record.record.remove(user_addr);
        event::emit(RedeemTokenEvent { by: user_addr, amount: reward.amount });
    }

    public entry fun burn_expired(admin: &signer, user: address) acquires Config, RewardRecord, Reward {
        let admin_addr = signer::address_of(admin);
        is_admin(admin_addr);

        let config = borrow_global<Config>(@loyalty_token_addr);
        let reward_record = borrow_global_mut<RewardRecord>(@loyalty_token_addr);

        assert!(reward_record.record.contains(user), E_NO_TOKEN_EXIST);

        let reward_obj_ext_ref = reward_record.record.borrow(user);
        let reward_obj_signer = object::generate_signer_for_extending(reward_obj_ext_ref);
        let reward_obj_addr = object::address_from_extend_ref(reward_obj_ext_ref);

        let expiry_sec = borrow_global<Reward>(reward_obj_addr).expiry_sec;
        let now = timestamp::now_seconds();

        assert!(expiry_sec < now, E_NO_TOKEN_EXPIRED);

        let reward = move_from<Reward>(reward_obj_addr);
        let coins = coin::withdraw<LoyaltyToken>(&reward_obj_signer, reward.amount);
        coin::burn(coins, &config.burn_cap);
        reward_record.record.remove(user);
        event::emit(BurnExpiredTokenEvent { user, amount: reward.amount });
    }

    #[view]
    public fun get_object_address(user: address): address acquires RewardRecord {
        let reward_record = borrow_global<RewardRecord>(@loyalty_token_addr);
        assert!(reward_record.record.contains(user), E_NO_TOKEN_EXIST);
        let reward_obj_ext_ref = reward_record.record.borrow(user);
        object::address_from_extend_ref(reward_obj_ext_ref)
    }

    #[view]
    public fun check_loyalty(user: address): (u64, u64) acquires RewardRecord, Reward {
        let reward_record = borrow_global<RewardRecord>(@loyalty_token_addr);
        assert!(reward_record.record.contains(user), E_NO_TOKEN_EXIST);
        let reward_obj_ext_ref = reward_record.record.borrow(user);
        let reward_obj_addr = object::address_from_extend_ref(reward_obj_ext_ref);
        let reward = borrow_global<Reward>(reward_obj_addr);
        (reward.amount, reward.expiry_sec)
    }

    #[view]
    public fun get_balance(user: address): u64 {
        coin::balance<LoyaltyToken>(user)
    }
}