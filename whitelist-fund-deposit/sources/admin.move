module contract_addr::admin {
    use std::signer;

    const ENOT_ADMIN: u64 = 1;

    struct AdminConfig has key {
        admin_addr: address,
    }

    public fun init_admin(admin: &signer) {
        move_to(admin, AdminConfig {
            admin_addr: signer::address_of(admin),
        });
    }

    public fun is_admin(account: address) acquires AdminConfig {
        assert!(exists<AdminConfig>(@contract_addr) && borrow_global<AdminConfig>(@contract_addr).admin_addr == account, ENOT_ADMIN)
    }
}
