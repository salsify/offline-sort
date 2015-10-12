require 'spec_helper'

describe OfflineSort::OfflineSort do
  let(:count) { 1000 }
  let(:entries_per_chunk) { count / 100 }

  let(:arrays) do
    count.times.map do |index|
      [SecureRandom.hex, index, SecureRandom.hex]
    end
  end

  let(:array_sort_index) { 2 }
  let(:array_sort) { Proc.new { |arr| arr[array_sort_index] } }

  let(:hashes) do
    count.times do |index|
      { a: SecureRandom.hex, b: index, c: SecureRandom.hex }
    end
  end

  let(:hash_sort_key) { :c }
  let(:hash_sort) { Proc.new { |hash| hash[hash_sort_key] } }

  let(:input) { }
  let(:sort) { }

  before do
    @sorted = []
    osort = OfflineSort::OfflineSort.new(input.each, chunk_size: entries_per_chunk)
    osort.sort(&sort).each do |entry|
      @sorted << entry
    end
    @sorted
  end

  context "with arrays" do
    let(:input) { arrays.each }
    let(:sort) { array_sort }

    specify do
      expect(@sorted).to match_array(arrays.sort_by(&sort))
    end

    context "with multiple sort keys" do
      let(:sort) { Proc.new { |arr| [arr[0], arr[1]] } }
      let(:arrays) do
        count.times.map do |index|
          [index.round(-1), index, SecureRandom.hex]
        end.shuffle
      end

      specify do
        expect(@sorted).to match_array(arrays.sort_by(&sort))
      end
    end
  end

  context "hashes" do
    let(:input) { hashes.each }
    let(:sort) { hash_sort }

    specify do
      expect(@sorted).to match_array(hashes.sort_by(&sort))
    end

    context "with multiple sort keys" do
      let(:sort) { Proc.new { |hash| [hash[:a], hash[:c]] } }
      let(:hashes) do
        count.times.map do |index|
          { a: index.round(-1), b: index, c: SecureRandom.hex }
        end.shuffle
      end

      specify do
        expect(@sorted).to match_array(hashes.sort_by(&sort))
      end
    end
  end
end

