namespace HdrHistogram { 

    void register_int64() {
        Test.add_func("/HdrHistogram/Int64/number_of_leading_zeros", () => {
            assert(Int64.number_of_leading_zeros(-1) == 0);
            assert(Int64.number_of_leading_zeros(-9223372036854775808) == 0);
            assert(Int64.number_of_leading_zeros(9223372036854775807) == 1);
            assert(Int64.number_of_leading_zeros(4611686018427387903) == 2);
            assert(Int64.number_of_leading_zeros(1224979098644774911) == 3);
            assert(Int64.number_of_leading_zeros(9007199254740992) == 10);
            assert(Int64.number_of_leading_zeros(4503599627370496) == 11);
            assert(Int64.number_of_leading_zeros(4503599627370495) == 12);
            assert(Int64.number_of_leading_zeros(2147483648) == 32);
            assert(Int64.number_of_leading_zeros(2147483647) == 33);
            assert(Int64.number_of_leading_zeros(2) == 62);
            assert(Int64.number_of_leading_zeros(1) == 63);
            assert(Int64.number_of_leading_zeros(0) == 64);
        });
    }
}
