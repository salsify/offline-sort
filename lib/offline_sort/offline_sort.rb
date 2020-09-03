require 'offline_sort/chunk'
require 'offline_sort/fixed_size_min_heap'
require 'offline_sort/merger'
require 'tempfile'

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

    # Sorts the enumerable passed, maintaining a max memory of chunk size
    def sort
      chunk_entries = []
      sorted_chunks = []

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

      Merger.new(sorted_chunks, sort_by)
    end

    private

    def write_sorted_chunk(entries)
      file = Tempfile.open('sort-chunk-')
      file.binmode

      chunk_io = chunk_input_output_class.new(file)
      entries.sort_by(&sort_by).each { |entry| chunk_io.write_entry(entry) }

      chunk_io.rewind
      chunk_io
    end
  end
end
