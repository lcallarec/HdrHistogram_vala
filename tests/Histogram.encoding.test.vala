namespace HdrHistogram { 

    void register_histogram_encoding() {

        Test.add_func("/HdrHistogram/Histogram/encode_compressed", () => {
            // given
            var histogram = new Histogram(1, 300, 3);
            
            // when
            histogram.record_value(100);
            histogram.record_value(200);
            histogram.record_value(250);
            
            var dump = histogram.encode_compressed();
            
            //then
            assert(dump == "HISTFAAAACV4nJNpmSzMwMDAwQABzFCaEUrp2H+AsI4zMh1lZEpkAgBdIQSk");   
        });
        
        Test.add_func("/HdrHistogram/Histogram/decode", () => {
            // given
            var histogram = new Histogram(1, 1024, 3);
            histogram.record_value(115);
            histogram.record_value(198);
            histogram.record_value(578);
            histogram.record_value(45);
            histogram.record_value(215);
            histogram.record_value(320);
                
            try {
                var p25 = histogram.get_value_at_percentile(25);
                var p90 = histogram.get_value_at_percentile(90);
                var p99 = histogram.get_value_at_percentile(99);
                var p999 = histogram.get_value_at_percentile(99.9);

                var buffer = histogram.encode_into_byte_buffer();
    
                // when
                var new_histogram = Histogram.decode_from_byte_buffer(buffer, 1024);
                
                //then
                assert(new_histogram.get_value_at_percentile(25) == p25);
                assert(new_histogram.get_value_at_percentile(90) == p90);
                assert(new_histogram.get_value_at_percentile(99) == p99);
                assert(new_histogram.get_value_at_percentile(99.9) == p999);

            } catch {
                assert_not_reached();
            }
        });

        Test.add_func("/HdrHistogram/Histogram/decode_compressed", () => {
            // given
            var histogram = new Histogram(1, 1024, 3);
            histogram.record_value(115);
            histogram.record_value(198);
            histogram.record_value(578);
            histogram.record_value(45);
            histogram.record_value(215);
            histogram.record_value(320);
                
            try {
                var p25 = histogram.get_value_at_percentile(25);
                var p90 = histogram.get_value_at_percentile(90);
                var p99 = histogram.get_value_at_percentile(99);
                var p999 = histogram.get_value_at_percentile(99.9);

                var compressed_buffer = histogram.encode_into_compressed_byte_buffer();
    
                // when
                var new_histogram = Histogram.decode_from_compressed_byte_buffer(compressed_buffer, 1024);
                
                //then
                assert(new_histogram.get_value_at_percentile(25) == p25);
                assert(new_histogram.get_value_at_percentile(90) == p90);
                assert(new_histogram.get_value_at_percentile(99) == p99);
                assert(new_histogram.get_value_at_percentile(99.9) == p999);

            } catch {
                assert_not_reached();
            }
        });
}