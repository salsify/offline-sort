module OfflineSort
  class FixedSizeMinHeap
    attr_accessor :array
    attr_reader :sort_by
    attr_reader :size_limit
    attr_reader :heap_end

    def initialize(array, &sort_by)
      @array = array
      @sort_by = sort_by
      @size_limit = array.size
      @heap_end = array.size - 1
      ((array.size * 0.5) - 1).to_i.downto(0) { |i| heapify(i) }
    end

    def push(item)
      grow_heap
      array[heap_end] = item
      sift_up(heap_end)
    end

    def pop
      item = array[0]
      array[0] = array[heap_end]
      heapify(0)
      shrink_heap unless item.nil?
      item
    end

    private

    def shrink_heap
      array[heap_end] = nil
      @heap_end -= 1
    end

    def grow_heap
      raise "Heap Size (#{size_limit}) Exceeded" if heap_end == (size_limit - 1)
      @heap_end += 1
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

    # Get the parent of the node i > 0.
    def parent(i)
      ( i - 1 ) >> 1  # (i-1)/2, only valid iff i > 0 !!
    end
    # Get the node left of node i >= 0
    def left(i)
      ( i << 1 ) + 1  # 2i+1
    end
    # Get the node right of node i >= 0
    def right(i)
      ( i << 1 ) + 2  # 2i+2
    end

    # Keeps an heap sorted with the smallest (largest) element on top
    def heapify(i)
      l = left(i)
      top = if (l <= heap_end) && compare(l,i)
              l
            else
              i
            end

      r = right(i)
      top = if (r <= heap_end) && compare(r,top)
              r
            else
              top
            end

      if top != i
        swap(i, top)
        heapify(top)
      end
    end

    def sift_up(i)
      if i > 0 && p = parent(i)
        if compare(i,p)
          swap(i,p);
          sift_up(p)
        end
      end
    end
  end
end
