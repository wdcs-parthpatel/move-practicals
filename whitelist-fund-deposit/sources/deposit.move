module contract_addr::deposit {
    use std::signer;
    use aptos_framework::account;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_framework::event;
    use contract_addr::whitelist;
    use contract_addr::admin;

    const SEED_DEPOSIT: vector<u8> = b"DEPOSITFUND";

    const EINSUFFICIENT_FUND: u64 = 3;

    struct DepositConfig has key {
        signer_cap: account::SignerCapability
    }

    #[event]
    struct FundAdded has drop, store {
        user: address,
        amount: u64,
    }

    #[event]
    struct FundWithdraw has drop, store {
        user: address,
        amount: u64,
    }

    public fun init_deposit(admin: &signer) {
        let (deposit_signer, deposit_signer_cap) = account::create_resource_account(admin, SEED_DEPOSIT);
        coin::register<AptosCoin>(&deposit_signer);
        move_to(admin, DepositConfig{signer_cap:deposit_signer_cap});
    }

    public entry fun deposit_fund(user: &signer, amount: u64) acquires DepositConfig {
        let user_addr = signer::address_of(user);
        whitelist::is_whitelisted(user_addr);

        let balance = coin::balance<AptosCoin>(user_addr);
        assert!(balance >= amount, EINSUFFICIENT_FUND);

        let coin = coin::withdraw<AptosCoin>(user, amount);
        let resource_addr = get_resource_address();
        coin::deposit(resource_addr, coin);

        event::emit(FundAdded{user: user_addr, amount});
    }

    public entry fun withdraw_fund(admin: &signer, amount: u64) acquires DepositConfig {
        let admin_addr = signer::address_of(admin);
        admin::is_admin(admin_addr);

        let resource_addr = get_resource_address();
        let balance = coin::balance<AptosCoin>(resource_addr);
        assert!(balance >= amount, EINSUFFICIENT_FUND);

        let deposit_signer = get_resource_signer();
        let coins = coin::withdraw<AptosCoin>(&deposit_signer, amount);
        coin::deposit_with_signer(admin, coins);

        event::emit(FundWithdraw{user: admin_addr, amount});
    }

    fun get_resource_signer(): signer acquires DepositConfig {
        let config = borrow_global<DepositConfig>(@contract_addr);
        let signer = account::create_signer_with_capability(&config.signer_cap);
        signer
    }

    #[view]
    public fun get_resource_address(): address acquires DepositConfig {
        let config = borrow_global<DepositConfig>(@contract_addr);
        let signer = account::create_signer_with_capability(&config.signer_cap);
        signer::address_of(&signer)
    }
}
