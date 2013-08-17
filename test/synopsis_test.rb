require "test_helper"

class SynopsisTest < MiniTest::Unit::TestCase
  def test_synopsis_with_s3
    config = Configuration.keys
    batch  = IronResponse::Batch.new
    
    batch.auto_update_worker = true
    batch.config[:iron_io]   = config[:iron_io]
    batch.config[:aws_s3]    = config[:aws_s3]
    batch.worker             = "test/workers/hello.rb"
    batch.params_array       = Array(1..4).map {|i| {number: i}}
    
    results                  = batch.run!

    assert_equal Array, results.class
    assert_equal batch.params_array.length, results.length
    assert_equal true, results.select {|r| r.nil?}.length == 0
  end

  def test_synopsis_with_iron_cache
    config = Configuration.keys
    batch  = IronResponse::Batch.new
    
    batch.auto_update_worker = true
    batch.config[:iron_io]   = config[:iron_io]
    batch.worker             = "test/workers/hello.rb"
    batch.params_array       = Array(1..4).map {|i| {number: i}}
    
    results                  = batch.run!

    assert_equal Array, results.class
    assert_equal batch.params_array.length, results.length
    assert_equal true, results.select {|r| r.nil?}.length == 0
  end
end