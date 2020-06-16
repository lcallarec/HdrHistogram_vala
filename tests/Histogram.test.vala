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
        
        Test.add_func("/HdrHistogram/Histogram/buckets", () => {
            var histogram = new Histogram(1, (int64) Math.pow(2, 32), 3);

            assert(histogram.sub_bucket_count == 2048);
            assert(histogram.unit_magnitude == 0);

            // subBucketCount = 2^11, so 2^11 << 22 is > the max of 2^32 for 23 buckets total
            assert(23 == histogram.bucket_count);

            // first half of first bucket
            assert(histogram.get_bucket_index(3) == 0);
            assert(histogram.get_sub_bucket_index(3, 0) == 3);

            // second half of first bucket
            assert(histogram.get_bucket_index(1024 + 3) == 0);
            assert(histogram.get_sub_bucket_index(1024 + 3, 0) == 1024 + 3);

            // second bucket (top half)
            assert(histogram.get_bucket_index(2048 + 3 * 2) == 1);
            // counting by 2s, starting at halfway through the bucket
            assert(histogram.get_sub_bucket_index(2048 + 3 * 2, 1) == 1024 + 3);

            // third bucket (top half)
            assert(histogram.get_bucket_index((2048 << 1) + 3 * 4) == 2);
            // counting by 4s, starting at halfway through the bucket
            assert(histogram.get_sub_bucket_index((2048 << 1) + 3 * 4, 2) == 1024 + 3);

            // past last bucket -- not near Long.MAX_VALUE, so should still calculate ok.
            assert(histogram.get_bucket_index(((int64) 2048 << 22) + 3 * (1 << 23)) == 23);
            assert(histogram.get_sub_bucket_index(((int64) 2048 << 22) + 3 * (1 << 23), 23) == 1024 + 3);
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

        Test.add_func("/HdrHistogram/Histogram/get_value_at_percentile_limit_cases", () => {
            // given
            var histogram = new Histogram(1, 1024, 3);

            // when
            for (var i = 0;i<100;i++) {
                histogram.record_value(1);
            }

            histogram.record_value(100);
             
            //when
            try {
                assert(histogram.get_value_at_percentile(99) == 1);
                assert(histogram.get_value_at_percentile(99.9) == 100);
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

        Test.add_func("/HdrHistogram/Histogram/output_percentile_distribution", () => {
            // given
            var histogram = new Histogram(1, 3600000000000, 3);

            // when
            histogram.record_value(100);
            histogram.record_value(200);
            histogram.record_value(250);
            histogram.record_value(600);

            //then
            FileStream? output = FileStream.open("output_percentile_distribution", "w");
            if (output != null) {
                histogram.output_percentile_distribution(output, 5, 1);
                output = null;
            } else {
                assert_not_reached();
            }

            GLib.File file = GLib.File.new_for_path("output_percentile_distribution");
            FileInputStream reader = file.read();
            DataInputStream data_reader = new DataInputStream(reader);

            string output_percentile_distribution = "";
            while(true) {
                var line = data_reader.read_line();
                if (line == null) {
                    break;
                }
                output_percentile_distribution += line + "\n";
            }

            try {
                file.delete();
            } catch {
                assert_not_reached();
            }

            string expected_output = """       Value     Percentile TotalCount 1/(1-Percentile)

     100.000 0.000000000000          1           1.00
     100.000 0.100000000000          1           1.11
     100.000 0.200000000000          1           1.25
     200.000 0.300000000000          2           1.43
     200.000 0.400000000000          2           1.67
     200.000 0.500000000000          2           2.00
     250.000 0.550000000000          3           2.22
     250.000 0.600000000000          3           2.50
     250.000 0.650000000000          3           2.86
     250.000 0.700000000000          3           3.33
     250.000 0.750000000000          3           4.00
     600.000 0.775000000000          4           4.44
     600.000 1.000000000000          4
#[Mean    =      287.500, StdDeviation   =      188.331]
#[Max     =      600.000, Total count    =            4]
#[Buckets =           32, SubBuckets     =         2048]
""";
           assert(output_percentile_distribution == expected_output);

        });

        Test.add_func("/HdrHistogram/Histogram/output_percentile_distribution#csv", () => {
            // given
            var histogram = new Histogram(1, 3600000000000, 3);

            // when
            histogram.record_value(100);
            histogram.record_value(200);
            histogram.record_value(250);
            histogram.record_value(600);

            //then
            FileStream? output = FileStream.open("output_percentile_distribution", "w");
            if (output != null) {
                histogram.output_percentile_distribution(output, 5, 1, true);
                output = null;
            } else {
                assert_not_reached();
            }

            GLib.File file = GLib.File.new_for_path("output_percentile_distribution");
            FileInputStream reader = file.read();
            DataInputStream data_reader = new DataInputStream(reader);

            string output_percentile_distribution = "";
            while(true) {
                var line = data_reader.read_line();
                if (line == null) {
                    break;
                }
                output_percentile_distribution += line + "\n";
            }

            try {
                file.delete();
            } catch {
                assert_not_reached();
            }

            string expected_output = """"Value","Percentile","TotalCount","1/(1-Percentile)"
100.000,0.000000000000,1,1.00
100.000,0.100000000000,1,1.11
100.000,0.200000000000,1,1.25
200.000,0.300000000000,2,1.43
200.000,0.400000000000,2,1.67
200.000,0.500000000000,2,2.00
250.000,0.550000000000,3,2.22
250.000,0.600000000000,3,2.50
250.000,0.650000000000,3,2.86
250.000,0.700000000000,3,3.33
250.000,0.750000000000,3,4.00
600.000,0.775000000000,4,4.44
600.000,1.000000000000,4,Infinity
""";

           assert(output_percentile_distribution == expected_output);
        });

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
                var new_histogram = AbstractHistogram.decode_from_byte_buffer(buffer, 1024);
                
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
                var new_histogram = AbstractHistogram.decode_from_compressed_byte_buffer(compressed_buffer, 1024);
                
                //then
                assert(new_histogram.get_value_at_percentile(25) == p25);
                assert(new_histogram.get_value_at_percentile(90) == p90);
                assert(new_histogram.get_value_at_percentile(99) == p99);
                assert(new_histogram.get_value_at_percentile(99.9) == p999);

            } catch {
                assert_not_reached();
            }
        });

        Test.add_func("/HdrHistogram/Histogram/record_value_with_expected_interval#generate_values", () => {
            // given
            var histogram = new Histogram(1, 1024, 3);
    
            // when
            histogram.record_value_with_expected_interval(207, 100);
    
            // then
            assert(histogram.get_total_count() == 2);
            assert(histogram.get_min_non_zero_value() == 107);
            assert(histogram.get_max_value() == 207);
        });

        Test.add_func("/HdrHistogram/Histogram/record_value_with_expected_interval#generate_values_in_a_new_histogram", () => {
            // given
            var histogram = new Histogram(1, 1024, 3);
            histogram.record_value(207);
            histogram.record_value(207);

            // when
            var corrected_histogram = histogram.copy_corrected_for_coordinated_omission(100);

            // then
            assert(corrected_histogram.get_total_count() == 4);
            assert(corrected_histogram.get_min_non_zero_value() == 107);
            assert(corrected_histogram.get_max_value() == 207);
        });
    }
}