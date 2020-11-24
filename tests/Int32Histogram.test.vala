namespace HdrHistogram { 

    void register_int32_histogram() {

        Test.add_func("/HdrHistogram/Int32Histogram/record_value#happy_path", () => {
            //given
            var histogram = new Int32Histogram(1, int64.MAX, 3);

            // when
            for (var i = 0; i < Math.pow(2, 16) - 1; i++) {
                histogram.record_value(662607);
            }

            // then
            assert(histogram.get_count_at_index(10510) == Math.pow(2, 16) - 1);
        });

        Test.add_func("/HdrHistogram/Int32Histogram/record_value_with_count#happy_path", () => {
            //given
            var histogram = new Int32Histogram(1, int64.MAX, 3);

            try {
                //when
                histogram.record_value_with_count(662607, (int64) Math.pow(2, 32) - 1);
   
                //then
                assert(histogram.get_count_at_index(10510) == Math.pow(2, 32) - 1);
            } catch (Error e) {
                assert_not_reached();
            }
        });

        Test.add_func("/HdrHistogram/Int32Histogram/record_value_with_count#integer_overflow", () => {
            //given
            var histogram = new Int32Histogram(1, int64.MAX, 3);

            //when //then
            try {
                histogram.record_value_with_count(662607, (int64) Math.pow(2, 32));
                assert_not_reached();
            } catch (Error e) {
                //ok
            }
        });

        Test.add_func("/HdrHistogram/Int32Histogram/add#integer_overflow", () => {
            //given
            var histogram1 = new Int32Histogram(1, int64.MAX, 3);
            var histogram2 = new Int32Histogram(1, int64.MAX, 3);
            histogram1.record_value_with_count(662607, (int64) Math.pow(2, 32) - 1);
            histogram2.record_value_with_count(662607, (int64) Math.pow(2, 32) - 1);

            //when //then
            try {
                histogram1.add(histogram2);
                assert_not_reached();
            } catch (Error e) {
                //ok
            }
        });
    }
}
