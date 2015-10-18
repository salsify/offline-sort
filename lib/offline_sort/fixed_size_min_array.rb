module OfflineSort
  class FixedSizeMinArray
    attr_accessor :array
    attr_reader :sort_by
    attr_reader :size_limit
    attr_reader :array_end

    def initialize(array, &sort_by)
      @array = array
      @sort_by = sort_by
      @size_limit = array.size
      @end = array.size - 1
      sort_ascending!
    end

    def push(item)
      grow
      array[array_end] = item
      insert!
    end

    def pop
      item = array[array_end]
      shrink unless item.nil?
      item
    end

    private

    def shrink
      array[array_end] = nil
      @array_end -= 1
    end

    def grow
      raise "Heap Size (#{limit}) Exceeded" if array_end == (size_limit - 1)
      @array_end += 1
    end

    # Compare elements at the supplied indices
    def compare(i,j)
      (sort_by.call(array[i].data) <=> sort_by.call(array[j].data)) == -1
    end

    # Swap elements in the array
    def swap(i,j)
      #TODO does this allocate arrays?
      array[i], array[j] = array[j], array[i]
    end

    def sort_ascending!
      array.sort_by! { |item| sort_by.call(item.data) }
      array.reverse!
    end

    def insert!
      return unless array_end > 0

      item_index = array_end
      (item_index - 1).downto(0).each do |i|
        if compare(i,item_index)
          swap(i,item_index)
          item_index = i
        else
          break
        end
      end
    end
  end
end
