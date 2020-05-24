# HdrHistogram_vala

![CI](https://github.com/lcallarec/HdrHistogram_vala/workflows/CI/badge.svg) 
[![codecov](https://codecov.io/gh/lcallarec/HdrHistogram_vala/branch/master/graph/badge.svg)](https://codecov.io/gh/lcallarec/HdrHistogram_vala)
[![License](https://img.shields.io/github/license/lcallarec/HdrHistogram_vala)](https://github.com/lcallarec/HdrHistogram_vala/blob/master/LICENSE)

#### HdrHistogram_vala is a port of Gil Tene's HdrHistogram to native Vala

This is still WIP, ready soon !

- [x] Record value
- [x] Auto resize
- [x] Reset
- [x] Get mean
- [x] Get std deviation
- [x] Get percentiles
- [x] Output percentile distribution
- [ ] Java AtomicLong > Vala counterpart
- [x] Handle concurrent accesses in RecordedValuesIterator
- [x] Encode histogram
- [x] Encode & compress histogram
- [x] Decode uncompressed histograms
- [x] Decode compressed histograms
- [ ] Corrected coordinated omissions
- [ ] Add histograms
- [ ] Substract histograms
- [x] Iterate over percentiles
- [ ] Iterate LinearBucketValues
- [ ] Iterate LogarithmicBucketValues
- [ ] Iterate RecordedValues
- [ ] Iterate AllValues
- [ ] Log reader
- [ ] Log writer
- [ ] int8 histogram
- [ ] int16 histogram
- [ ] int32 histogram
- [ ] Packed histogram
- [ ] Decode all kinds of histogramqs
