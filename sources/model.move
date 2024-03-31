module AGDEX::model {
    use aptos_framework::signer;
    use aptos_framework::account::Self;
    use aptos_framework::coin::{Self, Coin};

    use AGDEX::admin::{Self, AdminCap};
    use AGDEX::rate::{Self, Rate};
    use AGDEX::srate::{Self, SRate};
    use AGDEX::decimal::{Self, Decimal};
    use AGDEX::sdecimal::{Self, SDecimal};


    struct RebaseFeeModel has key, store {
      base: Rate,
      multiplier: Decimal,
    }

    struct ReservingFeeModel has key, store {
      multiplier: Decimal,
    }


    struct FundingFeeModel has key, store {
      max: Rate,
      multiplier: Decimal,
    }

    const SECONDS_PER_EIGHT_HOUR: u64 = 28800;

    
    public(friend) fun create_rebase_fee_model(account: &signer, base: Rate, multiplier: Decimal) {
        let model = RebaseFeeModel { base, multiplier };
        move_to(account, model);
    }

    public(friend) fun create_reserving_fee_model(account: &signer, multiplier: Decimal) {
      let model = ReservingFeeModel { multiplier };
      move_to(account, model);
    }


    public(friend) fun create_funding_fee_model(account: &signer, multiplier: Decimal, max: Rate) {
      let model = FundingFeeModel { multiplier, max };
      move_to(account, model);
    }

    public  fun get_rebase_fee_model_data(addr: address): (Rate, Decimal) acquires RebaseFeeModel {
      let model = borrow_global<RebaseFeeModel>(addr);
      (model.base, model.multiplier)
    }

    public fun get_reserving_fee_model_data(addr: address): (Decimal) acquires ReservingFeeModel {
      let model = borrow_global<ReservingFeeModel>(addr);
      (model.multiplier)
    }

    public fun get_funding_fee_model_data(addr: address): (Rate, Decimal) acquires FundingFeeModel {
      let model = borrow_global<FundingFeeModel>(addr);
      (model.max, model.multiplier)
    }


    public  fun compute_rebase_fee_rate(
        model: &RebaseFeeModel,
        increase: bool,
        ratio: Rate,
        target_ratio: Rate,
    ): Rate {
        if ((increase && rate::le(&ratio, &target_ratio))
            || (!increase && rate::ge(&ratio, &target_ratio))) {
            model.base
        } else {
            let delta_rate = decimal::mul_with_rate(
                model.multiplier,
                rate::diff(ratio, target_ratio),
            );
            rate::add(model.base, decimal::to_rate(delta_rate))
        }
    }

    public  fun compute_reserving_fee_rate(
        model: &ReservingFeeModel,
        utilization: Rate,
        elapsed: u64,
    ): Rate {
        let daily_rate = decimal::to_rate(
            decimal::mul_with_rate(model.multiplier, utilization)
        );
        rate::div_by_u64(
            rate::mul_with_u64(daily_rate, elapsed),
            SECONDS_PER_EIGHT_HOUR,
        )
    }

    public  fun compute_funding_fee_rate(
        model: &FundingFeeModel,
        pnl_per_lp: SDecimal,
        elapsed: u64,
    ): SRate {
        let daily_rate = decimal::to_rate(
            decimal::mul(model.multiplier, sdecimal::value(&pnl_per_lp))
        );
        if (rate::gt(&daily_rate, &model.max)) {
            daily_rate = model.max;
        };
        let seconds_rate = rate::div_by_u64(
            rate::mul_with_u64(daily_rate, elapsed),
            SECONDS_PER_EIGHT_HOUR,
        );
        srate::from_rate(
            !sdecimal::is_positive(&pnl_per_lp),
            seconds_rate,
        )
    }
    

   public(friend) fun update_rebase_fee_model(account: &signer, base: u128, multiplier: u128) {
        admin::assert_admin(account);

        let addr = signer::address_of(account);
        let model = borrow_global_mut<RebaseFeeModel>(addr);
        model.base = rate::from_raw(base);
        model.multiplier = decimal::from_raw((multiplier as u256));
    }

    public(friend)  fun update_reserving_fee_model(account: &signer, multiplier: u128) {
        admin::assert_admin(account);

        let addr = signer::address_of(account);
        let model = borrow_global_mut<ReservingFeeModel>(addr);
        model.multiplier = decimal::from_raw((multiplier as u256));
    }

    public(friend)  fun update_funding_fee_model(account: &signer, multiplier: u128, max: u128) {
        admin::assert_admin(account);

        let addr = signer::address_of(account);
        let model = borrow_global_mut<FundingFeeModel>(addr);
        model.multiplier = decimal::from_raw((multiplier as u256));
        model.max = rate::from_raw(max);
    }
}