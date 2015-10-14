require 'spec_helper'

shared_examples "a valid chunk input output" do
  let(:count) { 1000 }

  let(:arrays) do
    count.times.map do |index|
      [SecureRandom.hex, index, SecureRandom.hex]
    end
  end

  let(:hashes) do
    count.times.map do |index|
      { 'a' => SecureRandom.hex, 'b' => index, 'c' => SecureRandom.hex }
    end
  end

  let(:tempfile) do
    t = Tempfile.open('chunk-input-output')
    t.binmode
    t
  end

  let(:chunk_class) { }
  let(:chunk_io) { chunk_class.new(tempfile) }

  describe "#rewind" do
    before do
      allow(chunk_io).to receive(:flush)
      allow(tempfile).to receive(:rewind)
      chunk_io.rewind
    end

    it "rewinds the io" do
      expect(tempfile).to have_received(:rewind)
    end

    it "flushes the io" do
      expect(chunk_io).to have_received(:flush)
    end
  end

  describe "#flush" do
    before do
      allow(tempfile).to receive(:flush)
      chunk_io.flush
    end

    it "flushes the io" do
      expect(tempfile).to have_received(:flush)
    end
  end

  shared_examples "a valid integration test" do
    let(:enumerable) {}

    it "writes the data and reads it back" do
      expect { chunk_io.write_entries(enumerable) }.not_to raise_error

      chunk_io.rewind

      expect(tempfile.size).not_to eq(0)
      expect(chunk_io.each.to_a).to match_array(enumerable)
    end
  end

  context "arrays" do
    it_behaves_like "a valid integration test" do
      let(:enumerable) { arrays }
    end
  end

  context "hashes" do
    it_behaves_like "a valid integration test" do
      let(:enumerable) { hashes }
    end
  end
end

describe OfflineSort::Chunk::InputOutput::Base do
  let(:io) { Tempfile.new('chunk') }
  let(:chunk_io) { OfflineSort::Chunk::InputOutput::Base.new(io) }

  describe "#read_entry" do
    it "raises when read_entry is called" do
      expect { chunk_io.read_entry }.to raise_error(OfflineSort::Chunk::InputOutput::Base::MethodNotImplementedError)
    end
  end

  describe "#write_entry" do
    it "raises when write_entry is called" do
      expect { chunk_io.write_entry({}) }.to raise_error(OfflineSort::Chunk::InputOutput::Base::MethodNotImplementedError)
    end
  end
end
