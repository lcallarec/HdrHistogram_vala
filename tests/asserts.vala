using HdrHistogram;

delegate void NotThrowFunc() throws Error;
void assert_not_throw(NotThrowFunc func) {
    try {
        func();
    } catch {
        assert_not_reached();
    }
}

void assert_same_histograms(AbstractHistogram _h1, AbstractHistogram _h2) {
    var h1 = _h1;  
    var h2 = _h2;     
    switch (Type.from_instance(_h1).name()) {
        case "HdrHistogramHistogram":
            h1 = (Histogram) _h1;       
        break;

        case "HdrHistogramInt32Histogram":
            h1 = (Int32Histogram) _h1;
            break;

        case "HdrHistogramInt16Histogram":
            h1 = (Int16Histogram) _h1;
            break;

        case "HdrHistogramInt8Histogram":
            h1 = (Int8Histogram) _h1;
            break;
    }
  
    switch (Type.from_instance(_h2).name()) {
        case "HdrHistogramHistogram":
            h2 = (Histogram) _h2;       
        break;

        case "HdrHistogramInt32Histogram":
            h2 = (Int32Histogram) _h2;
            break;

        case "HdrHistogramInt16Histogram":
            h2 = (Int16Histogram) _h2;
            break;

        case "HdrHistogramInt8Histogram":
            h2 = (Int8Histogram) _h2;
            break;
    }

    assert(h1.get_value_at_percentile(25) == h2.get_value_at_percentile(25));
    assert(h1.get_value_at_percentile(90) == h2.get_value_at_percentile(90));
    assert(h1.get_value_at_percentile(99) == h2.get_value_at_percentile(99));
    assert(h1.get_value_at_percentile(99.9) == h2.get_value_at_percentile(99.9));
    assert(h1.get_total_count() == h2.get_total_count());
    try {
        assert(h1.encode_compressed() == h2.encode_compressed());
    } catch (HdrError e) {
        assert_not_reached();
    }
}