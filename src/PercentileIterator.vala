namespace HdrHistogram {
    /**
     * Used for iterating through histogram values according to percentile levels. The iteration is
     * performed in steps that start at 0% and reduce their distance to 100% according to the
     * <i>percentile_ticks_per_half_distance</i> parameter, ultimately reaching 100% when all recorded histogram
     * values are exhausted.
    */
    public class PercentileIterator : AbstractHistogramIterator {
        internal int percentile_ticks_per_half_distance;
        internal double percentile_level_to_iterate_to;
        internal double percentile_level_to_iterate_from;
        internal bool reached_last_recorded_value;

        /**
         * Reset iterator for re-use in a fresh iteration over the same histogram data set.
         *
         * @param percentile_ticks_per_half_distance The number of iteration steps per half-distance to 100%.
         */
        public void reset(int percentile_ticks_per_half_distance) {
            reset_histogram(histogram, percentile_ticks_per_half_distance);
        }

        private void reset_histogram(AbstractHistogram histogram, int percentile_ticks_per_half_distance) {
            base.reset_iterator(histogram);
            this.percentile_ticks_per_half_distance = percentile_ticks_per_half_distance;
            this.percentile_level_to_iterate_to = 0.0;
            this.percentile_level_to_iterate_from = 0.0;
            this.reached_last_recorded_value = false;
        }

        /**
         * @param histogram The histogram this iterator will operate on
         * @param percentile_ticks_per_half_distance The number of equal-sized iteration steps per half-distance to 100%.
         */
        public PercentileIterator(AbstractHistogram histogram, int percentile_ticks_per_half_distance) {
            reset_histogram(histogram, percentile_ticks_per_half_distance);
        }

        public bool has_next() throws HdrError {
            if (base.has_next())
                return true;
            // We want one additional last step to 100%
            if (!reached_last_recorded_value && (array_total_count > 0)) {
                percentile_level_to_iterate_to = 100.0;
                reached_last_recorded_value = true;
                return true;
            }
            return false;
        }

        internal override void increment_iteration_level() {
            percentile_level_to_iterate_from = percentile_level_to_iterate_to;

            // The choice to maintain fixed-sized "ticks" in each half-distance to 100% [starting
            // from 0%], as opposed to a "tick" size that varies with each interval, was made to
            // make the steps easily comprehensible and readable to humans. The resulting percentile
            // steps are much easier to browse through in a percentile distribution output, for example.
            //
            // We calculate the number of equal-sized "ticks" that the 0-100 range will be divided
            // by at the current scale. The scale is detemined by the percentile level we are
            // iterating to. The following math determines the tick size for the current scale,
            // and maintain a fixed tick size for the remaining "half the distance to 100%"
            // [from either 0% or from the previous half-distance]. When that half-distance is
            // crossed, the scale changes and the tick size is effectively cut in half.
            int64 percentile_reporting_ticks = percentile_ticks_per_half_distance * 
                (int64) Math.pow(2, (int64) (Math.log(100.0 / (100.0 - (percentile_level_to_iterate_to))) / Math.log(2)) + 1);
            percentile_level_to_iterate_to += 100.0 / percentile_reporting_ticks;
        }

        internal override bool reached_iteration_level() {
            if (count_at_this_value == 0)
                return false;
            double current_percentile = (100.0 * (double) total_count_to_current_index) / array_total_count;
            return (current_percentile >= percentile_level_to_iterate_to);
        }

        public override double get_percentile_iterated_to() {
           return percentile_level_to_iterate_to;
        }   
  
        public double get_percentile_iterated_from() {
           return percentile_level_to_iterate_from;
        }            
    }
}