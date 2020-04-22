test_sources = [
    'tests.vala',
    'Arrays.test.vala',
    'Histogram.test.vala', 
    'Int64.test.vala'
]

deps += [dependency('gio-2.0')]

test('hdr-tests', executable('hdr-tests', test_sources + sources, dependencies: deps))
