require 'forwardable'

module OfflineSort
  class Merger
    extend Forwardable
    include Enumerable

    attr_reader :sorted_chunks, :sort_by

    def initialize(sorted_chunks, sort_by)
      @sorted_chunks = sorted_chunks
      @sort_by = sort_by
    end

    def_delegators :enumerator, :each

    def enumerator
      if sorted_chunks.size == 1
        sorted_chunks.first.to_enum
      else
        pq = []
        chunk_enumerators =
          sorted_chunks.each(&:open).each(&:rewind).map(&:each)

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
              sorted_chunks[item.chunk_number].close
            end
          end
        end
      end
    end

    private

    class ChunkEntry
      attr_reader :chunk_number, :data

      def initialize(chunk_number, data)
        @chunk_number = chunk_number
        @data = data
      end
    end
  end
end
