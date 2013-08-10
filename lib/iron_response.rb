require "iron_response/version"
require "iron_worker_ng"
require "aws/s3"
require "json"

module IronResponse
  module Protocol
    S3_PATH = "tasks"

    def Protocol.s3_path(task_id)
      "#{S3_PATH}/#{task_id}.json"
    end
  end

  class Responder
    def initialize(binding, &block)
      task_id = eval("@iron_task_id", binding)
      params  = eval("params", binding)
      send_data_to_s3(params, task_id, block.call)
    end

    def send_data_to_s3(params, task_id, data)
      aws_s3 = params[:aws_s3]
      AWS::S3::Base.establish_connection! access_key_id:     aws_s3[:access_key_id],
                                          secret_access_key: aws_s3[:secret_access_key]
      path = IronResponse::Protocol.s3_path(task_id)
      bucket_name = params[:aws_s3][:bucket]
      AWS::S3::S3Object.store(path, data.to_json, bucket_name)
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
      @worker.split("/").last.split(".rb").first
    end

    def run!
      @client = IronWorkerNG::Client.new(@config[:iron_io])

      if @auto_update_worker
        create_code!
      end

      task_ids = params_array.map do |params|
        params[:aws_s3] = @config[:aws_s3]
        @client.tasks.create(worker_name, params)._id
      end

      task_ids.map do |task_id|
        get_response_from_task_id(@client.tasks.wait_for(task_id)._id)
      end
    end

    def get_response_from_task_id(task_id)
      aws_s3 = @config[:aws_s3]
      AWS::S3::Base.establish_connection! access_key_id:     aws_s3[:access_key_id],
                                          secret_access_key: aws_s3[:secret_access_key]

      bucket_name = @config[:aws_s3][:bucket]
      bucket      = AWS::S3::Bucket.find(bucket_name)
      path        = IronResponse::Protocol.s3_path(task_id)
      response    = bucket[path].value

      JSON.parse(response)
    end

    def code
      @code ||= IronWorkerNG::Code::Ruby.new(exec: @worker).tap do |c|
        c.name = worker_name
        c.merge_gem("iron_response")
        c.runtime = "ruby"
      end

      @code
    end

    def patch_code!
      @client.codes.patch(code)
    end

    def create_code!
      @client.codes.create(code)
    end
  end
end