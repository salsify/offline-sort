# frozen_string_literal: true

require 'spec_helper'

describe OfflineSort::Chunk::InputOutput::MessagePack do
  it_behaves_like "a valid chunk input output" do
    let(:chunk_class) { OfflineSort::Chunk::InputOutput::MessagePack }
  end
end
