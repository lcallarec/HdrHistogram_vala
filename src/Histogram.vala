namespace HdrHistogram { 
    
    public class Histogram : AbstractHistogram {
        private int64[] counts;
        private int normalizing_index_offset;
        private int64 total_count;

        public Histogram(int64 lowest_discernible_value, int64 highest_trackable_value, int8 number_of_significant_value_digits) {
            base(lowest_discernible_value, highest_trackable_value, number_of_significant_value_digits);
            counts.resize(counts_array_length);
        }

        /**
         * Construct a histogram with the same range settings as a given source histogram,
         * duplicating the source's start/end timestamps (but NOT its contents)
         * @param source The source histogram to duplicate
         */
        public Histogram.from_source(AbstractHistogram source, bool allocate_counts_array = true) {
            base.from_source(source);
            if (allocate_counts_array) {
                counts = new int64[counts_array_length];
            }
            word_size_in_bytes = 8;
        }

        public override int64 get_total_count() {
            return total_count;
        }

        public override AbstractHistogram copy_corrected_for_coordinated_omission(int64 expected_interval_between_value_samples) throws HdrError {
            Histogram copy = new Histogram.from_source(this);
            copy.add_while_correcting_for_coordinated_omission(this, expected_interval_between_value_samples);
            return copy;
        }

        public static Histogram decode(string histogram) throws HdrError {
            return _decode(typeof(Histogram), histogram) as Histogram;
        }

        public static Histogram decode_compressed(string histogram) throws HdrError {
            return _decode_compressed(typeof(Histogram), histogram) as Histogram;
        }

        public static Histogram decode_from_byte_buffer(ByteArray buffer)  throws HdrError {
            return _decode_from_byte_buffer(typeof(Histogram), buffer) as Histogram;
        }

        public static Histogram decode_from_compressed_byte_buffer(ByteArray compressed_buffer) throws HdrError {
            return _decode_from_compressed_byte_buffer(typeof(Histogram), compressed_buffer) as Histogram;
        }

        internal override void clear_counts() {
            Arrays.Int64.fill(counts, 0, counts_array_length, 0);
            total_count = 0;
        }

        internal override int64 get_count_at_index(int index) {
            try {
                return counts[normalize_index(index, normalizing_index_offset, counts_array_length)];
            } catch (HdrError e) {
                return 0;
            }
        }

        internal override void increment_total_count() {
            total_count++;
        }

        internal override void add_to_count_at_index(int index, int64 value) throws HdrError {
            var normalized_index = normalize_index(index, normalizing_index_offset, counts_array_length);
            var currentCount = counts[normalized_index];
            var newCount = (uint64) (currentCount + value);
            if (newCount > int64.MAX) {
                throw new HdrError.INDEX_OUT_OF_BOUNDS("Integer overflow error : %lld would overflow int64.MAX value".printf(newCount));
            }
            counts[normalize_index(index, normalizing_index_offset, counts_array_length)] = value;
        }

        internal override void add_to_total_count(int64 value) {
            total_count += value;
        }

        internal override void increment_count_at_index(int index) throws HdrError {
            var normalized_index = normalize_index(index, normalizing_index_offset, counts_array_length);
            if (normalized_index > counts.length -1) {
                throw new HdrError.INDEX_OUT_OF_BOUNDS("In increment_count_at_index");
            }
            counts[index]++;
        }

        internal override void resize(int64 new_highest_trackable_value) throws HdrError {
            int old_normalized_zero_index = normalize_index(0, normalizing_index_offset, counts_array_length);

            establish_size(new_highest_trackable_value);

            int counts_delta = counts_array_length - counts.length;

            counts = Arrays.Int64.copy(counts, counts_array_length);

            if (old_normalized_zero_index != 0) {
                // We need to shift the stuff from the zero index and up to the end of the array:
                int new_normalized_zero_index = old_normalized_zero_index + counts_delta;
                int length_to_copy = (counts_array_length - counts_delta) - old_normalized_zero_index;
                Arrays.Int64.array_copy(counts, old_normalized_zero_index, counts, new_normalized_zero_index, length_to_copy);
                Arrays.Int64.fill(counts, old_normalized_zero_index, new_normalized_zero_index, 0);
            }
        }

        internal override int get_normalizing_index_offset() {
            return normalizing_index_offset;
        }

        internal override void set_normalizing_index_offset(int normalizing_index_offset) {
            this.normalizing_index_offset = normalizing_index_offset;
        }

        internal override void set_count_at_index(int index, int64 value) throws HdrError {
            counts[normalize_index(index, normalizing_index_offset, counts_array_length)] = value;
        }

        internal override void set_total_count(int64 total_count) {
            this.total_count = total_count;
        }
    }
}
