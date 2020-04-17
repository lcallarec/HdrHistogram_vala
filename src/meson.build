
sources = files(
    'AbstractHistogram.vala',
    'Arrays.vala',
    'Histogram.vala',
    'Int64.vala'
)

hdrhistogram_static_lib = static_library('HdrHistogram', [sources], dependencies: deps, vala_args: vala_args)
hdrhistogram_dep = declare_dependency(include_directories: include_directories('.'), link_with: hdrhistogram_static_lib)
