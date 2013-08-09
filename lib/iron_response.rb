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

    def self.batch_queue(worker_name, params_array, client)
      pids = params_array.map do |params|
        client.tasks.create(worker_name, params)._id
      end

      pids.map do |pid|
        client.tasks.wait_for(pid)
        get_response_for_pid(pid)
      end
    end

    def get_response_for_pid(pid)
      # fetch from Amazon S3
    end

  end
end