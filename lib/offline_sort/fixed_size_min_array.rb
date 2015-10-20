module OfflineSort
  class FixedSizeMinArray
    attr_accessor :array
    attr_reader :sort_by
    attr_reader :size_limit
    attr_reader :array_start

    def initialize(array, &sort_by)
      @array = array
      @sort_by = sort_by
      @size_limit = array.size
      @array_start = 0
      array.sort_by! { |item| sort_by.call(item.data) }
    end

    def push(item)
      grow
      array[array_start] = item
      insert!
    end

    def pop
      item = array[array_start]
      shrink unless item.nil?
      item
    end

    private

    def shrink
      array[array_start] = nil
      @array_start += 1
    end

    def grow
      raise "Size (#{limit}) Exceeded" if array_start == 0
      @array_start -= 1
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

    def insert!
      return unless size_limit - array_start > 1

      item_index = array_start
      (item_index + 1).upto(size_limit - 1).each do |i|
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
