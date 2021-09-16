# frozen_string_literal: true

require 'msgpack'
require 'offline_sort/chunk/input_output/base'

module OfflineSort
  module Chunk
    module InputOutput
      class MessagePack < OfflineSort::Chunk::InputOutput::Base
        attr_reader :packer, :unpacker

        def initialize(io)
          super
          @packer = ::MessagePack::Packer.new(io)
          @unpacker = ::MessagePack::Unpacker.new(io)
        end

        def read_entry
          unpacker.read
        end

        def write_entry(entry)
          packer.write(entry)
        end

        def flush
          packer.flush
          super
        end
      end
    end
  end
end

