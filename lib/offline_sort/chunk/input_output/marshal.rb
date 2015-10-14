module OfflineSort
  module Chunk
    module InputOutput
      class Marshal < OfflineSort::Chunk::InputOutput::Base
        def read_entry
          ::Marshal.load(io)
        end

        def write_entry(entry)
          io.write(::Marshal.dump(entry))
        end
      end
    end
  end
end
