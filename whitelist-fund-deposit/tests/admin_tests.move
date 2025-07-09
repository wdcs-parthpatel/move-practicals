#[test_only]
module contract_addr::admin_tests {
    use std::signer;
    use aptos_framework::account;
    use contract_addr::admin;

    #[test (user = @0x12345)]
    fun test_signer_is_admin(user: signer) {
        let admin_account = account::create_account_for_test(@contract_addr);
        admin::init_admin(&admin_account);
        let user_addr = signer::address_of(&user);
        admin::is_admin(user_addr);
    }

    #[test(user = @0x1234)]
    #[expected_failure(abort_code = admin::ENOT_ADMIN)]
    fun test_signer_is_not_admin(user: signer) {
        let admin_account = account::create_account_for_test(@contract_addr);
        admin::init_admin(&admin_account);
        let user_addr = signer::address_of(&user);
        admin::is_admin(user_addr);
    }
}
