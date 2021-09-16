# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'securerandom'
require 'benchmark'
require 'msgpack'
require 'tempfile'

require 'offline_sort'

