namespace HdrHistogram { 

    /**
     * Represents a value point iterated through in a Histogram, with associated stats.
     * <ul>
     * <li><b><code>value_iterated_to</code></b> :<br> The actual value level that was iterated to by the iterator</li>
     * <li><b><code>prevvalue_iterated_to</code></b> :<br> The actual value level that was iterated from by the iterator</li>
     * <li><b><code>count_atvalue_iterated_to</code></b> :<br> The count of recorded values in the histogram that
     * exactly match this [lowestEquivalentValue(value_iterated_to)...highestEquivalentValue(value_iterated_to)] value
     * range.</li>
     * <li><b><code>count_added_in_this_iteration_step</code></b> :<br> The count of recorded values in the histogram that
     * were added to the total_count_to_this_value (below) as a result on this iteration step. Since multiple iteration
     * steps may occur with overlapping equivalent value ranges, the count may be lower than the count found at
     * the value (e.g. multiple linear steps or percentile levels can occur within a single equivalent value range)</li>
     * <li><b><code>total_count_to_this_value</code></b> :<br> The total count of all recorded values in the histogram at
     * values equal or smaller than value_iterated_to.</li>
     * <li><b><code>total_value_to_this_value</code></b> :<br> The sum of all recorded values in the histogram at values
     * equal or smaller than value_iterated_to.</li>
     * <li><b><code>percentile</code></b> :<br> The percentile of recorded values in the histogram at values equal
     * or smaller than value_iterated_to.</li>
     * <li><b><code>percentile_level_iterated_to</code></b> :<br> The percentile level that the iterator returning this
     * HistogramIterationValue had iterated to. Generally, percentile_level_iterated_to will be equal to or smaller than
     * percentile, but the same value point can contain multiple iteration levels for some iterators. E.g. a
     * PercentileIterator can stop multiple times in the exact same value point (if the count at that value covers a
     * range of multiple percentiles in the requested percentile iteration points).</li>
     * </ul>
     */

    public class HistogramIterationValue {

        private int64 value_iterated_to;
        private int64 value_iterated_from;
        private int64 count_atvalue_iterated_to;
        private int64 count_added_in_this_iteration_step;
        private int64 total_count_to_this_value;
        private int64 total_value_to_this_value;
        private double percentile;
        private double percentile_level_iterated_to;
        private double integer_to_double_value_conversion_ratio;

        // Set is all-or-nothing to avoid the potential for accidental omission of some values...
        internal void set(
            int64 value_iterated_to,
            int64 value_iterated_from,
            int64 count_atvalue_iterated_to,
            int64 count_in_this_iteration_step,
            int64 total_count_to_this_value,
            int64 total_value_to_this_value,
            double percentile,
            double percentile_level_iterated_to,
            double integer_to_double_value_conversion_ratio
        ) {
            this.value_iterated_to = value_iterated_to;
            this.value_iterated_from = value_iterated_from;
            this.count_atvalue_iterated_to = count_atvalue_iterated_to;
            this.count_added_in_this_iteration_step = count_in_this_iteration_step;
            this.total_count_to_this_value = total_count_to_this_value;
            this.total_value_to_this_value = total_value_to_this_value;
            this.percentile = percentile;
            this.percentile_level_iterated_to = percentile_level_iterated_to;
            this.integer_to_double_value_conversion_ratio = integer_to_double_value_conversion_ratio;
        }

        internal void reset() {
            value_iterated_to = 0;
            value_iterated_from = 0;
            count_atvalue_iterated_to = 0;
            count_added_in_this_iteration_step = 0;
            total_count_to_this_value = 0;
            total_value_to_this_value = 0;
            percentile = 0.0;
            percentile_level_iterated_to = 0.0;
        }

        public string to_string() {
            return  @"value_iterated_to: $value_iterated_to ,
                      prev_value_iterated_to: $value_iterated_from ,
                    count_atvalue_iterated_to: $count_atvalue_iterated_to ,
                    count_added_in_this_iteration_step: $count_added_in_this_iteration_step ,
                    total_count_to_this_value: $total_count_to_this_value ,
                    total_value_to_this_value: $total_value_to_this_value ,
                    percentile: $percentile ,
                    percentile_level_iterated_to: $percentile_level_iterated_to";
        }

        public int64 get_value_iterated_to() {
            return value_iterated_to;
        }

        public double get_double_value_iterated_to() {
            return value_iterated_to * integer_to_double_value_conversion_ratio;
        }

        public int64 get_value_iterated_from() {
            return value_iterated_from;
        }

        public double get_double_value_iterated_from() {
            return value_iterated_from * integer_to_double_value_conversion_ratio;
        }

        public int64 get_count_at_value_iterated_to() {
            return count_atvalue_iterated_to;
        }

        public int64 get_count_added_in_this_iteration_step() {
            return count_added_in_this_iteration_step;
        }

        public int64 get_total_count_to_this_value() {
            return total_count_to_this_value;
        }

        public int64 get_total_value_to_this_value() {
            return total_value_to_this_value;
        }

        public double get_percentile() {
            return percentile;
        }

        public double get_percentile_level_iterated_to() {
            return percentile_level_iterated_to;
        }

        public double get_integer_to_double_value_conversion_ratio() {
            return integer_to_double_value_conversion_ratio;
        }
    }
}