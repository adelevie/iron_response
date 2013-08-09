# iron_response

Provides a response object for IronWorkers.

```ruby
require "iron_response"

batch = IronResponse::Batch.new
batch.config[:aws_s3] = {
  access_key_id: 123, 
  secret_access_key: 456, 
  bucket: "iron_worker"
}
batch.config[:iron_io] = {
  project_id: "abc", 
  token: "defg"
}
batch.worker       = "path/to/worker/is_prime"
batch.params_array = [1..1000].map {|i| {number: i}}
results            = batch.run!

p results
#=> [true, true, true, false, true, false...]
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
