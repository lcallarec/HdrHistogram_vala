namespace HdrHistogram { 

    void register_int16_histogram() {

        Test.add_func("/HdrHistogram/Int16Histogram/revord_value", () => {
            //given
            var histogram = new Int16Histogram(1, int64.MAX, 3);

            // when
            for (var i = 0; i < Math.pow(2, 16) - 1; i++) {
                histogram.record_value(662607);
            }

            // then
            assert(histogram.get_count_at_index(10510) == Math.pow(2, 16) - 1);
        });

        Test.add_func("/HdrHistogram/Int16Histogram/revord_value#integer overflow", () => {
            //given
            var histogram = new Int16Histogram(1, int64.MAX, 3);

            //when //then
            var ok = true;
            for (var i = 0; i <= Math.pow(2, 16); i++) {
                ok = histogram.record_value(1);
            }
            assert_false(ok);
 
        });
    }
}
