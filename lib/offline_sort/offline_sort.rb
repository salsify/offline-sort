require 'offline_sort/chunk'
require 'offline_sort/fixed_size_min_heap'

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
      pq = []
      chunk_enumerators = sorted_chunk_ios.map(&:each)

      chunk_enumerators.each_with_index do |chunk, index|
        entry = chunk.next
        pq.push(ChunkEntry.new(index, entry))
      end

      #pq.sort_by! { |item| sort_by.call(item.data) }
      #pq.reverse!

      pq = FixedSizeMinHeap.new(pq, &sort_by)

      Enumerator.new do |yielder|
        while item = pq.pop
          yielder.yield(item.data)

          begin
            entry = chunk_enumerators[item.chunk_number].next
            pq.push(ChunkEntry.new(item.chunk_number, entry))
            #sort_last!(pq)
          rescue StopIteration
            sorted_chunk_ios[item.chunk_number].close
          end
        end
      end
    end

    def sort_last!(container)
      return container if container.size < 2
      key = container.last
      (container.size-2).downto(0).each do |i|
        if (sort_by.call(container[i].data) <=> sort_by.call(key.data)) == -1
          container[i+1] = container[i]
          container[i] = key
        else
          break
        end
      end
      container
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
