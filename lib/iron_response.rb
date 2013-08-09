require "iron_response/version"
require "iron_worker_ng"

module IronResponse
  class Responder
    def initialize(&block)
      send_data_to_s3(block.call)
    end

    def send_data_to_s3(data)
      p "pretending to send #{data} to s3"
    end
  end
end