# HdrHistogram_vala

![CI](https://github.com/lcallarec/HdrHistogram_vala/workflows/CI/badge.svg) 
[![codecov](https://codecov.io/gh/lcallarec/HdrHistogram_vala/branch/master/graph/badge.svg)](https://codecov.io/gh/lcallarec/HdrHistogram_vala)
[![License](https://img.shields.io/github/license/lcallarec/HdrHistogram_vala)](https://github.com/lcallarec/HdrHistogram_vala/blob/master/LICENSE)

Gil Tene's [High Dynamic Range Histogram](https://github.com/HdrHistogram/HdrHistogram) vala implementation

Who's better than Gil Tene himself to describe what is HdrHistogram :

> HdrHistogram supports the recording and analyzing of sampled data value counts across a configurable integer value range with configurable value precision within the range. Value precision is expressed as the number of significant digits in the value recording, and provides control over value quantization behavior across the value range and the subsequent value resolution at any given level.

# API

## Create an Histogram

When creating a histogram instance, you must provide the minimum and maximum trackable values and the wanted number of precision digits. If you need to create a histogram to record latency between one millisecond and one minute `[1ms..1min]` with a precision of 0.01, use the following :


```vala
var histogram = new Hdr.Histogram(1, 60000, 2); //From 1ms to 60000ms with a precision of 2 digits, 0.01
```

Histogram can stores counters in many bucket sizes, which impacts histogram memory footprint. This library supports unsigned 8-bit, unsigned 16-bit, unsigned 32-bit and signed 64-bit histogram counters.

```vala
var histogram = new Hdr.Int8Histogram(1, 60000, 2);
var histogram = new Hdr.Int16Histogram(1, 60000, 2);
var histogram = new Hdr.Int32Histogram(1, 60000, 2);
```

## Record values

```vala
histogram.record_value(42);
```

## Statistics

### Percentils

```vala
histogram.record_value(45);
histogram.record_value(115);
histogram.record_value(198);
histogram.record_value(215);
histogram.record_value(320);
histogram.record_value(578);

histogram.get_value_at_percentile(25); //115
histogram.get_value_at_percentile(99.9); //578
```

### Min, max, mean, standard deviation

```vala
histogram.record_value(45);
histogram.record_value(115);
histogram.record_value(198);
histogram.record_value(215);
histogram.record_value(320);
histogram.record_value(578);

histogram.get_min_value(); // 45
histogram.get_max_value(); // 578

histogram.get_mean(); //245.1666666667

histogram.get_std_deviation(); // 171.523970
```

### Record counts

```vala
histogram.record_value(45);
histogram.record_value(115);
histogram.record_value(198);
histogram.record_value(215);
histogram.record_value(320);
histogram.record_value(578);

histogram.get_total_count(); // 6
```

## Dump

```vala
histogram.output_percentile_distribution(output_stream, 5, 1);
```

## Coordinated omissions

Record with coordinated omissions :

```vala
histogram.record_value_with_expected_interval(42, 5);
```

Post-processing of coordinated omissions :

```vala
var new_histogram = histogram.copy_corrected_for_coordinated_omission(5);
```

This is still WIP, ready soon !

- [x] Record value
- [x] Auto resize
- [x] Reset
- [x] Get mean
- [x] Get std deviation
- [x] Get percentiles
- [x] Output percentile distribution
- [x] Handle concurrent accesses in RecordedValuesIterator
- [x] Encode histogram
- [x] Encode & compress histogram
- [x] Decode uncompressed histograms
- [x] Decode compressed histograms
- [x] Corrected coordinated omissions
- [x] Add histograms
- [x] Substract histograms
- [x] Iterate over percentiles
- [x] Iterate RecordedValues
- [x] Tags
- [x] uint8 histogram
- [x] uint16 histogram
- [x] uint32 histogram
- [ ] Packed histogram
- [ ] Decode all kinds of histograms

Not likely to be done :
- [ ] Java AtomicLong > Vala counterpart
- [ ] Log reader
- [ ] Log writer
