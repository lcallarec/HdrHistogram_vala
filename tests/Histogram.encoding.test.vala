namespace HdrHistogram { 

    void register_histogram_encoding() {

        Test.add_func("/HdrHistogram/Histogram/encode_decode", () => {
            // given
            var histogram = new Histogram(1, 300, 3);
            
            // when
            histogram.record_value(115);
            histogram.record_value(198);
            histogram.record_value(578);
            histogram.record_value(45);
            histogram.record_value(215);
            histogram.record_value(320);
                
            try {
                //when
                var encoded = histogram.encode();
                var new_histogram = Histogram.decode(encoded);

                //then
                assert_same_histograms(histogram, new_histogram);

            } catch (Error e) {
                assert_not_reached();
            }
        });
        
        Test.add_func("/HdrHistogram/Histogram/encode_decode_compressed", () => {
            // given
            var histogram = new Histogram(1, 300, 3);
            
            // when
            histogram.record_value(115);
            histogram.record_value(198);
            histogram.record_value(578);
            histogram.record_value(45);
            histogram.record_value(215);
            histogram.record_value(320);
                
            try {
                //when
                var encoded = histogram.encode_compressed();
                var new_histogram = Histogram.decode_compressed(encoded);

                //then
                assert_same_histograms(histogram, new_histogram);

            } catch (Error e) {
                assert_not_reached();
            }
        });
        
        Test.add_func("/HdrHistogram/Histogram/encode_decode_from_byte_buffer", () => {
            // given
            var histogram = new Histogram(1, 1024, 3);
            histogram.record_value(115);
            histogram.record_value(198);
            histogram.record_value(578);
            histogram.record_value(45);
            histogram.record_value(215);
            histogram.record_value(320);
                
            try {
                
                // when
                var buffer = histogram.encode_into_byte_buffer();
                var new_histogram = Histogram.decode_from_byte_buffer(buffer);
                
                //then
                assert_same_histograms(histogram, new_histogram);

            } catch {
                assert_not_reached();
            }
        });

        Test.add_func("/HdrHistogram/Histogram/encode_decode_from_compressedbyte_buffer", () => {
            // given
            var histogram = new Histogram(1, 1024, 3);
            histogram.record_value(115);
            histogram.record_value(198);
            histogram.record_value(578);
            histogram.record_value(45);
            histogram.record_value(215);
            histogram.record_value(320);
                
            try {
                // when
                var compressed_buffer = histogram.encode_into_compressed_byte_buffer();
                var new_histogram = Histogram.decode_from_compressed_byte_buffer(compressed_buffer);
                
                //then
                assert_same_histograms(histogram, new_histogram);
            } catch {
                assert_not_reached();
            }
        });

        Test.add_func("/HdrHistogram/Int16Histogram/encode_decode", () => {
            // given
            var histogram = new Int16Histogram(1, 300, 3);
            
            // when
            histogram.record_value(115);
            histogram.record_value(198);
            histogram.record_value(578);
            histogram.record_value(45);
            histogram.record_value(215);
            histogram.record_value(320);
                
            try {
                //when
                var encoded = histogram.encode();
                var new_histogram = Int16Histogram.decode(encoded);

                //then
                assert_same_histograms(histogram, new_histogram);

            } catch (Error e) {
                assert_not_reached();
            }
        });
        
        Test.add_func("/HdrHistogram/Int16Histogram/encode_decode_compressed", () => {
            // given
            var histogram = new Int16Histogram(1, 300, 3);
            
            // when
            histogram.record_value(115);
            histogram.record_value(198);
            histogram.record_value(578);
            histogram.record_value(45);
            histogram.record_value(215);
            histogram.record_value(320);
                
            try {
                //when
                var encoded = histogram.encode_compressed();
                var new_histogram = Int16Histogram.decode_compressed(encoded);

                //then
                assert_same_histograms(histogram, new_histogram);

            } catch (Error e) {
                assert_not_reached();
            }
        });
        
        Test.add_func("/HdrHistogram/Int16Histogram/encode_decode_from_byte_buffer", () => {
            // given
            var histogram = new Int16Histogram(1, 1024, 3);
            histogram.record_value(115);
            histogram.record_value(198);
            histogram.record_value(578);
            histogram.record_value(45);
            histogram.record_value(215);
            histogram.record_value(320);
                
            try {
                
                // when
                var buffer = histogram.encode_into_byte_buffer();
                var new_histogram = Int16Histogram.decode_from_byte_buffer(buffer);
                
                //then
                assert_same_histograms(histogram, new_histogram);

            } catch {
                assert_not_reached();
            }
        });

        Test.add_func("/HdrHistogram/Int16Histogram/encode_decode_from_compressed_byte_buffer", () => {
            // given
            var histogram = new Int16Histogram(1, 1024, 3);
            histogram.record_value(115);
            histogram.record_value(198);
            histogram.record_value(578);
            histogram.record_value(45);
            histogram.record_value(215);
            histogram.record_value(320);
                
            try {
                // when
                var compressed_buffer = histogram.encode_into_compressed_byte_buffer();
                var new_histogram = Int16Histogram.decode_from_compressed_byte_buffer(compressed_buffer);
                
                //then
                assert_same_histograms(histogram, new_histogram);
            } catch {
                assert_not_reached();
            }
        });
    }
}