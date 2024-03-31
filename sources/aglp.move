module AGDEX::AGLP {
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::coin::CoinStore;
    use aptos_framework::managed_coin;

    use AGDEX::admin;
    use AGDEX::market;

    struct AGLP  {}

    // fun init_module(sender: &signer) {
    //     assert!(has_admin_cap(account), 403);

    //    managed_coin::initialize<AGLP>(
    //         sender,
    //         b"AGDEX Liquitity Coin",
    //         b"AGLP",
    //         6,
    //         false,
    //     );
    //     managed_coin::register<AGLP>(account);


    //     create_market(
    //         coin::treasury_into_supply(treasury),
    //         rate::from_percent(5),
    //     );
    // }

}