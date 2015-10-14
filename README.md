# offline-sort

Sort arbitrarily large collections of data with limited memory usage. Given an enumerable and a `sort_by` proc, this gem will break the input data into sorted chunks, persist the chunks, and return an `Enumerator`. Data read from this enumerator will be in its final sorted order.

The size of the chunks and the strategy for serializing and deserializing the data are configurable. The gem comes with builtin strategies for `Marshal`, `MessagePack` and `YAML`.

## Installation

Add this line to your application's Gemfile:

    gem 'offline-sort'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install offline-sort

## Usage
```ruby
  arrays = [ [4,5,6], [7,8,9], [1,2,3] ]
  
  # Create a sorted enumerator
  sorted = OfflineSort.sort(arrays, chunk_size: 1) do |array|
    array.first
  end
  
  # Stream results in sorted order
  sorted.each do |entry|
    # e.g. write to a file
  end
```

Sorting is not limited to arrays. You can anything that can be expressed in a `Enumerable#sort_by` block.

## Using MessagePack

Message pack serialization is faster than the default Ruby `Marshal` strategy. To enable message pack serialization follow these steps.

`gem install msgpack`

`require 'msgpack'`

Requiring MessagePack before you require `offline_sort` will automatically enable MessagePack serialization in the gem.

Limitations

The MessagePack serialize/deserialize process stringifies hash keys so it is important to write your sort_by in terms of string keys.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
