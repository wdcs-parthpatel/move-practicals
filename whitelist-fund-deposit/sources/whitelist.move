module contract_addr::whitelist {
    use std::signer;
    use aptos_framework::account;
    use aptos_framework::event;

    use contract_addr::admin;

    const SEED_WHITELIST: vector<u8> = b"WHITELIST";

    const ENOT_WHITELISTED: u64 = 2;

    struct WhitelistConfig has key {
        signer_cap: account::SignerCapability
    }

    struct Whitelist has key {
        addresses: vector<address>,
    }

    #[event]
    struct WhitelistAddEvent has drop, store {
        user: address
    }

    #[event]
    struct WhitelistRemoveEvent has drop, store {
        user: address
    }

    public fun init_whitelist(admin: &signer) {
        let (whitelist_signer, whitelist_signer_cap) = account::create_resource_account(admin, SEED_WHITELIST);
        move_to(admin, WhitelistConfig { signer_cap: whitelist_signer_cap });
        move_to(&whitelist_signer, Whitelist { addresses: vector<address>[] });
    }

    public entry fun add(account: &signer, addresses: vector<address>) acquires Whitelist, WhitelistConfig {
        let acc_addr = signer::address_of(account);
        admin::is_admin(acc_addr);

        let resource_addr = get_resource_address();
        let whitelist_addresses = &mut borrow_global_mut<Whitelist>(resource_addr).addresses;
        let i = 0;
        while (i < addresses.length()) {
            let addr = addresses.borrow(i);
            if (!whitelist_addresses.contains(addr)) {
                whitelist_addresses.push_back(*addr);
                event::emit(WhitelistAddEvent { user: *addr });
            };
            i += 1;
        }
    }

    public entry fun remove(account: &signer, addresses: vector<address>) acquires Whitelist, WhitelistConfig {
        let acc_addr = signer::address_of(account);
        admin::is_admin(acc_addr);

        let resource_addr = get_resource_address();
        let whitelist_addresses = &mut borrow_global_mut<Whitelist>(resource_addr).addresses;
        let i = 0;
        while (i < addresses.length()) {
            let addr = addresses.borrow(i);
            if (whitelist_addresses.contains(addr)) {
                whitelist_addresses.remove_value(addr);
                event::emit(WhitelistRemoveEvent { user: *addr });
            };
            i += 1;
        }
    }

    public fun is_whitelisted(account: address) acquires WhitelistConfig, Whitelist {
        let whitelist_addresses = get_whitelist_addresses();
        assert!(whitelist_addresses.contains(&account), ENOT_WHITELISTED)
    }

    #[view]
    public fun get_resource_address(): address acquires WhitelistConfig {
        let config = borrow_global<WhitelistConfig>(@contract_addr);
        let signer = account::create_signer_with_capability(&config.signer_cap);
        signer::address_of(&signer)
    }

    #[view]
    public fun get_whitelist_addresses(): vector<address> acquires WhitelistConfig, Whitelist {
        let whitelist_resource_addr = get_resource_address();
        borrow_global<Whitelist>(whitelist_resource_addr).addresses
    }
}
