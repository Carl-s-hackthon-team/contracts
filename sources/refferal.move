
module AGDEX::referral {
    use AGDEX::rate::Rate;

    friend AGDEX::market;

    struct Referral has store {
        referrer: address,
        rebate_rate: Rate,
    }

    public fun new_referral(
        referrer: address,
        rebate_rate: Rate,
    ): Referral {
        Referral { referrer, rebate_rate }
    }

    public fun get_referrer(referral: &Referral): address {
        referral.referrer
    }

    public fun get_rebate_rate(referral: &Referral): Rate {
        referral.rebate_rate
    }
}
