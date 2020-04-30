namespace HdrHistogram { 

    public errordomain HdrError {
        ILLEGAL_ARGUMENT,
        INDEX_OUT_OF_BOUNDS,
        CONCURRENT_MODIFICATION_EXCEPTION,
        NO_SUCH_ELEMENT,
        UNSUPPORTED_OPERATION
    }

    /**
     * Unlike the Java reference implementation, there's no need to separate AbstractHistogramBase 
     * from AbstractHistogram. But keeping vala implementation as much as possible in sync with reference implementation
     * helps for adding features and debuging.
     */
    public abstract class AbstractHistogramBase {
        
        internal bool auto_resize = false;

        internal int64 lowest_discernible_value;
        internal int64 highest_trackable_value;
        internal int8 number_of_significant_value_digits;

        internal int bucket_count;

        /**
         * Power-of-two length of linearly scaled array slots in the counts array. Long enough to hold the first sequence of
         * entries that must be distinguished by a single unit (determined by configured precision).
         */
        internal int sub_bucket_count;
        internal int counts_array_length;

        internal int64 start_time_stamp_msec = int64.MAX;
        internal int64 end_time_stamp_msec = 0;
        internal string tag = null;

        internal double integer_to_double_value_conversion_ratio = 1.0;

        internal PercentileIterator percentile_iterator;
        internal RecordedValuesIterator recorded_values_iterator;

        internal double get_integer_to_double_value_conversion_ratio() {
            return integer_to_double_value_conversion_ratio;
        }
    }

    public abstract class AbstractHistogram : AbstractHistogramBase {
    
        /**
         * Number of leading zeros in the largest value that can fit in bucket 0.
         */
        internal int leading_zero_count_base;
        internal int sub_bucket_half_count_magnitude;

        /**
         * Largest k such that 2^k <= lowest_discernible_value
         */        
        internal int unit_magnitude;
        internal int sub_bucket_half_count;

        /**
         * Biggest value that can fit in bucket 0
         */        
        internal int64 sub_bucket_mask;

        /**
         * Lowest unitMagnitude bits are set
         */
        int64 unit_magnitude_mask;  

        int64 max_value = 0;
        int64 min_non_zero_value = int64.MAX;

        // Abstract methods
        internal abstract void increment_count_at_index(int index) throws HdrError;
        internal abstract void resize(int64 new_highest_trackable_value);
        internal abstract void add_to_count_at_index(int index, int64 value);
        internal abstract void increment_total_count();
        internal abstract int64 get_count_at_index(int index) throws HdrError.INDEX_OUT_OF_BOUNDS;
        internal abstract void clear_counts();
        internal abstract int get_normalizing_index_offset();
        internal abstract void set_normalizing_index_offset(int normalizing_index_offset);

        /**
         * Get the total count of all recorded values in the histogram
         * @return the total count of all recorded values in the histogram
         */
        public abstract int64 get_total_count();

        /**
         * Construct a histogram given the Lowest and Highest values to be tracked and a number of significant
         * decimal digits. Providing a lowest_discernible_value is useful is situations where the units used
         * for the histogram's values are much smaller that the minimal accuracy required. E.g. when tracking
         * time values stated in nanosecond units, where the minimal accuracy required is a microsecond, the
         * proper value for lowest_discernible_value would be 1000.
         *
         * @lowest_discernible_value           The lowest value that can be discerned (distinguished from 0) by the histogram.
         *                                     Must be a positive integer that is {@literal >=} 1. May be internally rounded
         *                                     down to nearest power of 2.
         * @highest_trackable_value            The highest value to be tracked by the histogram. Must be a positive
         *                                     integer that is {@literal >=} (2 * lowest_discernible_value).
         * @number_of_significant_value_digits The number of significant decimal digits to which the histogram will
         *                                     maintain value resolution and separation. Must be a non-negative
         *                                     integer between 0 and 5.
         */        
        public AbstractHistogram(
            int64 lowest_discernible_value,
            int64 highest_trackable_value,
            int8 number_of_significant_value_digits
        ) 
        {
           init(lowest_discernible_value, highest_trackable_value, number_of_significant_value_digits, 1.0, 0);
        }

        private void init(
            int64 lowest_discernible_value,
            int64 highest_trackable_value,
            int8 number_of_significant_value_digits,
            double integer_to_double_value_conversion_ratio,
            int normalizing_index_offset
        ) {
            this.lowest_discernible_value = lowest_discernible_value;
            this.highest_trackable_value = highest_trackable_value;
            this.number_of_significant_value_digits = number_of_significant_value_digits;

            /*
             * Given a 3 decimal point accuracy, the expectation is obviously for "+/- 1 unit at 1000". It also means that
             * it's "ok to be +/- 2 units at 2000". The "tricky" thing is that it is NOT ok to be +/- 2 units at 1999. Only
             * starting at 2000. So internally, we need to maintain single unit resolution to 2x 10^decimalPoints.
             */
            var largest_value_with_single_unit_resolution = 2 * (int64) Math.pow(10, number_of_significant_value_digits);
            
            
            // We need to maintain power-of-two subBucketCount (for clean direct indexing) that is large enough to
            // provide unit resolution to at least largest_value_with_single_unit_resolution. So figure out
            // largest_value_with_single_unit_resolution's nearest power-of-two (rounded up), and use that:            
            var sub_bucket_count_magnitude = (int) Math.ceil(Math.log(largest_value_with_single_unit_resolution) / Math.log(2));
            sub_bucket_count = 1 << sub_bucket_count_magnitude;
            
            sub_bucket_half_count_magnitude = sub_bucket_count_magnitude - 1;
            sub_bucket_half_count = sub_bucket_count / 2;
            unit_magnitude = (int) (Math.log(lowest_discernible_value) / Math.log(2));

            leading_zero_count_base = 64 - unit_magnitude - sub_bucket_count_magnitude;
            
            sub_bucket_mask = ((int64)sub_bucket_count - 1) << unit_magnitude;

            establish_size(highest_trackable_value);

            percentile_iterator = new PercentileIterator(this, 1);
            recorded_values_iterator = new RecordedValuesIterator(this);            
        }

        public bool record_value(int64 value) {
            try {
                record_single_value(value);
                return true;
            } catch {
                return false;
            }
        }

        public void record_single_value(int64 value) throws HdrError {
            var counts_index = counts_array_index(value);
            try {
                increment_count_at_index(counts_index);
            } catch (HdrError.INDEX_OUT_OF_BOUNDS e) {
                handle_record_exception(1, value, e);
            }

            update_min_and_max(value);
            increment_total_count();
        }


        /**
         * Control whether or not the histogram can auto-resize and auto-adjust its
         * highest_trackable_value
         * 
         * @param auto_resize auto_resize setting
         */
        public void set_auto_resize(bool auto_resize) {
            this.auto_resize = auto_resize;
        }

        internal void update_min_and_max(int64 value) {
            if (value > max_value) {
                updated_max_value(value);
            }
            if ((value < min_non_zero_value) && (value != 0)) {
                update_min_non_zero_value(value);
            }
        }

        /**
         * Set internally tracked max_value to new value if new value is greater than current one.
         * May be overridden by subclasses for synchronization or atomicity purposes.
         * @param value new max_value to set
         */
        private void updated_max_value(int64 value) {
            int64 internal_value = value | unit_magnitude_mask; // Max unit-equivalent value
            max_value = internal_value;
        }

        private void reset_max_value(int64 max_value) {
            this.max_value = max_value | unit_magnitude_mask; // Max unit-equivalent value
        }

        private void reset_min_non_zero_value(int64 min_non_zero_value) {
            int64 internal_value = min_non_zero_value & ~unit_magnitude_mask; // Min unit-equivalent value
            this.min_non_zero_value = (min_non_zero_value == int64.MAX) ? min_non_zero_value : internal_value;
        }

        private void handle_record_exception(int64 count, int64 value, HdrError e) throws HdrError.INDEX_OUT_OF_BOUNDS {
            if (!auto_resize) {
                throw new HdrError.INDEX_OUT_OF_BOUNDS(@"value $value outside of histogram covered range. Caused by: " + e.message);
            }
            resize(value);
            int counts_index = counts_array_index(value);
            add_to_count_at_index(counts_index, count);
            highest_trackable_value = highest_equivalent_value(value_from_index(counts_array_length - 1));
        }
        
        protected int counts_array_index(int64 value) {
            var bucket_index = this.get_bucket_index(value);
            var sub_bucket_index = this.get_sub_bucket_index(value, bucket_index);
            return this.counts_array_index_from_bucket(bucket_index, sub_bucket_index);
        }


        private int counts_array_index_from_bucket(int bucket_index, int sub_bucket_index) {
            //  assert(subBucketIndex < subBucketCount);
            //  assert(bucketIndex == 0 || (subBucketIndex >= subBucketHalfCount));
            // Calculate the index for the first entry that will be used in the bucket (halfway through subBucketCount).
            // For bucketIndex 0, all subBucketCount entries may be used, but bucketBaseIndex is still set in the middle.
            int bucket_base_index = (bucket_index + 1) << sub_bucket_half_count_magnitude;
            // Calculate the offset in the bucket. This subtraction will result in a positive value in all buckets except
            // the 0th bucket (since a value in that bucket may be less than half the bucket's 0 to subBucketCount range).
            // However, this works out since we give bucket 0 twice as much space.
            int offset_in_bucket = sub_bucket_index - sub_bucket_half_count;
            // The following is the equivalent of ((subBucketIndex  - subBucketHalfCount) + bucketBaseIndex;
            return bucket_base_index + offset_in_bucket;
        }

        /**
         * The buckets (each of which has sub_bucket_count sub-buckets, here assumed to be 2048 as an example) overlap:
         *
         * <pre>
         * The 0'th bucket covers from 0...2047 in multiples of 1, using all 2048 sub-buckets
         * The 1'th bucket covers from 2048..4097 in multiples of 2, using only the top 1024 sub-buckets
         * The 2'th bucket covers from 4096..8191 in multiple of 4, using only the top 1024 sub-buckets
         * ...
         * </pre>
         *
         * Bucket 0 is "special" here. It is the only one that has 2048 entries. All the rest have 1024 entries (because
         * their bottom half overlaps with and is already covered by the all of the previous buckets put together). In other
         * words, the k'th bucket could represent 0 * 2^k to 2048 * 2^k in 2048 buckets with 2^k precision, but the midpoint
         * of 1024 * 2^k = 2048 * 2^(k-1) = the k-1'th bucket's end, so we would use the previous bucket for those lower
         * values as it has better precision.
         */        
        internal void establish_size(int64 new_highest_trackable_value) {
            // establish counts array length:
            counts_array_length = determine_array_length_needed(new_highest_trackable_value);
            // establish exponent range needed to support the trackable value with no overflow:
            bucket_count = get_buckets_needed_to_cover_value(new_highest_trackable_value);
            // establish the new highest trackable value:
            highest_trackable_value = new_highest_trackable_value;
        }

        internal int determine_array_length_needed(int64 highest_trackable_value) {
            //determine counts array length needed:
            int counts_array_length = get_length_for_number_of_buckets(get_buckets_needed_to_cover_value(highest_trackable_value));
            return counts_array_length;
        }

        internal int get_length_for_number_of_buckets(int number_of_buckets) {
            int length_needed = (number_of_buckets + 1) * (sub_bucket_half_count);
            return length_needed;
        }

        internal int get_buckets_needed_to_cover_value(int64 value) {
            // Shift won't overflow because subBucketMagnitude + unitMagnitude <= 62.
            // the k'th bucket can express from 0 * 2^k to subBucketCount * 2^k in units of 2^k
            int64 smallest_untrackable_value = ((int64) sub_bucket_count) << unit_magnitude;

            // always have at least 1 bucket
            int buckets_needed = 1;
            while (smallest_untrackable_value <= value) {
                if (smallest_untrackable_value > (int64.MAX / 2)) {
                    // next shift will overflow, meaning that bucket could represent values up to ones greater than
                    // Long.MAX_VALUE, so it's the last bucket
                    return buckets_needed + 1;
                }
                smallest_untrackable_value <<= 1;
                buckets_needed++;
            }
            return buckets_needed;
        }

        internal int get_bucket_index(int64 value) {
             return this.leading_zero_count_base - Int64.number_of_leading_zeros(value | sub_bucket_mask);
        }

        internal int get_sub_bucket_index(int64 value, int bucket_index) {
             return (int) (uint) (value >> (bucket_index + unit_magnitude));
        }

        internal int normalize_index(int index, int normalizing_index_offset, int array_length) {
            if (normalizing_index_offset == 0) {
                // Fastpath out of normalization. Keeps integer value histograms fast while allowing
                // others (like DoubleHistogram) to use normalization at a cost...
                return index;
            }
            if ((index > array_length) || (index < 0)) {
                //throw new ArrayIndexOutOfBoundsException("index out of covered value range");
            }
            int normalized_index = index - normalizing_index_offset;
            // The following is the same as an unsigned remainder operation, as int64 as no double wrapping happens
            // (which shouldn't happen, as normalization is never supposed to wrap, since it would have overflowed
            // or underflowed before it did). This (the + and - tests) seems to be faster than a % op with a
            // correcting if < 0...:
            if (normalized_index < 0) {
                normalized_index += array_length;
            } else if (normalized_index >= array_length) {
                normalized_index -= array_length;
            }
            return normalized_index;
        }

        /**
         * Get a value that lies in the middle (rounded up) of the range of values equivalent the given value.
         * Where "equivalent" means that value samples recorded for any two
         * equivalent values are counted in a common total count.
         *
         * @param value The given value
         * @return The value lies in the middle (rounded up) of the range of values equivalent the given value.
         */
        public int64 median_equivalent_value(int64 value) {
            return (lowest_equivalent_value(value) + (size_of_equivalent_value_range(value) >> 1));
        }

        /**
         * Get the highest value that is equivalent to the given value within the histogram's resolution.
         * Where "equivalent" means that value samples recorded for any two
         * equivalent values are counted in a common total count.
         *
         * @param value The given value
         * @return The highest value that is equivalent to the given value within the histogram's resolution.
         */
        public int64 highest_equivalent_value(int64 value) {
            return next_non_equivalent_value(value) - 1;
        }

        /**
         * Get the next value that is not equivalent to the given value within the histogram's resolution.
         * Where "equivalent" means that value samples recorded for any two
         * equivalent values are counted in a common total count.
         *
         * @param value The given value
         * @return The next value that is not equivalent to the given value within the histogram's resolution.
         */
        public int64 next_non_equivalent_value(int64 value) {
            return lowest_equivalent_value(value) + size_of_equivalent_value_range(value);
        }

        /**
         * Get the lowest value that is equivalent to the given value within the histogram's resolution.
         * Where "equivalent" means that value samples recorded for any two
         * equivalent values are counted in a common total count.
         *
         * @param value The given value
         * @return The lowest value that is equivalent to the given value within the histogram's resolution.
         */
        public int64 lowest_equivalent_value(int64 value) {
            int bucket_index = get_bucket_index(value);
            int sub_bucket_index = get_sub_bucket_index(value, bucket_index);
            int64 this_value_base_level = value_from_buckets_index(bucket_index, sub_bucket_index);
            return this_value_base_level;
        }

        /**
         * Get the size (in value units) of the range of values that are equivalent to the given value within the
         * histogram's resolution. Where "equivalent" means that value samples recorded for any two
         * equivalent values are counted in a common total count.
         *
         * @param value The given value
         * @return The size of the range of values equivalent to the given value.
         */
        public int64 size_of_equivalent_value_range(int64 value) {
            int bucket_index = get_bucket_index(value);
            int64 distance_to_next_value = 1 << (unit_magnitude + bucket_index);
            return distance_to_next_value;
        }

        /**
         * Get the lowest recorded value level in the histogram. If the histogram has no recorded values,
         * the value returned is undefined.
         *
         * @return the Min value recorded in the histogram
         */
        public int64 get_min_value() {
            try {
                if ((get_count_at_index(0) > 0) || (get_total_count() == 0)) {
                    return 0;
                }
            } catch {
                return 0;
            }
            return get_min_non_zero_value();
        }

        /**
         * Get the highest recorded value level in the histogram. If the histogram has no recorded values,
         * the value returned is undefined.
         *
         * @return the Max value recorded in the histogram
         */
        public int64 get_max_value() {
            return (max_value == 0) ? 0 : highest_equivalent_value(max_value);
        }

        /**
         * Get the lowest recorded non-zero value level in the histogram. If the histogram has no recorded values,
         * the value returned is undefined.
         *
         * @return the lowest recorded non-zero value level in the histogram
         */
        public int64 get_min_non_zero_value() {
            return (min_non_zero_value == int64.MAX) ? int64.MAX : lowest_equivalent_value(min_non_zero_value);
        }

        /**
         * Get the computed mean value of all recorded values in the histogram
         *
         * @return the mean value (in value units) of the histogram data
         */
        public double get_mean() throws HdrError {
            if (get_total_count() == 0) {
                return 0.0;
            }
            recorded_values_iterator.reset();
            double total_value = 0;
            while (recorded_values_iterator.has_next()) {
                HistogramIterationValue iteration_value = recorded_values_iterator.next();
                total_value += median_equivalent_value(iteration_value.get_value_iterated_to())
                        * (double) iteration_value.get_count_at_value_iterated_to();
            }
            return (total_value * 1.0) / get_total_count();
        }

        /**
         * Get the computed standard deviation of all recorded values in the histogram
         *
         * @return the standard deviation (in value units) of the histogram data
         */
        public double get_std_deviation() throws HdrError {
            if (get_total_count() == 0) {
                return 0.0;
            }
            double mean = get_mean();
            double geometric_deviation_total = 0.0;
            recorded_values_iterator.reset();
            while (recorded_values_iterator.has_next()) {
                HistogramIterationValue iteration_value = recorded_values_iterator.next();
                double deviation = (median_equivalent_value(iteration_value.get_value_iterated_to()) * 1.0) - mean;
                geometric_deviation_total += (deviation * deviation) * iteration_value.get_count_added_in_this_iteration_step();
            }
            double std_deviation = Math.sqrt(geometric_deviation_total / get_total_count());
            return std_deviation;
        }

        /**
         * Get the value at a given percentile.
         * Returns the largest value that (100% - percentile) [+/- 1 ulp] of the overall recorded value entries
         * in the histogram are either larger than or equivalent to. Returns 0 if no recorded values exist.
         * <p>
         * Note that two values are "equivalent" in this statement if
         * {@link org.HdrHistogram.AbstractHistogram#valuesAreEquivalent} would return true.
         *
         * @param percentile  The percentile for which to return the associated value
         * @return The largest value that (100% - percentile) [+/- 1 ulp] of the overall recorded value entries
         * in the histogram are either larger than or equivalent to. Returns 0 if no recorded values exist.
         */
        public int64 get_value_at_percentile(double percentile) throws HdrError {
            // Truncate to 0..100%, and remove 1 ulp to avoid roundoff overruns into next bucket when we
            // subsequently round up to the nearest integer:
            double requested_percentile = double.min(double.max(Math.nextafter(percentile, -double.INFINITY), 0.0), 100.0);
            // derive the count at the requested percentile. We round up to nearest integer to ensure that the
            // largest value that the requested percentile of overall recorded values is <= is actually included.
            double fp_count_at_percentile = (requested_percentile * get_total_count()) / 100.0;
            int64 count_at_percentile = (int64)(Math.ceil(fp_count_at_percentile)); // round up

            count_at_percentile = int64.max(count_at_percentile, 1); // Make sure we at least reach the first recorded entry
            int64 total_to_current_index = 0;
            for (int i = 0; i < counts_array_length; i++) {
                total_to_current_index += get_count_at_index(i);
                if (total_to_current_index >= count_at_percentile) {
                    int64 value_at_index = value_from_index(i);
                    return (percentile == 0.0) ?
                            lowest_equivalent_value(value_at_index) :
                            highest_equivalent_value(value_at_index);
                }
            }
            return 0;
        }

        /**
         * Get the percentile at a given value.
         * The percentile returned is the percentile of values recorded in the histogram that are smaller
         * than or equivalent to the given value.
         * <p>
         * Note that two values are "equivalent" in this statement if
         * {@link org.HdrHistogram.AbstractHistogram#valuesAreEquivalent} would return true.
         *
         * @param value The value for which to return the associated percentile
         * @return The percentile of values recorded in the histogram that are smaller than or equivalent
         * to the given value.
         */
        public double get_percentile_at_or_below_value(int64 value) throws HdrError {
            if (get_total_count() == 0) {
                return 100.0;
            }
            int target_index = int.min(counts_array_index(value), (counts_array_length - 1));
            int64 total_to_current_index = 0;
            for (int i = 0; i <= target_index; i++) {
                total_to_current_index += get_count_at_index(i);
            }
            return (100.0 * total_to_current_index) / get_total_count();
        }

        /**
         * Get the count of recorded values within a range of value levels (inclusive to within the histogram's resolution).
         *
         * @param low_value  The lower value bound on the range for which
         *                  to provide the recorded count. Will be rounded down with
         *                  {@link Histogram#lowest_equivalent_value lowest_equivalent_value}.
         * @param high_value  The higher value bound on the range for which to provide the recorded count.
         *                   Will be rounded up with {@link Histogram#highest_equivalent_value highest_equivalent_value}.
         * @return the total count of values recorded in the histogram within the value range that is
         * {@literal >=} lowest_equivalent_value(<i>low_value</i>) and {@literal <=} highest_equivalent_value(<i>high_value</i>)
         */
        public int64 get_count_between_values(int64 low_value, int64 high_value) throws HdrError.INDEX_OUT_OF_BOUNDS {
            int lowIndex = int.max(0, counts_array_index(low_value));
            int highIndex = int.min(counts_array_index(high_value), (counts_array_length - 1));
            int64 count = 0;
            for (int i = lowIndex ; i <= highIndex; i++) {
                count += get_count_at_index(i);
            }
            return count;
        }

        /**
         * Get the count of recorded values at a specific value (to within the histogram resolution at the value level).
         *
         * @param value The value for which to provide the recorded count
         * @return The total count of values recorded in the histogram within the value range that is
         * {@literal >=} lowest_equivalent_value(<i>value</i>) and {@literal <=} highest_equivalent_value(<i>value</i>)
         */
        public int64 getCountAtValue(int64 value) throws HdrError.INDEX_OUT_OF_BOUNDS {
            int index = int.min(int.max(0, counts_array_index(value)), (counts_array_length - 1));
            return get_count_at_index(index);
        }

        internal int64 value_from_index(int index) {
            int bucket_index = (index >> sub_bucket_half_count_magnitude) - 1;
            int sub_bucket_index = (index & (sub_bucket_half_count - 1)) + sub_bucket_half_count;
            if (bucket_index < 0) {
                sub_bucket_index -= sub_bucket_half_count;
                bucket_index = 0;
            }
            return value_from_buckets_index(bucket_index, sub_bucket_index);
        }

        public void reset() {
            clear_counts();
            reset_max_value(0);
            reset_min_non_zero_value(int64.MAX);
            set_normalizing_index_offset(0);
            start_time_stamp_msec = int64.MAX;
            end_time_stamp_msec = 0;
            tag = null;
        }

        private int64 value_from_buckets_index(int bucket_index, int sub_bucket_index) {
            return ((int64) sub_bucket_index) << (bucket_index + unit_magnitude);
        }

        /**
         * Set internally tracked min_non_zero_value to new value if new value is smaller than current one.
         * May be overridden by subclasses for synchronization or atomicity purposes.
         * @param value new min_non_zero_value to set
         */        
        private void update_min_non_zero_value(int64 value) {
            if (value <= unit_magnitude_mask) {
                return; // Unit-equivalent to 0.
            }
            
            int64 internal_value = value & ~unit_magnitude_mask; // Min unit-equivalent value
            min_non_zero_value = internal_value;
        }

        /**
         * get the start time stamp [optionally] stored with this histogram
         * @return the start time stamp [optionally] stored with this histogram
         */
        public int64 get_start_time_stamp() {
            return start_time_stamp_msec;
        }

        /**
         * Set the start time stamp value associated with this histogram to a given value.
         * @param time_stamp_msec the value to set the time stamp to, [by convention] in msec since the epoch.
         */
        public void set_start_time_stamp(int64 time_stamp_msec) {
            start_time_stamp_msec = time_stamp_msec;
        }

        /**
         * get the end time stamp [optionally] stored with this histogram
         * @return the end time stamp [optionally] stored with this histogram
         */
        public int64 get_end_time_stamp() {
            return end_time_stamp_msec;
        }

        /**
         * Set the end time stamp value associated with this histogram to a given value.
         * @param timeStampMsec the value to set the time stamp to, [by convention] in msec since the epoch.
         */
        public void set_end_time_stamp(int64 time_stamp_msec) {
            end_time_stamp_msec = time_stamp_msec;
        }

        /**
         * get the tag string [optionally] associated with this histogram
         * @return tag string [optionally] associated with this histogram
         */
        public string get_tag() {
            return tag;
        }

        /**
         * Set the tag string associated with this histogram
         * @param tag the tag string to assciate with this histogram
         */
        public void set_tag(string tag) {
            this.tag = tag;
        }
        
         /**
         * Produce textual representation of the value distribution of histogram data by percentile. The distribution is
         * output with exponentially increasing resolution, with each exponentially decreasing half-distance containing
         * <i>dumpTicksPerHalf</i> percentile reporting tick points.
         *
         * @param print_stream    Stream into which the distribution will be output
         * <p>
         * @param percentile_ticks_per_half_distance  The number of reporting points per exponentially decreasing half-distance
         * <p>
         * @param output_value_unit_scaling_ratio    The scaling factor by which to divide histogram recorded values units in
         *                                     output
         * @param use_csv_format  Output in CSV format if true. Otherwise use plain text form.
         */
        public void output_percentile_distribution(FileStream print_stream, int percentile_ticks_per_half_distance = 5, double output_value_unit_scaling_ratio = 1, bool use_csv_format = false) {

            if (use_csv_format) {
                print_stream.printf("\"Value\",\"Percentile\",\"TotalCount\",\"1/(1-Percentile)\"\n");
            } else {
                print_stream.printf("%12s %14s %10s %14s\n\n", "Value", "Percentile", "TotalCount", "1/(1-Percentile)");
            }

            PercentileIterator iterator = percentile_iterator;
            iterator.reset(percentile_ticks_per_half_distance);

            string percentile_format_string;
            string last_linepercentile_format_string;
            if (use_csv_format) {
                percentile_format_string = "%." + number_of_significant_value_digits.to_string() + "f,%.12f,%d,%.2f\n";
                last_linepercentile_format_string = "%." + number_of_significant_value_digits.to_string() + "f,%.12f,%d,Infinity\n";
            } else {
                percentile_format_string = "%12." + number_of_significant_value_digits.to_string() + "f %2.12f %10d %14.2f\n";
                last_linepercentile_format_string = "%12." + number_of_significant_value_digits.to_string() + "f %2.12f %10d\n";
            }

            while (iterator.has_next()) {
                HistogramIterationValue iteration_value = iterator.next();
                if (iteration_value.get_percentile_level_iterated_to() != 100.0D) {
                    print_stream.printf(percentile_format_string,
                            iteration_value.get_value_iterated_to() / output_value_unit_scaling_ratio,
                            iteration_value.get_percentile_level_iterated_to()/100.0D,
                            iteration_value.get_total_count_to_this_value(),
                            1/(1.0D - (iteration_value.get_percentile_level_iterated_to()/100.0D)) );
                } else {
                    print_stream.printf(last_linepercentile_format_string,
                            iteration_value.get_value_iterated_to() / output_value_unit_scaling_ratio,
                            iteration_value.get_percentile_level_iterated_to()/100.0D,
                            iteration_value.get_total_count_to_this_value());
                }
            }

            if (!use_csv_format) {
                // Calculate and output mean and std. deviation.
                // Note: mean/std. deviation numbers are very often completely irrelevant when
                // data is extremely non-normal in distribution (e.g. in cases of strong multi-modal
                // response time distribution associated with GC pauses). However, reporting these numbers
                // can be very useful for contrasting with the detailed percentile distribution
                // reported by outputPercentileDistribution(). It is not at all surprising to find
                // percentile distributions where results fall many tens or even hundreds of standard
                // deviations away from the mean - such results simply indicate that the data sampled
                // exhibits a very non-normal distribution, highlighting situations for which the std.
                // deviation metric is a useless indicator.
                //

                double mean =  get_mean() / output_value_unit_scaling_ratio;
                double std_deviation = get_std_deviation() / output_value_unit_scaling_ratio;
                print_stream.printf("#[Mean    = %12." + number_of_significant_value_digits.to_string() + "f, StdDeviation   = %12." +
                                number_of_significant_value_digits.to_string() +"f]\n",
                        mean, std_deviation);
                print_stream.printf(
                        "#[Max     = %12." + number_of_significant_value_digits.to_string() + "f, Total count    = %12d]\n",
                        get_max_value() / output_value_unit_scaling_ratio, get_total_count());
                print_stream.printf("#[Buckets = %12d, SubBuckets     = %12d]\n",
                        bucket_count, sub_bucket_count);
            }
        }
        private const int ENCODING_HEADER_SIZE = 40;
        private const int V2EncodingCookieBase = 0x1c849303;
        private  const int V2CompressedEncodingCookieBase = 0x1c849304;
        private const int V2maxWordSizeInBytes = 9; // LEB128-64b9B + ZigZag require up to 9 bytes per word

        private int get_encoding_cookie() {
            return V2EncodingCookieBase | 0x10; // LSBit of wordsize byte indicates TLZE Encoding
        }

        private int get_compressed_encoding_cookie() {
            return V2CompressedEncodingCookieBase | 0x10; // LSBit of wordsize byte indicates TLZE Encoding
        }

        public ByteArray encode_into_byte_buffer() {
            int64 max_value = get_max_value();
            int relevant_length = counts_array_index(max_value) + 1;
            
            ByteArrayWriter writer = new ByteArrayWriter(ByteOrder.BIG_ENDIAN);

            var payload_buffer = create_bytes_from_counts_array();

            writer.put_int32(get_encoding_cookie());
            writer.put_int32((int) payload_buffer.len);
            writer.put_int32(get_normalizing_index_offset());
            writer.put_int32(number_of_significant_value_digits);
            writer.put_int64(lowest_discernible_value);
            writer.put_int64(highest_trackable_value);
            writer.put_double(get_integer_to_double_value_conversion_ratio());
            writer.put_byte_array(payload_buffer);

            return writer.to_byte_array();
        }

        /**
         * Encode this histogram in compressed form into a byte array
         * @param target_buffer The buffer to encode into
         * @param compression_level Compression level -1 default, 0-9
         * @return ByteArray the buffer
         */
        public ByteArray encode_into_compressed_byte_buffer(int compression_level = -1) {
            int needed_capacity = get_needed_byte_buffer_capacity();

            var uncompressed_byte_array = encode_into_byte_buffer();
    
            ByteArrayWriter writer = new ByteArrayWriter(ByteOrder.BIG_ENDIAN);
            
            var compressed_array = Zlib.compress(uncompressed_byte_array.data); 

            writer.put_int32(get_compressed_encoding_cookie());

            writer.put_int32(compressed_array.length);
            writer.put_bytes(compressed_array);

            return writer.to_byte_array();
        }

        public string encode() {
            ByteArray buffer = encode_into_byte_buffer();
            return Base64.encode((uchar[]) buffer.data);
        }

        public string encode_compressed(int compression_level = -1) {
            ByteArray buffer = encode_into_compressed_byte_buffer(compression_level);
            return Base64.encode((uchar[]) buffer.data);
        }

        internal ByteArray create_bytes_from_counts_array() {
            int counts_limit = counts_array_index(max_value) + 1;
            int src_index = 0;
            
            var encoder = new ZigZag.Encoder();

            while (src_index < counts_limit) {
                // V2 encoding format uses a ZigZag LEB128-64b9B encoded int64. Positive values are counts,
                // while negative values indicate a repeat zero counts.
                int64 count = get_count_at_index(src_index++);
                if (count < 0) {
                    //  throw new RuntimeException("Cannot encode histogram containing negative counts (" +
                    //          count + ") at index " + src_index + ", corresponding the value range [" +
                    //          lowestEquivalentValue(valueFromIndex(src_index)) + "," +
                    //          nextNonEquivalentValue(valueFromIndex(src_index)) + ")");
                }
                // Count trailing 0s (which follow this count):
                int64 zeros_count = 0;
                if (count == 0) {
                    zeros_count = 1;
                    while ((src_index < counts_limit) && (get_count_at_index(src_index) == 0)) {
                        zeros_count++;
                        src_index++;
                    }
                }
                if (zeros_count > 1) {
                    encoder.encode_int64(-zeros_count);
                } else {
                    encoder.encode_int64(count);
                }
            }

            return encoder.to_byte_array();
        }

        /**
         * Get the capacity needed to encode this histogram into a ByteBuffer
         * @return the capacity needed to encode this histogram into a ByteBuffer
         */
        public int get_needed_byte_buffer_capacity() {
            return get_relevant_needed_byte_buffer_capacity(counts_array_length);
        }


        internal int get_relevant_needed_byte_buffer_capacity(int relevant_length) {
            return get_needed_payload_byte_buffer_capacity(relevant_length) + AbstractHistogram.ENCODING_HEADER_SIZE;
        }

        internal int get_needed_payload_byte_buffer_capacity(int relevant_length) {
            return (relevant_length * AbstractHistogram.V2maxWordSizeInBytes);
        }        
    }

     /**
     * An {@link java.lang.Iterable}{@literal <}{@link HistogramIterationValue}{@literal >} through
     * the histogram using a {@link PercentileIterator}
     */
    public class Percentiles : Iterable<HistogramIterationValue> {
        internal AbstractHistogram histogram;
        internal int percentile_ticks_per_half_distance;

        private Percentiles(AbstractHistogram histogram, int percentile_ticks_per_half_distance) {
            this.histogram = histogram;
            this.percentile_ticks_per_half_distance = percentile_ticks_per_half_distance;
        }

        /**
         * @return A {@link PercentileIterator}{@literal <}{@link HistogramIterationValue}{@literal >}
         */
         public Iterator<HistogramIterationValue> iterator() {
            return new PercentileIterator(histogram, percentile_ticks_per_half_distance);
        }
    }
}