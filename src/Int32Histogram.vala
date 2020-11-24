namespace HdrHistogram { 
    
    public class Int32Histogram : AbstractHistogram {
        private uint32[] counts;
        private int normalizing_index_offset;
        private int64 total_count;

        public Int32Histogram(int64 lowest_discernible_value, int64 highest_trackable_value, int8 number_of_significant_value_digits) {
            base(lowest_discernible_value, highest_trackable_value, number_of_significant_value_digits);
            counts.resize(counts_array_length);
        }

        /**
         * Construct a histogram with the same range settings as a given source histogram,
         * duplicating the source's start/end timestamps (but NOT its contents)
         * @param source The source histogram to duplicate
         */
        public Int32Histogram.from_source(AbstractHistogram source, bool allocate_counts_array = true) {
            base.from_source(source);
            if (allocate_counts_array) {
                counts = new uint32[counts_array_length];
            }
            word_size_in_bytes = 8;
        }

        public override int64 get_total_count() {
            return total_count;
        }

        public override AbstractHistogram copy_corrected_for_coordinated_omission(int64 expected_interval_between_value_samples) {
            Histogram copy = new Histogram.from_source(this);
            copy.add_while_correcting_for_coordinated_omission(this, expected_interval_between_value_samples);
            return copy;
        }

        internal override void clear_counts() {
            Arrays.Int32.fill((int32[]) counts, 0, counts_array_length, 0);
            total_count = 0;
        }

        internal override int64 get_count_at_index(int index) throws HdrError.INDEX_OUT_OF_BOUNDS {
            return counts[normalize_index(index, normalizing_index_offset, counts_array_length)];
        }

        internal override void increment_total_count() {
            total_count++;
        }

        internal override void add_to_count_at_index(int index, int64 value) throws HdrError {
            var normalized_index = normalize_index(index, normalizing_index_offset, counts_array_length);
            if (normalized_index + value > int32.MAX) {
                throw new HdrError.INTEGER_OVERFLOW("Integer overflow error : %lld would overflow uint32.MAX value".printf(normalized_index + value));
            }

            counts[normalized_index] += (uint8) value;
        }

        internal override void add_to_total_count(int64 value) {
            total_count += value;
        }

        internal override void increment_count_at_index(int index) throws HdrError {
            var normalized_index = normalize_index(index, normalizing_index_offset, counts_array_length);
            var newCount = (int64) counts[normalized_index] + 1;
            if (newCount> uint32.MAX) {
                throw new HdrError.INTEGER_OVERFLOW("Integer overflow error : %lld would overflow uint32.MAX value".printf(newCount));
            }

            if (normalized_index > counts.length -1) {
                throw new HdrError.INDEX_OUT_OF_BOUNDS("In increment_count_at_index");
            }
            counts[normalized_index]++;
        }

        internal override void resize(int64 new_highest_trackable_value) {
            int old_normalized_zero_index = normalize_index(0, normalizing_index_offset, counts_array_length);

            establish_size(new_highest_trackable_value);

            int counts_delta = counts_array_length - counts.length;

            counts = (uint32[]) Arrays.Int32.copy((int32[]) counts, counts_array_length);

            if (old_normalized_zero_index != 0) {
                // We need to shift the stuff from the zero index and up to the end of the array:
                int new_normalized_zero_index = old_normalized_zero_index + counts_delta;
                int length_to_copy = (counts_array_length - counts_delta) - old_normalized_zero_index;
                Arrays.Int32.array_copy((int32[]) counts, old_normalized_zero_index, (int32[]) counts, new_normalized_zero_index, length_to_copy);
                Arrays.Int32.fill((int32[]) counts, old_normalized_zero_index, new_normalized_zero_index, 0);
            }
        }

        internal override int get_normalizing_index_offset() {
            return normalizing_index_offset;
        }

        internal override void set_normalizing_index_offset(int normalizing_index_offset) {
            this.normalizing_index_offset = normalizing_index_offset;
        }

        internal override void set_integer_to_double_value_conversion_ratio(double integer_to_double_value_conversion_ratio) {
            non_concurrent_set_integer_to_double_value_conversion_ratio(integer_to_double_value_conversion_ratio);
        }

        internal override void set_count_at_index(int index, int64 value) {
            counts[normalize_index(index, normalizing_index_offset, counts_array_length)] = (uint8) value;
        }

        internal override void set_total_count(int64 total_count) {
            this.total_count = total_count;
        }
    }
}
