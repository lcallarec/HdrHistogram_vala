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
            histogram.record_value(100);

            // then
            assert(histogram.get_min_value() == 100);
            assert(histogram.get_max_value() == 100);
        });
    }
}



