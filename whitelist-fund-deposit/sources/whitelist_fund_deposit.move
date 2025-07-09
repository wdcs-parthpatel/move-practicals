module contract_addr::whitelist_fund_deposit {
    use contract_addr::admin;
    use contract_addr::deposit;
    use contract_addr::whitelist;

    fun init_module(admin: &signer) {
        admin::init_admin(admin);
        whitelist::init_whitelist(admin);
        deposit::init_deposit(admin);
    }
}