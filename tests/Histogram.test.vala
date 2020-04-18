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
    }
}



