# iron_response

Provides a response object for IronWorkers.

```ruby
require "iron_response"

batch = IronResponse::Batch.new

batch.auto_update_worker = true
batch.config[:iron_io]   = config[:iron_io]
batch.config[:aws_s3]    = config[:aws_s3]
batch.worker             = "test/workers/is_prime.rb"
batch.params_array       = Array(1..10).map {|i| {number: i}}

results                  = batch.run!

p results
#=> [false, true, true, false, true, false...]
```

Assumes you have a worker file called `is_prime.rb`:
```ruby
require "iron_response"

IronResponse::Responder do
  def is_prime?(n)
    ("1" * n =~ /^1?$|^(11+?)\1+$/) == 0 ? false : true
  end

  is_prime? params[:number]
end
```

## Installation

Don't install this yet. It's just a code sketch so far. Once this library works, these will be the installation instructions:

Add this line to your application's Gemfile:

```ruby
gem "iron_response"
```

And then execute:

```sh
$ bundle
```

Or install it yourself as:

```sh
$ gem install iron_response
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
