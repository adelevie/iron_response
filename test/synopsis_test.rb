require "test_helper"

class SynopsisTest < MiniTest::Unit::TestCase
  def test_synopsis

    config = Configuration.keys
    batch = IronResponse::Batch.new
    
    batch.auto_update_worker = true
    batch.config[:iron_io]   = config[:iron_io]
    batch.config[:aws_s3]    = config[:aws_s3]
    batch.worker             = "test/workers/is_prime.rb"
    batch.params_array       = [1,2,3].map {|i| {number: i}}#Array(1).map {|i| {number: i}}
    
    results                  = batch.run!

    p results
    assert_equal Array, results.class
  end
end