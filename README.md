# iron_response

Provides a response object for IronWorkers.

```ruby
require "iron_response"

config = {...}
batch = IronResponse::Batch.new

batch.auto_update_worker = true
batch.config[:iron_io]   = config[:iron_io]
batch.config[:aws_s3]    = config[:aws_s3]
batch.worker             = "test/workers/is_prime.rb"
batch.params_array       = Array(1..10).map {|i| {number: i}}

results                  = batch.run!

p results
#=> [{"result"=>false}, {"result"=>true}, {"result"=>true}...]
```

Assumes you have a worker file called `is_prime.rb`:
```ruby
require "iron_response"

IronResponse::Responder.new(binding) do
  def is_prime?(n)
    ("1" * n =~ /^1?$|^(11+?)\1+$/) == 0 ? false : true
  end

  {
   result: is_prime?(params[:number])
  }
end
```

## Rationale

Iron.io's IronWorker is a great product that provides a lot of powerful concurrency options. With IronWorker, you can scale tasks to hundreds and even thousands of workers. However, IronWorker was missing one useful feature for me: responses. What do I mean? In the typical IronWorker setup, worker files are just one-off scripts that run independently of the client that queues them up. For example:

```ruby
client = IronWorkerNG::Client.new
100.times do |i|
  client.tasks.create("do_something", number: i)
end
```

For many use cases, this is fine. But what if I want to know the result of `do_something`? A simple way to get the result would be for your worker to POST the final result somewhere, then have the client it. This gem simply abstracts that process away, allowing the developer to avoid boilerplate and to keep worker code elegant.

Under the hood, `iron_response` uses some functional and meta-programming to capture the final expression of a worker file, convert it to JSON, and then POST it to Amazon S3. When all the workers in an `IronResponse::Batch` have finished, the gem retrieves the file and converts the JSON string back to Ruby.

This process means there a few important implications:

- Response objects "sent" from workers should be JSON-parseable. This means sticking to basic Ruby objects and data structures such as `String`, `Fixnum`, `Hash`, and `Array`.
- The these objects must be parseable, they can be fairly large. Though I haven't figured out exactly what the limit if any actually is, you really are only contrained by IronWorkers RAM and HD limits, and the bandwidth between the client (your computer), IronWorker servers, and S3. 

One final gotcha: I haven't yet implemented a clean way to use the `iron_worker_ng` gem to declare dependencies. This should be done soon, though.

## Usage

This gem requires a basic understanding of how to use [IronWorker with Ruby](https://github.com/iron-io/iron_worker_ruby_ng).

Assuming you have an empy directory, called `foo`:

```sh
$ mkdir workers
$ cd workers
$ touch my_worker.rb
```

`my_worker.rb` should look like this:

```ruby
require "iron_response"

IronResponse::Responder.new(binding) do
  # your code here
end
```

To run this worker, create at the top-level of `foo` fileds called `configuration.rb` and `enqueue.rb`:

`configuration.rb`:
```ruby
class Configuration
  def self.keys
    {
      iron_io: {
        token:      "123",
        project_id: "123"
      },
      aws_s3: {
        access_key_id:     "123",
        secret_access_key: "123",
        bucket:            "iron_response"
      }
    }
  end
end
```

Obviously, fill in the appropriate API keys. It is highly recommended that you do not use your AWS master keys. Instead, go to the AWS Console, click on "IAM", and create a user with a policy that allows it to edit the bucket named in the configuration file. Here's an example policy:

```json
{
  "Statement": [
    {
      "Action": "s3:*",
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::iron_response",
        "arn:aws:s3:::iron_response/*"
      ]
    }
  ]
}
```

Now, write your queueing script:

`enqueue.rb`:
```ruby
require_relative "configuration"
require "iron_response"

config = Configuration.keys
batch = IronResponse::Batch.new

batch.auto_update_worker = true
batch.config             = config
batch.worker             = "workers/my_worker.rb"

# The `params_array` is an Array of Hashes 
# that get sent as the payload to IronWorker scripts.
batch.params_array       = Array ("a".."z").map {|i| {letter: i}}

results                  = batch.run!
```

## Installation

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
