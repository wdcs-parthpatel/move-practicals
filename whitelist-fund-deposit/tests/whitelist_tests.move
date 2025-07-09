#[test_only]
module contract_addr::whitelist_tests {
    use std::vector;
    use aptos_framework::account;
    use contract_addr::admin;
    use contract_addr::whitelist;
    const USER1: address = @0x123;
    const USER2: address = @0x456;
    
    #[test]
    fun test_init_whitelist() {
        let admin_account = account::create_account_for_test(@contract_addr);
        admin::init_admin(&admin_account);
        whitelist::init_whitelist(&admin_account);

        let resource_addr = whitelist::get_resource_address();
        assert!(resource_addr != @0x0, 0);

        let addresses = whitelist::get_whitelist_addresses();
        assert!(addresses.length() == 0, 1);
    }
    
    #[test]
    fun test_add_with_admin() {
        let admin_account = account::create_account_for_test(@contract_addr);
        admin::init_admin(&admin_account);
        whitelist::init_whitelist(&admin_account);

        let addresses = vector::empty<address>();
        addresses.push_back(USER1);
        addresses.push_back(USER2);

        whitelist::add(&admin_account, addresses);

        let whitelist_addresses = whitelist::get_whitelist_addresses();
        assert!(whitelist_addresses.length() == 2, 2);
        assert!(whitelist_addresses.contains(&USER1), 3);
        assert!(whitelist_addresses.contains(&USER2), 4);
    }

    #[test]
    #[expected_failure(abort_code = admin::ENOT_ADMIN)]
    fun test_add_with_non_admin() {
        let admin_account = account::create_account_for_test(@contract_addr);
        admin::init_admin(&admin_account);
        whitelist::init_whitelist(&admin_account);

        let non_admin_account = account::create_account_for_test(@0x789);

        let addresses = vector::empty<address>();
        addresses.push_back(USER1);

        whitelist::add(&non_admin_account, addresses);
    }

    #[test]
    fun test_remove_with_admin() {
        let admin_account = account::create_account_for_test(@contract_addr);
        admin::init_admin(&admin_account);
        whitelist::init_whitelist(&admin_account);

        let addresses = vector::empty<address>();
        addresses.push_back(USER1);
        addresses.push_back(USER2);
        whitelist::add(&admin_account, addresses);

        let remove_addresses = vector::empty<address>();
        remove_addresses.push_back(USER1);
        whitelist::remove(&admin_account, remove_addresses);

        let whitelist_addresses = whitelist::get_whitelist_addresses();
        assert!(whitelist_addresses.length() == 1, 5);
        assert!(!whitelist_addresses.contains(&USER1), 6);
        assert!(whitelist_addresses.contains(&USER2), 7);
    }

    #[test]
    #[expected_failure(abort_code = admin::ENOT_ADMIN)]
    fun test_remove_with_non_admin() {
        let admin_account = account::create_account_for_test(@contract_addr);
        admin::init_admin(&admin_account);
        whitelist::init_whitelist(&admin_account);

        let addresses = vector::empty<address>();
        addresses.push_back(USER1);
        whitelist::add(&admin_account, addresses);

        let non_admin_account = account::create_account_for_test(@0x789);

        whitelist::remove(&non_admin_account, addresses);
    }

    #[test]
    fun test_is_whitelisted() {
        let admin_account = account::create_account_for_test(@contract_addr);
        admin::init_admin(&admin_account);
        whitelist::init_whitelist(&admin_account);

        let addresses = vector::empty<address>();
        addresses.push_back(USER1);
        whitelist::add(&admin_account, addresses);

        whitelist::is_whitelisted(USER1);
    }
    
    #[test]
    #[expected_failure(abort_code = whitelist::ENOT_WHITELISTED)]
    fun test_is_not_whitelisted() {
        let admin_account = account::create_account_for_test(@contract_addr);
        admin::init_admin(&admin_account);
        whitelist::init_whitelist(&admin_account);

        whitelist::is_whitelisted(USER1);
    }
}
