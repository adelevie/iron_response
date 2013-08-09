require "test_helper"

class RddTest < MiniTest::Unit::TestCase
  def test_readme

    config = Configuration.keys[:ironio]
    client = IronWorkerNG::Client.new(config)

    code = IronWorkerNG::Code::Ruby.new(:exec => "test/workers/is_prime.rb", :name => 'is_prime')
    #code.gem("iron_response")
    client.codes.create(code)

  end
end