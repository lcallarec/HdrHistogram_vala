namespace HdrHistogram { 

    /**
     * 
     * Represents a value point iterated through in a Histogram, with associated stats.
     */

    public class HistogramIterationValue {

        private int64 value_iterated_to;
        private int64 value_iterated_from;
        private int64 count_a_value_iterated_to;
        private int64 count_added_in_this_iteration_step;
        private int64 total_count_to_this_value;
        private int64 total_value_to_this_value;
        private double percentile;
        private double percentile_level_iterated_to;

        // Set is all-or-nothing to avoid the potential for accidental omission of some values...
        internal void set(
            int64 value_iterated_to,
            int64 value_iterated_from,
            int64 count_a_value_iterated_to,
            int64 count_in_this_iteration_step,
            int64 total_count_to_this_value,
            int64 total_value_to_this_value,
            double percentile,
            double percentile_level_iterated_to
        ) {
            this.value_iterated_to = value_iterated_to;
            this.value_iterated_from = value_iterated_from;
            this.count_a_value_iterated_to = count_a_value_iterated_to;
            this.count_added_in_this_iteration_step = count_in_this_iteration_step;
            this.total_count_to_this_value = total_count_to_this_value;
            this.total_value_to_this_value = total_value_to_this_value;
            this.percentile = percentile;
            this.percentile_level_iterated_to = percentile_level_iterated_to;
        }

        internal void reset() {
            value_iterated_to = 0;
            value_iterated_from = 0;
            count_a_value_iterated_to = 0;
            count_added_in_this_iteration_step = 0;
            total_count_to_this_value = 0;
            total_value_to_this_value = 0;
            percentile = 0.0;
            percentile_level_iterated_to = 0.0;
        }

        public string to_string() {
            return  @"
                value_iterated_to:                  $value_iterated_to \n,
                prev_value_iterated_to:             $value_iterated_from \n,
                count_a_value_iterated_to:          $count_a_value_iterated_to \n,
                count_added_in_this_iteration_step: $count_added_in_this_iteration_step \n,
                total_count_to_this_value:          $total_count_to_this_value \n,
                total_value_to_this_value:          $total_value_to_this_value \n,
                percentile:                         $percentile \n,
                percentile_level_iterated_to:       $percentile_level_iterated_to \n";
        }

        public int64 get_value_iterated_to() {
            return value_iterated_to;
        }

        public int64 get_value_iterated_from() {
            return value_iterated_from;
        }

        public int64 get_count_at_value_iterated_to() {
            return count_a_value_iterated_to;
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
    }
}