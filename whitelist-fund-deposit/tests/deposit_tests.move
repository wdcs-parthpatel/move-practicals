#[test_only]
module contract_addr::deposit_tests {
    use std::signer;
    use std::vector;
    use aptos_framework::account;
    use aptos_framework::aptos_coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;

    use contract_addr::admin;
    use contract_addr::deposit;
    use contract_addr::whitelist;

    const USER1: address = @0x123;
    const USER2: address = @0x456;
    const DEPOSIT_AMOUNT: u64 = 1000000;

    #[test (aptos_framework = @0x1)]
    public fun test_init_deposit(aptos_framework: signer) {
        let admin_account = account::create_account_for_test(@contract_addr);
        admin::init_admin(&admin_account);

        let (_burn_cap, _mint_cap) = aptos_coin::initialize_for_test(&aptos_framework);
        deposit::init_deposit(&admin_account);
        aptos_framework::coin::destroy_burn_cap(_burn_cap);
        aptos_framework::coin::destroy_mint_cap(_mint_cap);

        let resource_addr = deposit::get_resource_address();
        assert!(resource_addr != @0x0, 0);
    }

    #[test (aptos_framework = @0x1, user = @0x12)]
    public fun test_deposit_fund_with_whitelist(aptos_framework: signer, user: signer) {
        let admin_account = account::create_account_for_test(@contract_addr);
        admin::init_admin(&admin_account);

        whitelist::init_whitelist(&admin_account);

        let (_burn_cap, _mint_cap) = aptos_coin::initialize_for_test(&aptos_framework);
        deposit::init_deposit(&admin_account);
        aptos_framework::coin::destroy_burn_cap(_burn_cap);
        aptos_framework::coin::destroy_mint_cap(_mint_cap);

        let user_addr = signer::address_of(&user);
        let addresses = vector::empty<address>();
        addresses.push_back(user_addr);
        whitelist::add(&admin_account, addresses);

        account::create_account_for_test(user_addr);
        coin::register<AptosCoin>(&user);
        aptos_coin::mint(&aptos_framework, user_addr, 5);
        deposit::deposit_fund(&user, 3);

        assert!(coin::balance<AptosCoin>(deposit::get_resource_address()) == 3, 1);
        assert!(coin::balance<AptosCoin>(user_addr) == 2, 2);
    }

    #[test (aptos_framework = @0x1, user = @0x12)]
    #[expected_failure(abort_code = deposit::EINSUFFICIENT_FUND)]
    public fun test_deposit_fund_with_insufficement_fund(aptos_framework: signer, user: signer) {
        let admin_account = account::create_account_for_test(@contract_addr);
        admin::init_admin(&admin_account);

        whitelist::init_whitelist(&admin_account);

        let (_burn_cap, _mint_cap) = aptos_coin::initialize_for_test(&aptos_framework);
        deposit::init_deposit(&admin_account);
        aptos_framework::coin::destroy_burn_cap(_burn_cap);
        aptos_framework::coin::destroy_mint_cap(_mint_cap);

        let user_addr = signer::address_of(&user);
        let addresses = vector::empty<address>();
        addresses.push_back(user_addr);
        whitelist::add(&admin_account, addresses);

        account::create_account_for_test(user_addr);
        coin::register<AptosCoin>(&user);
        aptos_coin::mint(&aptos_framework, user_addr, 3);
        deposit::deposit_fund(&user, 5);
    }

    #[test (aptos_framework = @0x1, user = @0x12)]
    #[expected_failure(abort_code = whitelist::ENOT_WHITELISTED)]
    public fun test_deposit_fund_with_not_whitelist(aptos_framework: signer, user: signer) {
        let admin_account = account::create_account_for_test(@contract_addr);
        admin::init_admin(&admin_account);

        whitelist::init_whitelist(&admin_account);

        let (_burn_cap, _mint_cap) = aptos_coin::initialize_for_test(&aptos_framework);
        deposit::init_deposit(&admin_account);
        aptos_framework::coin::destroy_burn_cap(_burn_cap);
        aptos_framework::coin::destroy_mint_cap(_mint_cap);

        let user_addr = signer::address_of(&user);

        account::create_account_for_test(user_addr);
        coin::register<AptosCoin>(&user);
        aptos_coin::mint(&aptos_framework, user_addr, 5);
        deposit::deposit_fund(&user, 3);
    }

    #[test (aptos_framework = @0x1, user = @0x12345)]
    public fun test_withdraw_with_admin(aptos_framework: signer, user: signer) {
        let admin_account = account::create_account_for_test(@contract_addr);
        admin::init_admin(&admin_account);

        let (_burn_cap, _mint_cap) = aptos_coin::initialize_for_test(&aptos_framework);
        deposit::init_deposit(&admin_account);
        aptos_framework::coin::destroy_burn_cap(_burn_cap);
        aptos_framework::coin::destroy_mint_cap(_mint_cap);

        let user_addr = signer::address_of(&user);

        account::create_account_for_test(user_addr);
        coin::register<AptosCoin>(&user);

        aptos_coin::mint(&aptos_framework, deposit::get_resource_address(), 5);
        deposit::withdraw_fund(&user, 3);

        assert!(coin::balance<AptosCoin>(deposit::get_resource_address()) == 2, 3);
        assert!(coin::balance<AptosCoin>(user_addr) == 3, 4);
    }

    #[test (aptos_framework = @0x1, user = @0x123)]
    #[expected_failure(abort_code = admin::ENOT_ADMIN)]
    public fun test_withdraw_with_non_admin(aptos_framework: signer, user: signer) {
        let admin_account = account::create_account_for_test(@contract_addr);
        admin::init_admin(&admin_account);

        let (_burn_cap, _mint_cap) = aptos_coin::initialize_for_test(&aptos_framework);
        deposit::init_deposit(&admin_account);
        aptos_framework::coin::destroy_burn_cap(_burn_cap);
        aptos_framework::coin::destroy_mint_cap(_mint_cap);

        deposit::withdraw_fund(&user, 3);
    }

    #[test (aptos_framework = @0x1, user = @0x12345)]
    #[expected_failure(abort_code = deposit::EINSUFFICIENT_FUND)]
    public fun test_withdraw_with_insufficement_fund(aptos_framework: signer, user: signer) {
        let admin_account = account::create_account_for_test(@contract_addr);
        admin::init_admin(&admin_account);

        let (_burn_cap, _mint_cap) = aptos_coin::initialize_for_test(&aptos_framework);
        deposit::init_deposit(&admin_account);
        aptos_framework::coin::destroy_burn_cap(_burn_cap);
        aptos_framework::coin::destroy_mint_cap(_mint_cap);

        deposit::withdraw_fund(&user, 2);
    }
}
