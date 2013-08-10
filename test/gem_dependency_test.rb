require "test_helper"

class GemDependencyTest < MiniTest::Unit::TestCase
  def test_synopsis

    config = Configuration.keys
    batch = IronResponse::Batch.new
    
    #batch.auto_update_worker = true
    
    batch.config[:iron_io]   = config[:iron_io]
    batch.config[:aws_s3]    = config[:aws_s3]
    batch.worker             = "test/workers/fcc_filings_counter.rb"

    batch.code.merge_gem("nokogiri", "< 1.6.0") # keeps the build times low
    batch.code.merge_gem("ecfs")
    batch.code.full_remote_build(true)

    batch.params_array       = [
                                "12-375", "12-268",
                                "12-238", "12-353", 
                                "13-150", "13-5", 
                                "10-71"
                                ].map { |i| {docket_number: i} } 
    
    results                  = batch.run!

    total = results.map {|r| r["length"]}.inject(:+)

    p "There are #{total} total filings in these dockets."

    assert_equal Array, results.class
    assert_equal batch.params_array.length, results.length
  end
end