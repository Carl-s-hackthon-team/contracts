module AGDEX::admin {
    use std::signer;
    use aptos_framework::account;

    struct AdminCap has key {}

    public fun grant_admin_cap(admin: &signer) {
        move_to(admin, AdminCap {});
    }

    public fun assert_admin(account: &signer) {
        assert!(exists<AdminCap>(signer::address_of(account)), 403);
    }
}