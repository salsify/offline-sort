# frozen_string_literal: true

require 'yaml'

module OfflineSort
  module Chunk
    module InputOutput
      class Yaml < OfflineSort::Chunk::InputOutput::Base
        # The yaml parser does not expose a document enumerator that we can call next on without loading the entire file
        def read_entry
          YAML.load(next_document) # rubocop:disable Security/YAMLLoad, this is loading from a trusted source
        end

        def write_entry(entry)
          io.write(YAML.dump(entry))
        end

        private

        def next_document
          sio = StringIO.new
          document_count = 0

          loop do
            line = io.gets

            if line && line.start_with?('---')
              document_count += 1
            end

            sio.write(line)
            break if line.nil? || document_count > 1
          end

          # reset the io to the beginning of the document
          if document_count > 1
            io.seek(io.pos - line.length, IO::SEEK_SET)
          end

          raise EOFError unless sio.size > 0 # rubocop:disable Style/ZeroLengthPredicate

          sio.string
        end
      end
    end
  end
end
