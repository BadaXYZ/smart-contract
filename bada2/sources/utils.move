module bada2::utils{
    public fun calculate_percent_amount(amount: u64, percentage: u64): u64 {
        (amount * percentage) / 100
    }
}