project('HdrHistogram_vala', ['vala', 'c'], version: '0.1')

cc = meson.get_compiler('c')
libm = cc.find_library('m', required: true)

glib = dependency('glib-2.0')
gobject = dependency('gobject-2.0')
gio = dependency('gio-2.0')

vala_args = []

if get_option('debug') == true
  vala_args += ['--ccode', '--debug']
endif

deps = [libm, glib, gobject, gio]

subdir('src')
subdir('tests')
