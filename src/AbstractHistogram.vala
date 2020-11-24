namespace HdrHistogram { 

    public errordomain HdrError {
        ILLEGAL_ARGUMENT,
        INDEX_OUT_OF_BOUNDS,
        CONCURRENT_MODIFICATION_EXCEPTION,
        NO_SUCH_ELEMENT,
        UNSUPPORTED_OPERATION,
        DECODE_NO_VALID_COOKIE,
        INTEGER_OVERFLOW
    }

    /**
     * Unlike the Java reference implementation, there's no need to separate AbstractHistogramBase 
     * from AbstractHistogram. But keeping vala implementation as much as possible in sync with reference implementation
     * helps for adding features and debugging.
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
        internal int word_size_in_bytes;

        internal int64 start_time_stamp_msec = int64.MAX;
        internal int64 end_time_stamp_msec = 0;
        internal string tag = null;

        internal double integer_to_double_value_conversion_ratio = 1.0;
        internal double double_to_integer_value_conversion_ratio = 1.0;

        internal PercentileIterator percentile_iterator;
        internal RecordedValuesIterator recorded_values_iterator;

        internal double get_integer_to_double_value_conversion_ratio() {
            return integer_to_double_value_conversion_ratio;
        }

        internal void non_concurrent_set_integer_to_double_value_conversion_ratio(double integer_to_double_value_conversion_ratio) {
            this.integer_to_double_value_conversion_ratio = integer_to_double_value_conversion_ratio;
            double_to_integer_value_conversion_ratio = 1.0/integer_to_double_value_conversion_ratio;
        }

        internal abstract void set_integer_to_double_value_conversion_ratio(double integer_to_double_value_conversion_ratio);

        /**
         * get the configured lowest_discernible_value
         * @return lowest_discernible_value
         */
        public int64 get_lowest_discernible_value() {
            return lowest_discernible_value;
        }

        /**
         * get the configured number_of_significant_value_digits
         * @return number_of_significant_value_digits
         */
        public int8 get_number_of_significant_value_digits() {
            return number_of_significant_value_digits;
        }

        /**
         * get the configured get_number_of_significant_value_digits
         * @return get_number_of_significant_value_digits
         */
        public int64 get_highest_trackable_value() {
            return highest_trackable_value;
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
         * Lowest unit_magnitude bits are set
         */
        int64 unit_magnitude_mask;  

        int64 max_value = 0;
        int64 min_non_zero_value = int64.MAX;

        // Abstract methods
        internal abstract void increment_count_at_index(int index) throws HdrError;
        internal abstract void resize(int64 new_highest_trackable_value);
        internal abstract void add_to_count_at_index(int index, int64 value) throws HdrError;
        internal abstract void increment_total_count();
        internal abstract int64 get_count_at_index(int index) throws HdrError.INDEX_OUT_OF_BOUNDS;
        internal abstract void clear_counts();
        internal abstract int get_normalizing_index_offset();
        internal abstract void set_normalizing_index_offset(int normalizing_index_offset);
        internal abstract void set_count_at_index(int index, int64 value);
        internal abstract void set_total_count(int64 totalCount);
        internal abstract void add_to_total_count(int64 value);

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
        protected AbstractHistogram(int64 lowest_discernible_value, int64 highest_trackable_value, int8 number_of_significant_value_digits) 
        {
           init(lowest_discernible_value, highest_trackable_value, number_of_significant_value_digits, 1.0, 0);
        }

        /**
         * Construct a histogram with the same range settings as a given source histogram,
         * duplicating the source's start/end timestamps (but NOT it's contents)
         * @param source The source histogram to duplicate
         */
        protected AbstractHistogram.from_source(AbstractHistogram source) {
            init(source.get_lowest_discernible_value(), source.get_highest_trackable_value(), source.get_number_of_significant_value_digits(), 1.0, 0);
            this.set_start_time_stamp(source.get_start_time_stamp());
            this.set_end_time_stamp(source.get_end_time_stamp());
            this.auto_resize = source.auto_resize;
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
            
            
            // We need to maintain power-of-two sub_bucket_count (for clean direct indexing) that is large enough to
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
            stdout.printf("counts_index = %d\n", counts_index);
            try {
                increment_count_at_index(counts_index);
            } catch (HdrError.INDEX_OUT_OF_BOUNDS e) {
                handle_record_exception(1, value, e);
            }

            update_min_and_max(value);
            increment_total_count();
        }

        private void record_count_at_value(int64 count, int64 value) throws HdrError {
            int counts_index = counts_array_index(value);
            try {
                add_to_count_at_index(counts_index, count);
            } catch (HdrError ex) { //TODO Only INDEX OUT OF BOUNDS
                handle_record_exception(count, value, ex);
            }
            update_min_and_max(value);
            add_to_total_count(count);
        }

         /**
         * Record a value in the histogram (adding to the value's current count)
         *
         * @param value The value to be recorded
         * @param count The number of occurrences of this value to record
         * @throws HdrError (may throw) if value is exceeds highest_trackable_value
         */
        public void record_value_with_count(int64 value, int64 count) throws HdrError {
            record_count_at_value(count, value);
        }

        // Coordinated omissions
         /**
         * Record a value in the histogram.
         * <p>
         * To compensate for the loss of sampled values when a recorded value is larger than the expected
         * interval between value samples, Histogram will auto-generate an additional series of decreasingly-smaller
         * (down to the expected_interval_between_value_samples) value records.
         * <p>
         * Note: This is a at-recording correction method, as opposed to the post-recording correction method provided
         * by {@link #copy_corrected_for_coordinated_omission(long)}.
         * The two methods are mutually exclusive, and only one of the two should be be used on a given data set to correct
         * for the same coordinated omission issue.
         * <p>
         * See notes in the description of the Histogram calls for an illustration of why this corrective behavior is
         * important.
         *
         * @param value The value to record
         * @param expected_interval_between_value_samples If expected_interval_between_value_samples is larger than 0, add
         *                                           auto-generated value records as appropriate if value is larger
         *                                           than expected_interval_between_value_samples
         * @throws HdrError.INDEX_OUT_OF_BOUNDS (may throw) if value is exceeds highest_trackable_value
         */
        public void record_value_with_expected_interval(int64 value, int64 expected_interval_between_value_samples) throws HdrError {
            record_single_value_with_expected_interval(value, expected_interval_between_value_samples);
        }

        private void record_value_with_count_and_expected_interval(int64 value, int64 count, int64 expected_interval_between_value_samples) throws HdrError {
            record_count_at_value(count, value);
            if (expected_interval_between_value_samples <= 0)
            return;
            for (int64 missing_value = value - expected_interval_between_value_samples;
                missing_value >= expected_interval_between_value_samples;
                missing_value -= expected_interval_between_value_samples) {
                record_count_at_value(count, missing_value);
            }
        }

        private void record_single_value_with_expected_interval(int64 value, int64 expected_interval_between_value_samples) throws HdrError {
            record_single_value(value);
            if (expected_interval_between_value_samples <= 0) {
                return;
            }
            for (int64 missing_value = value - expected_interval_between_value_samples; missing_value >= expected_interval_between_value_samples; missing_value -= expected_interval_between_value_samples) {
                record_single_value(missing_value);
            }
        }

        //ADD
         /**
     * Add the contents of another histogram to this one.
     * <p>
     * As part of adding the contents, the start/end timestamp range of this histogram will be
     * extended to include the start/end timestamp range of the other histogram.
     *
     * @param other_histogram The other histogram.
     * @throws ArrayIndexOutOfBoundsException (may throw) if values in fromHistogram's are
     * higher than highest_trackable_value.
     */
    public void add(AbstractHistogram other_histogram) throws HdrError {
        int64 highest_recordable_value = highest_equivalent_value(value_from_index(counts_array_length - 1));
        if (highest_recordable_value < other_histogram.get_max_value()) {
            if (!is_auto_resize()) {
                throw new HdrError.INDEX_OUT_OF_BOUNDS("The other histogram includes values that do not fit in this histogram's range.");
            }
            resize(other_histogram.get_max_value());
        }
        if (bucket_count == other_histogram.bucket_count &&
            sub_bucket_count == other_histogram.sub_bucket_count &&
            unit_magnitude == other_histogram.unit_magnitude &&
            get_normalizing_index_offset() == other_histogram.get_normalizing_index_offset()) {
                //&& !(other_histogram instanceof ConcurrentHistogram) ) {
            // Counts arrays are of the same length and meaning, so we can just iterate and add directly:
            int64 observed_other_total_count = 0;
            for (int i = 0; i < other_histogram.counts_array_length; i++) {
                int64 other_count = other_histogram.get_count_at_index(i);
                if (other_count > 0) {
                    add_to_count_at_index(i, other_count);
                    observed_other_total_count += other_count;
                }
            }
            set_total_count(get_total_count() + observed_other_total_count);
            updated_max_value(int64.max(get_max_value(), other_histogram.get_max_value()));
            update_min_non_zero_value(int64.min(get_min_non_zero_value(), other_histogram.get_min_non_zero_value()));
        } else {
            // Arrays are not a direct match (or the other could change on the fly in some valid way),
            // so we can't just stream through and add them. Instead, go through the array and add each
            // non-zero value found at it's proper value:

            // Do max value first, to avoid max value updates on each iteration:
            int other_max_index = other_histogram.counts_array_index(other_histogram.get_max_value());
            int64 other_count = other_histogram.get_count_at_index(other_max_index);
            record_value_with_count(other_histogram.value_from_index(other_max_index), other_count);

            // Record the remaining values, up to but not including the max value:
            for (int i = 0; i < other_max_index; i++) {
                other_count = other_histogram.get_count_at_index(i);
                if (other_count > 0) {
                    record_value_with_count(other_histogram.value_from_index(i), other_count);
                }
            }
        }
        set_start_time_stamp(int64.min(start_time_stamp_msec, other_histogram.start_time_stamp_msec));
        set_end_time_stamp(int64.max(end_time_stamp_msec, other_histogram.end_time_stamp_msec));
    }

     /**
     * Subtract the contents of another histogram from this one.
     * <p>
     * The start/end timestamps of this histogram will remain unchanged.
     *
     * @param other_histogram The other histogram.
     * @throws ArrayIndexOutOfBoundsException (may throw) if values in other_histogram's are higher than highestTrackableValue.
     *
     */
    public void subtract(AbstractHistogram other_histogram) throws HdrError {
            //TODO throws ArrayIndexOutOfBoundsException, IllegalArgumentException {
        if (highest_equivalent_value(other_histogram.get_max_value()) >
                highest_equivalent_value(value_from_index(this.counts_array_length - 1))) {
            //  TODO throw new IllegalArgumentException(
            //          "The other histogram includes values that do not fit in this histogram's range.");
        }
        for (int i = 0; i < other_histogram.counts_array_length; i++) {
            int64 other_count = other_histogram.get_count_at_index(i);
            if (other_count > 0) {
                int64 other_value = other_histogram.value_from_index(i);
                if (get_count_at_value(other_value) < other_count) {
                    //TODO throw new IllegalArgumentException("other_histogram count (" + other_count + ") at value " +
                            //other_value + " is larger than this one's (" + get_count_at_value(other_value) + ")");
                }
                record_value_with_count(other_value, -other_count);
            }
        }
        // With subtraction, the max and minNonZero values could have changed:
        if ((get_count_at_value(get_max_value()) <= 0) || get_count_at_value(get_min_non_zero_value()) <= 0) {
            establish_internal_tacking_values();
        }
    }

        /**
         * Add the contents of another histogram to this one, while correcting the incoming data for coordinated omission.
         * <p>
         * To compensate for the loss of sampled values when a recorded value is larger than the expected
         * interval between value samples, the values added will include an auto-generated additional series of
         * decreasingly-smaller (down to the expectedIntervalBetweenValueSamples) value records for each count found
         * in the current histogram that is larger than the expectedIntervalBetweenValueSamples.
         *
         * Note: This is a post-recording correction method, as opposed to the at-recording correction method provided
         * by {@link #recordValueWithExpectedInterval(int64, int64) recordValueWithExpectedInterval}. The two
         * methods are mutually exclusive, and only one of the two should be be used on a given data set to correct
        * for the same coordinated omission issue.
        * by
        * <p>
        * See notes in the description of the Histogram calls for an illustration of why this corrective behavior is
        * important.
        *
        * @param other_histogram The other histogram. highest_trackable_value and largestValueWithSingleUnitResolution must match.
        * @param expected_interval_between_value_samples If expected_interval_between_value_samples is larger than 0, add
        *                                           auto-generated value records as appropriate if value is larger
        *                                           than expected_interval_between_value_samples
        * @throws ArrayIndexOutOfBoundsException (may throw) if values exceed highest_trackable_value
        */
        public void add_while_correcting_for_coordinated_omission(AbstractHistogram other_histogram, int64 expected_interval_between_value_samples) {
            AbstractHistogram to_histogram = this;

            var recorded_values = other_histogram.recorded_values();
            recorded_values.reset();
            while (recorded_values.has_next()) {
                var recorded_value = recorded_values.next();
                to_histogram.record_value_with_count_and_expected_interval(
                    recorded_value.get_value_iterated_to(),
                    recorded_value.get_count_at_value_iterated_to(),
                    expected_interval_between_value_samples
                );
            }
        }

        /**
         * Get a copy of this histogram, corrected for coordinated omission.
         * <p>
         * To compensate for the loss of sampled values when a recorded value is larger than the expected
         * interval between value samples, the new histogram will include an auto-generated additional series of
         * decreasingly-smaller (down to the expectedIntervalBetweenValueSamples) value records for each count found
         * in the current histogram that is larger than the expectedIntervalBetweenValueSamples.
         *
         * Note: This is a post-correction method, as opposed to the at-recording correction method provided
         * by {@link #record_value_with_expected_interval(int64, int64) record_value_with_expected_interval}. The two
         * methods are mutually exclusive, and only one of the two should be be used on a given data set to correct
         * for the same coordinated omission issue.
         * by
         * <p>
         * See notes in the description of the Histogram calls for an illustration of why this corrective behavior is
         * important.
         *
         * @param expected_interval_between_value_samples If expected_interval_between_value_samples is larger than 0, add
         *                                           auto-generated value records as appropriate if value is larger
         *                                           than expected_interval_between_value_samples
         * @return a copy of this histogram, corrected for coordinated omission.
         */
        public abstract AbstractHistogram copy_corrected_for_coordinated_omission(int64 expected_interval_between_value_samples);

        public bool is_auto_resize() {
            return auto_resize;
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
            //  assert(subBucketIndex < sub_bucket_count);
            //  assert(bucketIndex == 0 || (subBucketIndex >= subBucketHalfCount));
            // Calculate the index for the first entry that will be used in the bucket (halfway through sub_bucket_count).
            // For bucketIndex 0, all sub_bucket_count entries may be used, but bucketBaseIndex is still set in the middle.
            int bucket_base_index = (bucket_index + 1) << sub_bucket_half_count_magnitude;
            // Calculate the offset in the bucket. This subtraction will result in a positive value in all buckets except
            // the 0th bucket (since a value in that bucket may be less than half the bucket's 0 to sub_bucket_count range).
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
            // Shift won't overflow because subBucketMagnitude + unit_magnitude <= 62.
            // the k'th bucket can express from 0 * 2^k to sub_bucket_count * 2^k in units of 2^k
            int64 smallest_untrackable_value = ((int64) sub_bucket_count) << unit_magnitude;

            // always have at least 1 bucket
            int buckets_needed = 1;
            while (smallest_untrackable_value <= value) {
                if (smallest_untrackable_value > (int64.MAX / 2)) {
                    // next shift will overflow, meaning that bucket could represent values up to ones greater than
                    // int64.MAX_VALUE, so it's the last bucket
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
        public int64 get_count_at_value(int64 value) throws HdrError.INDEX_OUT_OF_BOUNDS {
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
         * @param tag the tag string to associate with this histogram
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
        private const int V2CompressedEncodingCookieBase = 0x1c849304;
        private const int V2maxWordSizeInBytes = 9; // LEB128-64b9B + ZigZag require up to 9 bytes per word

        private int get_encoding_cookie() {
            return V2EncodingCookieBase | 0x10; // LSBit of wordsize byte indicates TLZE Encoding
        }

        private static int get_cookie_base(int cookie) {
            return (cookie & ~0xf0);
        }

        private static int get_word_size_in_bytes_from_cookie(int cookie) {
            if ((get_cookie_base(cookie) == V2EncodingCookieBase) ||
                    (get_cookie_base(cookie) == V2CompressedEncodingCookieBase)) {
                return V2maxWordSizeInBytes;
            }
            int size_byte = (cookie & 0xf0) >> 4;
            return size_byte & 0xe;
        }

        private int get_compressed_encoding_cookie() {
            return V2CompressedEncodingCookieBase | 0x10; // LSBit of wordsize byte indicates TLZE Encoding
        }

        public ByteArray encode_into_byte_buffer() {
            
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
                    //          lowestEquivalentValue(value_from_index(src_index)) + "," +
                    //          nextNonEquivalentValue(value_from_index(src_index)) + ")");
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

        public static AbstractHistogram decode_from_compressed_byte_buffer(ByteArray compressed_buffer, int64 min_bar_for_highest_trackable_value) {

            var reader = new ByteArrayReader(compressed_buffer, ByteOrder.BIG_ENDIAN);

            int cookie = reader.read_int32();

            int header_size;
            if (get_cookie_base(cookie) == V2CompressedEncodingCookieBase) {
                header_size = AbstractHistogram.ENCODING_HEADER_SIZE;
            } else {
                throw new HdrError.DECODE_NO_VALID_COOKIE(
                     "The buffer does not contain a Histogram (no valid cookie found)"
                );
            }
    
            int length_of_compressed_contents = reader.read_int32();
            var header_buffer = Zlib.decompress(reader.take(length_of_compressed_contents));
            
            var histogram = decode_from_byte_buffer(new ByteArray.take(header_buffer), min_bar_for_highest_trackable_value);
            
            return histogram;

        }

        public static AbstractHistogram decode_from_byte_buffer(ByteArray buffer, int64 min_bar_for_highest_trackable_value) {
            var reader = new ByteArrayReader(buffer, ByteOrder.BIG_ENDIAN);
            int cookie = reader.read_int32();
            print("cookie := %d\n", cookie);
            if (get_cookie_base(cookie) == V2EncodingCookieBase) {
                if (get_word_size_in_bytes_from_cookie(cookie) != V2maxWordSizeInBytes) {
                    throw new HdrError.DECODE_NO_VALID_COOKIE(
                        "The buffer does not contain a Histogram (no valid cookie found)"
                    );
                }
            } else {
                throw new HdrError.DECODE_NO_VALID_COOKIE("The buffer does not contain a Histogram (no valid v2Encoding cookie)");
            }

            var payload_length_in_bytes = reader.read_int32();
            var normalizing_index_offset = reader.read_int32();
            var number_of_significant_value_digits = (int8) reader.read_int32();
            var lowest_trackable_unit_value = reader.read_int64();
            var highest_trackable_value = reader.read_int64();
            var integer_to_double_value_conversion_ratio = reader.read_double();

            highest_trackable_value = int64.max(highest_trackable_value, min_bar_for_highest_trackable_value);

            AbstractHistogram histogram;

            // Construct histogram:
            histogram = new Histogram(
                lowest_trackable_unit_value,
                highest_trackable_value,
                number_of_significant_value_digits
            );
            histogram.set_integer_to_double_value_conversion_ratio(integer_to_double_value_conversion_ratio);
            histogram.set_normalizing_index_offset(normalizing_index_offset);
            
            try {
                histogram.set_auto_resize(true);
            } catch {
                // Allow histogram to refuse auto-sizing setting
            }

            int filled_length = histogram.fill_counts_array_from_source_buffer(
                reader,
                payload_length_in_bytes,
                get_word_size_in_bytes_from_cookie(cookie)
            );

            histogram.establish_internal_tacking_values(filled_length);

            return histogram;
        }

        private int fill_counts_array_from_source_buffer(ByteArrayReader reader, int length_in_bytes, int word_size_in_bytes) {
            if ((word_size_in_bytes != 2) && (word_size_in_bytes != 4) &&
                    (word_size_in_bytes != 8) && (word_size_in_bytes != V2maxWordSizeInBytes)) {
                throw new HdrError.ILLEGAL_ARGUMENT("word size must be 2, 4, 8, or V2maxWordSizeInBytes ("+
                        V2maxWordSizeInBytes.to_string() + ") bytes");
            }
            int64 max_allowable_count_in_histogram =
                    ((this.word_size_in_bytes == 2) ? int8.MAX :
                            ((this.word_size_in_bytes == 4) ? int32.MAX : int64.MAX)
                    );

            int dst_index = 0;
            int end_position = reader.position + length_in_bytes;
            var decoder = new ZigZag.Decoder.with_reader(reader);
            while (reader.position < end_position) {
                int64 count;
                int zeros_count = 0;
                
                // V2 encoding format uses a long encoded in a ZigZag LEB128 format (up to V2maxWordSizeInBytes):
                count = decoder.decode_int64();
                if (count < 0) {
                    int64 zc = -count;
                    if (zc > int32.MAX) {
                        throw new HdrError.ILLEGAL_ARGUMENT(
                                "An encoded zero count of > int32.MAX was encountered in the source");
                    }
                    zeros_count = (int) zc;
                }
              
                if (count > max_allowable_count_in_histogram) {
                    throw new HdrError.ILLEGAL_ARGUMENT(
                            "An encoded count (" + count.to_string() +
                            ") does not fit in the Histogram's (" +
                            this.word_size_in_bytes.to_string() + " bytes) was encountered in the source");
                }
                if (zeros_count > 0) {
                    dst_index += zeros_count; // No need to set zeros in array. Just skip them.
                } else {
                    set_count_at_index(dst_index++, count);
                }
            }
            return dst_index; // this is the destination length
        }

        internal void establish_internal_tacking_values(int length_to_cover = counts_array_length) {
            reset_max_value(0);
            reset_min_non_zero_value(int64.MAX);
            int max_index = -1;
            int min_non_zero_index = -1;
            int64 observed_total_count = 0;
            for (int index = 0; index < length_to_cover; index++) {
                int64 count_at_index;
                if ((count_at_index = get_count_at_index(index)) > 0) {
                    observed_total_count += count_at_index;
                    max_index = index;
                    if ((min_non_zero_index == -1) && (index != 0)) {
                        min_non_zero_index = index;
                    }
                }
            }
            if (max_index >= 0) {
                updated_max_value(highest_equivalent_value(value_from_index(max_index)));
            }
            if (min_non_zero_index >= 0) {
                update_min_non_zero_value(value_from_index(min_non_zero_index));
            }
            set_total_count(observed_total_count);
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

        /**
         * Provide a means of iterating through all recorded histogram values using the finest granularity steps
         * supported by the underlying representation. The iteration steps through all non-zero recorded value counts,
         * and terminates when all recorded histogram values are exhausted.
         *
         * @return An {@link java.lang.Iterable}{@literal <}{@link HistogramIterationValue}{@literal >}
         * through the histogram using
         * a {@link RecordedValuesIterator}
         */
        public RecordedValuesIterator recorded_values() {
            return new RecordedValuesIterator(this);
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