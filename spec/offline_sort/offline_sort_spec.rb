require 'spec_helper'

# Sorting twice returns same result
# Sorting twice (or more times) only opens tempfile once
# sort in a before, and then assert that sorting again doesn't open tempfile at ALL
describe OfflineSort::Sorter do
  let(:offline_sorter_instance) do
    described_class.new(enumerable, chunk_size: entries_per_chunk, &sort)
  end

  let(:entries_per_chunk) { 900 }
  let(:count) { 10000 }
  let(:enumerable) { arrays }
  let(:sort) { array_sort }
  let(:array_sort) { Proc.new { |arr| arr[2] } }
  let(:arrays) do
    count.times.map do |index|
      [SecureRandom.hex, index, SecureRandom.hex]
    end
  end

  shared_examples "closes all tempfiles" do
    it "closes all tempfiles" do
      close_count = 0
      allow_any_instance_of(Tempfile).
        to receive(:close) { close_count += 1 }

      expected_number_of_tempfiles =
        (count.to_f / entries_per_chunk).ceil

      # The case where we don't write to disk because there's only
      # one chunk
      if expected_number_of_tempfiles == 1
        expected_number_of_tempfiles = 0
      end

      subject
      expect(close_count).to eq(expected_number_of_tempfiles)
    end
  end

  describe "#sort" do
    subject { offline_sorter_instance.sort }

    shared_examples "a correct offline sort" do
      let(:unsorted) { enumerable.dup }

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

        context "closing tempfiles" do
          subject do
            offline_sorter_instance.sort(close_tempfiles: close_tempfiles).to_a
          end

          context "when closing tempfiles" do
            let(:close_tempfiles) { true }

            it_behaves_like "closes all tempfiles"
          end

          context "when not closing tempfiles" do
            let(:close_tempfiles) { false }

            it "closes tempfiles" do
              expect_any_instance_of(Tempfile).not_to receive(:close)
              subject
            end
          end
        end

        context "when sorted twice" do
          it "produces the same result both times" do
            expect(
              offline_sorter_instance.sort(close_tempfiles: false).to_a
            ).to eq(subject.to_a)
          end

          it "only opens tempfiles once" do
            offline_sorter_instance.sort(close_tempfiles: false).to_a
            expect(Tempfile).not_to receive(:open)
            subject
          end
        end
      end

      context "when the number of entries is smaller than the chunk size" do
        let(:count) { entries_per_chunk - 1 }

        it "does not write out to disk", :focus do
          expect(Tempfile).not_to receive(:open)
          subject
        end

        it_behaves_like "produces a sorted result"
      end

      it_behaves_like "produces a sorted result"
    end

    let(:hashes) do
      count.times.map do |index|
        { 'a' => SecureRandom.hex, 'b' => index, 'c' => SecureRandom.hex }
      end
    end

    let(:hash_sort_key) { 'c' }
    let(:hash_sort) { Proc.new { |hash| hash[hash_sort_key] } }

    context "with arrays" do
      it_behaves_like "a correct offline sort"

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

  describe "#close_tempfiles" do
    before(:each) do
      offline_sorter_instance.sort(close_tempfiles: false)
    end

    subject { offline_sorter_instance.close_tempfiles }

    it_behaves_like "closes all tempfiles"
  end
end

