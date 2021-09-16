# frozen_string_literal: true

require 'spec_helper'

describe OfflineSort::FixedSizeMinHeap do
  let(:array) { (1..10).to_a.shuffle }
  let(:heap) { OfflineSort::FixedSizeMinHeap.new(array.dup) }

  describe "#initialize" do
    it "is a a heap" do
      expect { assert_min_heap(heap.array) }.not_to raise_error
    end
  end

  describe "#push" do
    context "with a full array" do
      it "raises an exception" do
        expect { heap.push(rand(20)) }.to raise_error("Heap Size (#{array.size}) Exceeded")
      end
    end

    context "with one space" do
      before do
        heap.pop
      end

      it "adds to the heap" do
        expect { heap.push(1) }.not_to raise_error
      end
    end

    context "with more than one space" do
      before do
        5.times { heap.pop }
      end

      it "adds to the heap" do
        5.times do
          expect { heap.push(1) }.not_to raise_error
        end
      end
    end
  end

  describe "#pop" do
    context "with empty array" do
      before do
        array.size.times { heap.pop }
      end

      it "is nil" do
        expect(heap.pop).to be nil
      end
    end

    context "until empty" do
      it "is sorted" do
        last = -1
        array.size.times do
          popped = heap.pop
          expect(popped).to be > (last)
          last = popped
        end
      end
    end
  end

  context "integration test" do
    it "is always heap ordered" do
      100.times do
        heap.pop
        heap.push(rand(100))
        expect { assert_min_heap(heap.array) }.not_to raise_error
      end
    end
  end

  def assert_min_heap(array)
    array.each_with_index do |e, index|
      left = (2 * index) + 1
      right = (2 * index) + 2

      if left < array.size
        unless array[left] >= e
          puts "left #{e} #{array}"
          raise 'not a heap'
        end
      end

      next unless right < array.size

      unless array[right] >= e
        puts "right #{e} #{array}"
        raise 'not a heap'
      end
    end
  end
end
