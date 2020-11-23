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
- [ ] uint16 histogram
- [ ] uint32 histogram
- [ ] Real uint64 histogram (not just int64 as java version)
- [ ] Packed histogram
- [ ] Decode all kinds of histograms

Not likely to be done :
- [ ] Java AtomicLong > Vala counterpart
- [ ] Log reader
- [ ] Log writer
