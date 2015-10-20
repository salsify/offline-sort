require 'spec_helper'

describe OfflineSort::Sorter do

  shared_examples "a correct offline sort" do
    let(:count) { 1000 }
    let(:entries_per_chunk) { 90 }
    let(:enumerable) {}
    let(:sort) {}

    before do
      @unsorted = enumerable.dup
      r = Benchmark.measure do
      result = OfflineSort.sort(enumerable, chunk_size: entries_per_chunk, &sort)
      @sorted = result.map do |entry|
        entry
      end
      end
      puts r
    end

    it "produces the same sorted result as an in-memory sort" do
      expect(@unsorted).to match_array(enumerable)
      expect do
        last = nil
        entry_count = 0
        @sorted.each do |entry|
          if last.nil?
            last = entry
            entry_count += 1
            next
          end

          unless ((sort.call(last) <=> sort.call(entry)) == -1)
            raise "Out of order at line #{entry_count}"
          end

          last = entry
          entry_count += 1
        end
      end.not_to raise_error
      expect(@sorted).to match_array(enumerable.sort_by(&sort))
    end
  end

  let(:arrays) do
    count.times.map do |index|
      [SecureRandom.hex, index, SecureRandom.hex]
    end
  end

  let(:array_sort_index) { 2 }
  let(:array_sort) { Proc.new { |arr| arr[array_sort_index] } }

  let(:hashes) do
    count.times.map do |index|
      { 'a' => SecureRandom.hex, 'b' => index, 'c' => SecureRandom.hex }
    end
  end

  let(:hash_sort_key) { 'c' }
  let(:hash_sort) { Proc.new { |hash| hash[hash_sort_key] } }


  context "with arrays" do
    it_behaves_like "a correct offline sort" do
      let(:enumerable) { arrays }
      let(:sort) { array_sort }
    end

    context "with multiple sort keys" do
      it_behaves_like "a correct offline sort" do
        let(:enumerable) do
          count.times.map do |index|
            [index.round(-1), index, SecureRandom.hex]
          end.shuffle
        end
        let(:sort) { Proc.new { |arr| [arr[0], arr[1]] } }
      end
    end
  end

  context "hashes" do
    it_behaves_like "a correct offline sort" do
      let(:enumerable) { hashes }
      let(:sort) { hash_sort }
    end

    context "with multiple sort keys" do
      it_behaves_like "a correct offline sort" do
        let(:enumerable) do
          count.times.map do |index|
            { 'a' => index.round(-1), 'b' => index, 'c' => SecureRandom.hex }
          end.shuffle
        end
        let(:sort) { Proc.new { |hash| [hash['a'], hash['c']] } }
      end
    end
  end
end

