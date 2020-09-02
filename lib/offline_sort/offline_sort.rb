require 'offline_sort/chunk'
require 'offline_sort/fixed_size_min_heap'
require 'tempfile'

module OfflineSort
  def self.sort(*args, &sort_by)
    Sorter.new(*args, &sort_by).sort
  end

  class Sorter
    DEFAULT_CHUNK_IO_CLASS = defined?(::MessagePack) ? Chunk::InputOutput::MessagePack : Chunk::InputOutput::Marshal
    DEFAULT_CHUNK_SIZE = 1000

    attr_reader :enumerable, :sort_by, :chunk_size, :chunk_input_output_class, :sorted_chunks

    def initialize(enumerable, chunk_input_output_class: DEFAULT_CHUNK_IO_CLASS, chunk_size: DEFAULT_CHUNK_SIZE, &sort_by)
      @enumerable = enumerable
      @chunk_input_output_class = chunk_input_output_class
      @chunk_size = chunk_size
      @sort_by = sort_by
      @sorted_chunks = []
    end

    # Sorts the enumerable passed, maintaining a max memory of chunk size
    #
    # @param close_tempfiles [Boolean]
    #   Whether or not to close the tempfiles opened by the sort. Note if this
    #   method will be called multiple times for the same Sorter object, every
    #   time except for the last must pass close_tempfiles as false.
    #
    # @return [Enumerator] The sorted enumerable
    def sort(close_tempfiles: true)
      if sorted_chunks.empty?
        chunk_entries = []

        enumerable.each do |entry|
          chunk_entries << entry

          if chunk_entries.size == chunk_size
            sorted_chunks << write_sorted_chunk(chunk_entries)
            chunk_entries.clear
          end
        end

        unless chunk_entries.empty?
          # In this case we have less than one full chunk so don't need to write
          # out to disk
          return chunk_entries.sort_by(&sort_by).to_enum if sorted_chunks.empty?

          sorted_chunks << write_sorted_chunk(chunk_entries)
        end
      end

      merge(sorted_chunks, close_tempfiles: close_tempfiles)
    end

    # Closes any tempfiles which have been opened to sort the enumerable
    def close_tempfiles
      sorted_chunks.each { |sorted_chunk_io| sorted_chunk_io.close }
    end

    private

    def merge(sorted_chunk_ios, close_tempfiles: true)
      pq = []
      chunk_enumerators = sorted_chunk_ios.map(&:each)

      chunk_enumerators.each_with_index do |chunk, index|
        entry = chunk.next
        pq.push(ChunkEntry.new(index, entry))
      end

      entry_sort_by = Proc.new { |entry| sort_by.call(entry.data) }
      pq = FixedSizeMinHeap.new(pq, &entry_sort_by)

      Enumerator.new do |yielder|
        while item = pq.pop
          yielder.yield(item.data)

          begin
            entry = chunk_enumerators[item.chunk_number].next
            pq.push(ChunkEntry.new(item.chunk_number, entry))
          rescue StopIteration
            if close_tempfiles
              sorted_chunk_ios[item.chunk_number].close
            else
              sorted_chunk_ios[item.chunk_number].rewind
            end
          end
        end
      end
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
