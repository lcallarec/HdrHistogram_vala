.PHONY: docs

docs:
	rm -rf docs
	valadoc src/AbstractHistogram.vala src/AbstractHistogramIterator.vala \
	src/Arrays.vala src/Bytes.vala src/Histogram.vala src/Int8Histogram.vala \
	src/Int16Histogram.vala src/Int32Histogram.vala src/HistogramIterationValue.vala \
	src/Int64.vala src/Iterable.vala src/Iterator.vala src/PercentileIterator.vala \
	src/RecordedValuesIterator.vala src/ZigZag.vala src/Zlib.vala \
	-o HdrHistogramValaDocs  --pkg=gio-2.0
	mv HdrHistogramValaDocs docs
