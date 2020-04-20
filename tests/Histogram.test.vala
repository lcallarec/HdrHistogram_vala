namespace HdrHistogram { 

    void register_histogram() {

        Test.add_func("/HdrHistogram/Histogram/init", () => {
            // given //when
            var histogram = new Histogram(1, 9007199254740991, 3);
            
            // then
            assert(histogram.bucket_count == 43);
            assert(histogram.sub_bucket_count == 2048);
            assert(histogram.counts_array_length == 45056);

            assert(histogram.get_max_value() == 0);
            assert(histogram.get_min_value() == 0);
            assert(histogram.unit_magnitude == 0);
            assert(histogram.sub_bucket_half_count_magnitude == 10);
        });
        
        Test.add_func("/HdrHistogram/Histogram/recordValue#Update min and max value", () => {
            // given
            var histogram = new Histogram(1, 9007199254740991, 3);
            
            //when
            var result = histogram.record_value(100);

            // then
            assert(result == true);
            assert(histogram.get_min_value() == 100);
            assert(histogram.get_max_value() == 100);
        });

        Test.add_func("/HdrHistogram/Histogram/recordValue#Should not record a value far above highest_trackable_value", () => {
            // given
            var histogram = new Histogram(1, 2048, 3);
            
            //when //then
            try {
                histogram.record_single_value(10000);
                assert_not_reached();
            } catch {}

            var result = histogram.record_value(10000);
            assert(result == false);
        });

        Test.add_func("/HdrHistogram/Histogram/recordValue#Should record a value far above highest_trackable_value when auto resize in on", () => {
            // given
            var histogram = new Histogram(1, 2048, 3);
            histogram.set_auto_resize(true);
            
            //when //then
            try {
                histogram.record_single_value(10000);
                var result = histogram.record_value(10000);
                assert(result == true);
            } catch {
                assert_not_reached();
            }
        });

        Test.add_func("/HdrHistogram/Histogram/get_mean", () => {
            // given
            var histogram = new Histogram(1, 1024, 3);

            // when
            histogram.record_value(100);
            histogram.record_value(150);
            histogram.record_value(200);
 
            
            //when
            try {
                assert(histogram.get_mean() == 150);
            } catch {
                assert_not_reached();
            }
        });

        Test.add_func("/HdrHistogram/Histogram/get_std_deviation", () => {
            // given
            var histogram = new Histogram(1, 1024, 3);

            // when
            histogram.record_value(100);
            histogram.record_value(150);
            histogram.record_value(200);
            histogram.record_value(250);
            histogram.record_value(300);
             
            //when
            try {
                assert(histogram.get_std_deviation() > 70.71067811865);
                assert(histogram.get_std_deviation() < 70.71067811866);
            } catch {
                assert_not_reached();
            }
        });

        Test.add_func("/HdrHistogram/Histogram/get_value_at_percentile", () => {
            // given
            var histogram = new Histogram(1, 1024, 3);

            // when
            histogram.record_value(115);
            histogram.record_value(198);
            histogram.record_value(578);
            histogram.record_value(45);
            histogram.record_value(215);
            histogram.record_value(320);
             
            //when
            try {
                assert(histogram.get_value_at_percentile(25) == 115);
                assert(histogram.get_value_at_percentile(90) == 578);
            } catch {
                assert_not_reached();
            }            
        });

        Test.add_func("/HdrHistogram/Histogram/get_percentile_at_or_below_value", () => {
            // given
            var histogram = new Histogram(1, 1024, 3);

            // when
            histogram.record_value(115);
            histogram.record_value(198);
            histogram.record_value(578);
            histogram.record_value(45);
            histogram.record_value(215);
            histogram.record_value(320);
             
            //when
            try {
                var percentile_for_100 = histogram.get_percentile_at_or_below_value(100);
                var percentile_for_500 = histogram.get_percentile_at_or_below_value(500);
                assert(percentile_for_100 > 16.66666);
                assert(percentile_for_100 < 16.666667);
                assert(percentile_for_500 > 83.333333);
                assert(percentile_for_500 < 83.333334);
            } catch {
                assert_not_reached();
            }
        });

        Test.add_func("/HdrHistogram/Histogram/reset", () => {
            // given
            var histogram = new Histogram(1, 1024, 3);

            // when
            histogram.record_value(578);
            histogram.record_value(120);
            histogram.record_value(157);

            histogram.reset();

            histogram.record_value(100);
            histogram.record_value(150);
            histogram.record_value(200);
            //when
            try {
                assert(histogram.get_mean() == 150);
            } catch {
                assert_not_reached();
            }
        });        
    }
}