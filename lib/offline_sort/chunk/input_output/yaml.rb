require 'yaml'

module OfflineSort
  module Chunk
    module InputOutput
      class Yaml < OfflineSort::Chunk::InputOutput::Base
        def read_entry
          line = io.gets

          raise EOFError if line.nil?

          sio = StringIO.new
          sio.write(line)
          line = io.gets
          until line.nil? || line.start_with?('---')
            sio.write(line)
            line = io.gets
          end

          io.seek(io.pos - line.length, IO::SEEK_SET) if !line.nil? && line.start_with?('---')
          YAML.load(sio.string)
        end

        def write_entry(entry)
          doc = YAML.dump(entry)
          io.write(doc)
          io.flush
        end
      end
    end
  end
end

