require 'spec_helper'

shared_examples "a valid chunk input output" do
  let(:count) { 100 }

  let(:arrays) do
    count.times.map do |index|
      [SecureRandom.hex, index, SecureRandom.hex]
    end
  end

  let(:hashes) do
    count.times.map do |index|
      { a: SecureRandom.hex, b: index, c: SecureRandom.hex }
    end
  end

  let(:tempfile) do
    t = Tempfile.open('chunk-input-output')
    t.binmode
    t
  end

  let(:chunk) { }

  context "integration test" do
    context "arrays" do
      specify do
        expect { write_collection(arrays, chunk) }.not_to raise_error
        expect(tempfile.size).not_to eq(0)

        tempfile.rewind

        expect(read_collection(chunk)).to match_array(arrays)
      end
    end

    context "hashes" do
      specify do
        expect { write_collection(hashes, chunk) }.not_to raise_error
        expect(tempfile.size).not_to eq(0)

        tempfile.rewind

        expect(read_collection(chunk)).to match_array(hashes)
      end
    end
  end

  def write_collection(collection, chunk)
    collection.each { |item| chunk.write_entry(item) }
  end

  def read_collection(chunk)
    collection = []
    while true
      begin
        collection << chunk.read_entry
      rescue EOFError
        break
      end
    end
    collection
  end
end

describe OfflineSort::Chunk::InputOutput::Base do
  it_behaves_like "a valid chunk input output" do
    let(:chunk) { OfflineSort::Chunk::InputOutput::Base.new(tempfile) }
  end
end

describe OfflineSort::Chunk::InputOutput::MessagePack do
  it_behaves_like "a valid chunk input output" do
    let(:chunk) { OfflineSort::Chunk::InputOutput::Base.new(tempfile) }
  end
end

describe OfflineSort::Chunk::InputOutput::Yaml do
  it_behaves_like "a valid chunk input output" do
    let(:chunk) { OfflineSort::Chunk::InputOutput::Base.new(tempfile) }
  end
end
