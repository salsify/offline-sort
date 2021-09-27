# frozen_string_literal: true

require 'offline_sort/chunk/input_output/base'
require 'offline_sort/chunk/input_output/marshal'
require 'offline_sort/chunk/input_output/message_pack' if defined?(MessagePack)
require 'offline_sort/chunk/input_output/yaml'
