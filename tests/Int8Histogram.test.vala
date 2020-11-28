namespace HdrHistogram { 

    void register_int8_histogram() {

        Test.add_func("/HdrHistogram/Int8Histogram/record_value#", () => {
            //given
            var histogram = new Int8Histogram(1, int64.MAX, 3);

            // when
            try {
                for (var i = 0; i < Math.pow(2, 8) - 1; i++) {
                    histogram.record_value(662607);
                }
            } catch (HdrError e) {
                assert_not_reached();
            }

            // then
            assert(histogram.get_count_at_index(10510) == 255);
        });

        Test.add_func("/HdrHistogram/Int8Histogram/record_value_with_count#happy_path", () => {
            //given
            var histogram = new Int8Histogram(1, int64.MAX, 3);

            try {
                //when
                histogram.record_value_with_count(662607, (int64) Math.pow(2, 8) - 1);   
            } catch (HdrError e) {
                assert_not_reached();
            }

            //then
            assert(histogram.get_count_at_index(10510) == 255);
        });

        Test.add_func("/HdrHistogram/Int8Histogram/record_value_with_count#integer_overflow", () => {
            //given
            var histogram = new Int8Histogram(1, int64.MAX, 3);

            //when //then
            try {
                histogram.record_value_with_count(662607, (int64) Math.pow(2, 8));
                assert_not_reached();
            } catch (Error e) {
                //ok
            }
        });

        Test.add_func("/HdrHistogram/Int8Histogram/add#integer_overflow", () => {
            //given
            var histogram1 = new Int8Histogram(1, int64.MAX, 3);
            var histogram2 = new Int8Histogram(1, int64.MAX, 3);

            try {
                histogram1.record_value_with_count(662607, (int64) Math.pow(2, 8) - 1);
                histogram2.record_value_with_count(662607, (int64) Math.pow(2, 8) - 1);
            } catch (HdrError e) {
                assert_not_reached();
            }

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
