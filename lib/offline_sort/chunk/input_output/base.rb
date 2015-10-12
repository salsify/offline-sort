module OfflineSort
  module Chunk
    module InputOutput
      class Base
        attr_reader :io

        def initialize(io)
          @io = io
        end

        def read_entry
          Marshal.load(io)
        end

        def write_entry(entry)
          io.write(Marshal.dump(entry))
          io.flush
        end
      end
    end
  end
end

