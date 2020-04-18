namespace HdrHistogram { 
    
    public class Histogram : AbstractHistogram {
        internal int64 total_count;
        internal int64[] counts;
        internal int normalizing_index_offset;

        public Histogram(int64 lowest_discernible_value, int64 highest_trackable_value, int8 number_of_significant_value_digits) {
            base(lowest_discernible_value, highest_trackable_value, number_of_significant_value_digits);
            counts.resize(counts_array_length);
        }

        public override int64 get_total_count() {
            return total_count;
        }

        internal override int64 get_count_at_index(int index) {
            return counts[normalize_index(index, normalizing_index_offset, counts_array_length)];
        }

        internal override void increment_total_count() {
            total_count++;
        }

        internal override void add_to_count_at_index(int index, int64 value) {
            counts[normalize_index(index, normalizing_index_offset, counts_array_length)] += value;
        }

        internal override void increment_count_at_index(int index) throws HdrError {
            var normalized_index = normalize_index(index, normalizing_index_offset, counts_array_length);
            if (normalized_index > counts.length -1) {
                throw new HdrError.INDEX_OUT_OF_BOUNDS("In increment_count_at_index");
            }
            counts[normalized_index]++;
        }

        internal override void resize(int64 new_highest_trackable_value) {
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
    }
}
