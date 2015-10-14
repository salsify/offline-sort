require 'pqueue'
require 'offline_sort/chunk'

module OfflineSort
  def self.sort(*args, &sort_by)
    Sorter.new(*args, &sort_by).sort
  end

  class Sorter
    DEFAULT_CHUNK_IO_CLASS = defined?(::MessagePack) ? Chunk::InputOutput::MessagePack : Chunk::InputOutput::Marshal
    DEFAULT_CHUNK_SIZE = 1000

    attr_reader :enumerable, :sort_by, :chunk_size, :chunk_input_output_class

    def initialize(enumerable, chunk_input_output_class: DEFAULT_CHUNK_IO_CLASS, chunk_size: DEFAULT_CHUNK_SIZE, &sort_by)
      @enumerable = enumerable
      @chunk_input_output_class = chunk_input_output_class
      @chunk_size = chunk_size
      @sort_by = sort_by
    end

    def sort
      merge(split)
    end

    private

    #TODO optimization for when there is less than a single full chunk of data
    def merge(sorted_chunk_ios)
      pq = PQueue.new { |x, y| -(sort_by.call(x.data) <=> sort_by.call(y.data)) }

      chunk_enumerators = sorted_chunk_ios.map(&:each)

      chunk_enumerators.each_with_index do |chunk, index|
        entry = chunk.next
        pq.push(ChunkEntry.new(index, entry))
      end

      Enumerator.new do |yielder|
        while item = pq.pop
          yielder.yield(item.data)

          begin
            entry = chunk_enumerators[item.chunk_number].next
            pq.push(ChunkEntry.new(item.chunk_number, entry))
          rescue StopIteration
            sorted_chunk_ios[item.chunk_number].close
          end
        end
      end
    end

    def split
      sorted_chunks = []
      chunk_entries = []

      enumerable.each do |entry|
        chunk_entries << entry

        if chunk_entries.size == chunk_size
          sorted_chunks << write_sorted_chunk(chunk_entries)
          chunk_entries.clear
        end
      end

      unless chunk_entries.empty?
        sorted_chunks << write_sorted_chunk(chunk_entries)
      end

      sorted_chunks
    end

    def write_sorted_chunk(entries)
      file = Tempfile.open('sort-chunk-')
      file.binmode

      chunk_io = chunk_input_output_class.new(file)
      entries.sort_by(&sort_by).each { |entry| chunk_io.write_entry(entry) }

      chunk_io.rewind
      chunk_io
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
