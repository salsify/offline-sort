# frozen_string_literal: true

module OfflineSort
  module Chunk
    module InputOutput
      class Marshal < OfflineSort::Chunk::InputOutput::Base
        def read_entry
          ::Marshal.load(io) # rubocop:disable Security/MarshalLoad, this is loading from a trusted source
        end

        def write_entry(entry)
          io.write(::Marshal.dump(entry))
        end
      end
    end
  end
end
