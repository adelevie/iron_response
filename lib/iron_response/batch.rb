require "iron_cache"
require "iron_worker_ng"
require "aws/s3"
require "json"

module IronResponse
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
        params[:config] = @config
        @client.tasks.create(worker_name, params)._id
      end

      task_ids.map do |task_id|
        get_response_from_task_id(@client.tasks.wait_for(task_id)._id)
      end
    end

    def get_response_from_task_id(task_id)
      case IronResponse::Common.response_provider(@config)
      when :iron_cache
        get_iron_cache_response(task_id)
      when :aws_s3
        get_aws_s3_response(task_id)
      end
    end

    def get_aws_s3_response(task_id)
      aws_s3 = @config[:aws_s3]
      AWS::S3::Base.establish_connection! access_key_id:     aws_s3[:access_key_id],
                                          secret_access_key: aws_s3[:secret_access_key]

      bucket_name = IronResponse::Common.s3_bucket_name(@config)
      bucket      = AWS::S3::Bucket.find(bucket_name)
      path        = IronResponse::Common.s3_path(task_id)
      response    = bucket[path].value

      JSON.parse(response)
    end

    def get_iron_cache_response(task_id)
      cache_client = IronCache::Client.new(@config[:iron_io])
      cache_name   = IronResponse::Common.iron_cache_cache_name(@config)
      cache        = cache_client.cache(cache_name)

      key   = IronResponse::Common.iron_cache_key(task_id)
      value = cache.get(key).value

      JSON.parse(value)
    end

    def code
      if @code.nil?
        @code = IronWorkerNG::Code::Ruby.new(exec: @worker)
        @code.name = worker_name
        @code.merge_gem("iron_response", IronResponse::VERSION) # bootstraps the current version with the worker
        @code.runtime = "ruby"
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