
module AGDEX::agg_price {
    use aptos_framework::math64::pow;
    use aptos_framework::managed_coin;
    use aptos_framework::coin::{Self, Coin, CoinStore};
    use aptos_framework::timestamp::now_microseconds;


    use pyth::i64::{Self as pyth_i64};
    use pyth::price::{Self as pyth_price};
    use pyth::pyth::{Self,from_byte_vec, get_price};

    use AGDEX::decimal::{Self, Decimal};

    friend AGDEX::market;

    struct AggPrice has drop, store {
        price: Decimal,
        precision: u64,
    }

    struct AggPriceConfig has key, store {
        max_interval: u64,
        max_confidence: u64,
        precision: u64,
        feeder: vector<u8>, 
    }

    const ERR_INVALID_PRICE_FEEDER: u64 = 1;
    const ERR_PRICE_STALED: u64 = 2;
    const ERR_EXCEED_PRICE_CONFIDENCE: u64 = 3;
    const ERR_INVALID_PRICE_VALUE: u64 = 4;

    
    public fun new_agg_price_config(
        max_interval: u64,
        max_confidence: u64,
        decimals: u8,
        feeder_address: vector<u8>,
    ): AggPriceConfig {
        AggPriceConfig {
            max_interval,
            max_confidence,
            precision: pow(10, (decimals as u64)),
            feeder: feeder_address,
        }
    }

    public fun update_agg_price_config(
        config: &mut AggPriceConfig,
        new_feeder_address: vector<u8>,
    ) {
        config.feeder = new_feeder_address;
    }

    public fun from_price(config: &AggPriceConfig, price: Decimal): AggPrice {
        AggPrice { price, precision: config.precision }
    }

    public fun parse_pyth(
        config: &mut AggPriceConfig,
        timestamp: u64,
        feeder_address: vector<u8>,
    ): AggPrice {
        assert!(feeder_address == config.feeder, ERR_INVALID_PRICE_FEEDER);

        let price = get_price(feeder);
        let price_info = get_price(from_byte_vec(feeder_address));
        let current_time = now_microseconds();

        assert!(
            price_info.timestamp + config.max_interval >= current_time,
            ERR_PRICE_STALED
        );

        assert!(
            price_info.confidence <= config.max_confidence,
            ERR_EXCEED_PRICE_CONFIDENCE
        );

        let price = price_info.price;

        assert!(price > 0, ERR_INVALID_PRICE_VALUE);

        let exp = pyth_price::get_expo(&price);
        let price = if (pyth_i64::get_is_negative(&exp)) {
            let exp = pyth_i64::get_magnitude_if_negative(&exp);
            decimal::div_by_u64(decimal::from_u64(price), pow(10, (exp as u64)))
        } else {
            let exp = pyth_i64::get_magnitude_if_positive(&exp);
            decimal::mul_with_u64(decimal::from_u64(price), pow(10, (exp as u64)))
        };

        AggPrice {
            price,
            precision: config.precision
        }
    }

    public fun price_of(self: &AggPrice): Decimal {
        self.price
    }

    public fun precision_of(self: &AggPrice): u64 {
        self.precision
    }

    public fun coins_to_value(self: &AggPrice, amount: u64): Decimal {
        decimal::div_by_u64(
            decimal::mul_with_u64(self.price, amount),
            self.precision,
        )
    }

    public fun value_to_coins(self: &AggPrice, value: Decimal): Decimal {
        decimal::div(
            decimal::mul_with_u64(value, self.precision),
            self.price,
        )
    }
}