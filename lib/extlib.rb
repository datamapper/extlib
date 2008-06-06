require 'pathname'
require 'rubygems'

# for Pathname /
require File.expand_path(File.join(File.dirname(__FILE__), 'extlib', 'pathname'))

dir = Pathname(__FILE__).dirname.expand_path / 'extlib'

require dir / 'blank'
require dir / 'inflection'
require dir / 'lazy_array'
require dir / 'object'
require dir / 'blank'
require dir / 'pooling'
require dir / 'string'
require dir / 'struct'
require dir / 'plug'
