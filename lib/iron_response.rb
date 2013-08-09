require "iron_response/version"
require "iron_worker_ng"
require "aws/s3"

module IronResponse
  class Responder
    def initialize(&block)
      send_data_to_s3(block.call)
    end

    def send_data_to_s3(data)
      p "pretending to send #{data} to s3"
    end
  end

  class Batch
    attr_accessor :config
    attr_accessor :worker
    attr_accessor :params_array
    attr_accessor :auto_update_worker

    def initialize
      @config = {}
    end

    def worker_name
      @worker.split("/").last
    end

    def run!
      @client = IronWorkerNG::Client.new(@config[:iron_io])

      if @auto_update_worker
        create_code!
      end

      pids = params_array.map do |params|
        params[:aws_s3] = @config[:aws_s3]
        @client.tasks.create(worker_name, params)._id
      end

      pids.map do |pid|
        get_response_from_pid(@client.tasks.wait_for(pid)._id)
      end
    end

    def get_response_from_pid(pid)
      bucket = @config[:aws_s3][:bucket]
      path = 
      "FakeResponseFromPid:#{pid}"
    end

    def create_code!
      code = IronWorkerNG::Code::Ruby.new(exec: @worker)
      code.name(worker_name)
      code.gem("iron_response")
      @client.codes.create(code)
      #@client.codes.patch(code)
    end
  end
end