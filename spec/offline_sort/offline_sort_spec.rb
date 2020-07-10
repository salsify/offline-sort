require 'spec_helper'

describe OfflineSort::Sorter do

  shared_examples "a correct offline sort" do
    let(:count) { 10000 }
    let(:entries_per_chunk) { 900 }
    let(:enumerable) {}
    let(:sort) {}
    let(:unsorted) { enumerable.dup }

    subject do
      OfflineSort.sort(enumerable, chunk_size: entries_per_chunk, &sort)
    end

    it "writes out to disk" do
      expect(Tempfile).to receive(:open).at_least(:once).and_call_original
      subject
    end

    shared_examples "produces a sorted result" do
      it "produces the same sorted result as an in-memory sort" do
        sorted = subject.to_a

        expect(unsorted).to match_array(enumerable)
        expect do
          last = nil
          entry_count = 0
          sorted.each do |entry|
            if last.nil?
              last = entry
              entry_count += 1
              next
            end

            unless (sort.call(last) <=> sort.call(entry)) == -1
              raise "Out of order at line #{entry_count}"
            end

            last = entry
            entry_count += 1
          end
        end.not_to raise_error
        expect(sorted).to match_array(enumerable.sort_by(&sort))
      end
    end

    context "when the number of entries is smaller than the chunk size" do
      let(:count) { entries_per_chunk - 1 }

      it "does not write out to disk" do
        expect(Tempfile).not_to receive(:open)
        subject
      end

      it_behaves_like "produces a sorted result"
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

