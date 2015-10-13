require 'pqueue'
require 'offline_sort/chunk'

module OfflineSort
  class OfflineSort
    DEFAULT_CHUNK_IO_CLASS = ::OfflineSort::Chunk::InputOutput::Base
    DEFAULT_CHUNK_SIZE = 1000

    attr_reader :input, :sort_by, :chunk_size

    def initialize(input, chunk_input_output_class: DEFAULT_CHUNK_IO_CLASS, chunk_size: DEFAULT_CHUNK_SIZE)
      @input = input
      @chunks = []
      @chunk_input_output_class = chunk_input_output_class
      @chunk_size = chunk_size
    end

    def sort(&sort_by)
      @sort_by = sort_by
      merge(split)
    end

    private

    #TODO optimization for when there is less than a single full chunk of data
    def merge(chunks)
      pq = PQueue.new { |x, y| (@sort_by.call(x.data) <=> @sort_by.call(y.data)) == -1 }

      chunks.each_with_index do |chunk, index|
        entry = chunk.next
        pq.push(ChunkEntry.new(index, entry))
      end

      Enumerator.new do |yielder|
        while item = pq.pop
          yielder.yield(item.data)

          begin
            entry = chunks[item.chunk_number].next
            pq.push(ChunkEntry.new(item.chunk_number, entry))
          rescue StopIteration
            chunks[item.chunk_number].io.close
          end
        end
      end
    end

    def split
      chunks = []
      chunk_entries = []

      input.each do |entry|
        chunk_entries << entry

        if chunk_entries.count == chunk_size
          chunks << write_chunk(chunk_entries)
          chunk_entries.clear
        end
      end

      unless chunk_entries.empty?
        chunks << write_chunk(chunk_entries)
        chunk_entries.clear
      end

      chunks
    end

    def write_chunk(entries)
      file = Tempfile.open('sort-chunk-', encoding: 'utf-8')
      file.binmode

      chunk_io = @chunk_input_output_class.new(file)
      entries.sort_by(&@sort_by).each { |entry| chunk_io.write_entry(entry) }

      file.flush
      file.rewind

      enumerate_chunk(chunk_io)
    end

    def enumerate_chunk(chunk_io)
      Enumerator.new do |yielder|
        while true
          begin
            yielder.yield(chunk_io.read_entry)
          rescue EOFError
            break
          end
        end
      end
    end

    class ChunkEntry
      attr_reader :chunk_number, :data

      def initialize(chunk_number, data)
        @chunk_number = chunk_number
        @data = data
      end
    end
  end
end
