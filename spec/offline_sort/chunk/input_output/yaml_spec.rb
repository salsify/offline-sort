require 'spec_helper'

describe OfflineSort::Chunk::InputOutput::Yaml do
  it_behaves_like "a valid chunk input output" do
    let(:chunk_class) { OfflineSort::Chunk::InputOutput::Yaml }
  end
end
