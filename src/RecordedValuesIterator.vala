namespace HdrHistogram {
    /**
     * Used for iterating through all recorded histogram values using the finest granularity steps supported by the
     * underlying representation. The iteration steps through all non-zero recorded value counts, and terminates when
     * all recorded histogram values are exhausted.
     */
    
    public class RecordedValuesIterator : AbstractHistogramIterator, Iterator<HistogramIterationValue> {
        internal int visited_index;
    
        /**
         * @param histogram The histogram this iterator will operate on
         */
        public RecordedValuesIterator(AbstractHistogram histogram) {
            reset_histogram(histogram);
        }
        /**
         * Reset iterator for re-use in a fresh iteration over the same histogram data set.
         */
        public void reset() {
            reset_histogram(histogram);
        }
    
        private void reset_histogram(AbstractHistogram histogram) {
            base.reset_iterator(histogram);
            visited_index = -1;
        }
        
        internal override void increment_iteration_level() {
            visited_index = current_index;
        }
    
        internal override bool reached_iteration_level() throws HdrError {
            int64 current_count = histogram.get_count_at_index(current_index);
            return (current_count != 0) && (visited_index != current_index);
        }
    }
}