namespace HdrHistogram { 

    /**
     * Used for iterating through histogram values.
     */
    public abstract class AbstractHistogramIterator : Iterator<HistogramIterationValue> {
        internal AbstractHistogram histogram;
        internal int64 array_total_count;

        internal int current_index;
        internal int64 current_value_at_index;

        internal int64 next_value_at_index;

        internal int64 prev_value_iterated_to;
        internal int64 total_count_to_prev_index;

        internal int64 total_count_to_current_index;
        internal int64 total_value_to_current_index;

        internal int64 count_at_this_value;

        private bool fresh_sub_bucket;
        
        internal HistogramIterationValue current_iteration_value = new HistogramIterationValue();

        private double integer_to_double_value_conversion_ratio;

        internal void reset_iterator(AbstractHistogram histogram) {
            this.histogram = histogram;
            array_total_count = histogram.get_total_count();
            integer_to_double_value_conversion_ratio = histogram.get_integer_to_double_value_conversion_ratio();
            current_index = 0;
            current_value_at_index = 0;
            next_value_at_index = 1 << histogram.unit_magnitude;
            prev_value_iterated_to = 0;
            total_count_to_prev_index = 0;
            total_count_to_current_index = 0;
            total_value_to_current_index = 0;
            count_at_this_value = 0;
            fresh_sub_bucket = true;
            current_iteration_value.reset();
        }

        /**
         * Returns true if the iteration has more elements. (In other words, returns true if next would return an
         * element rather than throwing an exception.)
         *
         * @return true if the iterator has more elements.
         */
        public override bool has_next() {
            if (histogram.get_total_count() != array_total_count) {
                //throw new HdrError.CONCURRENT_MODIFICATION_EXCEPTION("In AbstractHistogramIterator.has_next() histogram.get_total_count() != array_total_count");
                return false;
            }
            return (total_count_to_current_index < array_total_count);
        }

        /**
         * Returns the next element in the iteration.
         *
         * @return the {@link HistogramIterationValue} associated with the next element in the iteration.
         */
        public override HistogramIterationValue next() {
            // Move through the sub buckets and buckets until we hit the next reporting level:
            while (!exhausted_sub_buckets()) {
                count_at_this_value = histogram.get_count_at_index(current_index);
                if (fresh_sub_bucket) { // Don't add unless we've incremented since last bucket...
                    total_count_to_current_index += count_at_this_value;
                    total_value_to_current_index += count_at_this_value * histogram.highest_equivalent_value(current_value_at_index);
                    fresh_sub_bucket = false;
                }
                if (reached_iteration_level()) {
                    int64 value_iterated_to = get_value_iterated_to();

                    current_iteration_value.set(
                        value_iterated_to,
                        prev_value_iterated_to,
                        count_at_this_value,
                        (total_count_to_current_index - total_count_to_prev_index),
                        total_count_to_current_index,
                        total_value_to_current_index,
                        ((100.0 * total_count_to_current_index) / array_total_count),
                        get_percentile_iterated_to(),
                        integer_to_double_value_conversion_ratio
                    );

                    prev_value_iterated_to = value_iterated_to;
                    
                    total_count_to_prev_index = total_count_to_current_index;
                    // move the next iteration level forward:
                    increment_iteration_level();
                    //  if (histogram.get_total_count() != array_total_count) {
                    //      throw new HdrError.CONCURRENT_MODIFICATION_EXCEPTION("In AbstractHistogramIterator.next() histogram.get_total_count() != array_total_count");
                    //  }
                    return current_iteration_value;
                }
                increment_sub_bucket();
            }
            assert_not_reached();
            // Should not reach here. But possible for concurrent modification or overflowed histograms
            // under certain conditions
            //  if ((histogram.get_total_count() != array_total_count) ||
            //      (total_count_to_current_index > array_total_count)) {
            //      throw new HdrError.CONCURRENT_MODIFICATION_EXCEPTION("In AbstractHistogramIterator.has_next() histogram.get_total_count() != array_total_count");
            //  }
            //  throw new HdrError.NO_SUCH_ELEMENT("In AbstractHistogramIterator.next()");
        }

        /**
         * Not supported. Will throw an {@link UnsupportedOperationException}.
         */
        public override void remove() {
            assert_not_reached();
        }

        internal abstract void increment_iteration_level();

        /**
         * @return true if the current position's data should be emitted by the iterator
         */
        internal abstract bool reached_iteration_level();

        internal double get_percentile_iterated_to() {
            return (100.0 * (double) total_count_to_current_index) / array_total_count;
        }

        internal double get_percentile_iterated_from() {
            return (100.0 * (double) total_count_to_prev_index) / array_total_count;
        }

        internal int64 get_value_iterated_to() {
            return histogram.highest_equivalent_value(current_value_at_index);
        }

        private bool exhausted_sub_buckets() {
            return (current_index >= histogram.counts_array_length);
        }

        internal void increment_sub_bucket() {
            fresh_sub_bucket = true;
            // Take on the next index:
            current_index++;
            current_value_at_index = histogram.value_from_index(current_index);
            // Figure out the value at the next index (used by some iterators):
            next_value_at_index = histogram.value_from_index(current_index + 1);
        }
    }
}