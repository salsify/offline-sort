# frozen_string_literal: true

module OfflineSort
  module Chunk
    module InputOutput

      class Base
        MethodNotImplementedError = Class.new(StandardError)

        attr_reader :io

        def initialize(io)
          @io = io
        end

        def read_entry
          raise MethodNotImplementedError.new("#{__method__} must be overridden by #{self.class}")
        end

        def write_entry(_entry)
          raise MethodNotImplementedError.new("#{__method__} must be overridden by #{self.class}")
        end

        def write_entries(entries)
          entries.each { |entry| write_entry(entry) }
        end

        def flush
          io.flush
        end

        def rewind
          flush
          io.rewind
        end

        def close
          io.close
        end

        def each
          Enumerator.new do |yielder|
            loop do
              yielder.yield(read_entry)
            rescue EOFError
              break
            end
          end
        end
      end

    end
  end
end
