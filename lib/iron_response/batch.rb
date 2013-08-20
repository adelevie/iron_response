require "iron_cache"
require "iron_worker_ng"
require "aws/s3"
require "json"

module IronResponse
  class Batch
    attr_accessor :config
    attr_accessor :worker
    attr_accessor :params_array
    attr_accessor :results

    def initialize(config)
      @config = config
      @client = IronWorkerNG::Client.new(@config[:iron_io])
    end

    def worker_name
      @worker.split("/").last.split(".rb").first
    end

    def worker_language
      is_ruby 
    end

    def run!
      task_ids = params_array.map do |params|
        params[:config] = @config
        @client.tasks.create(worker_name, params)._id
      end

      task_ids.map do |task_id|
        p "Fetching response for IronWorker task #{task_id}"
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
      response    = bucket[path]

      IronResponse::Common.handle_response(response, task_id, @client)
    end

    def get_iron_cache_response(task_id)
      cache_client = IronCache::Client.new(@config[:iron_io])
      cache_name   = IronResponse::Common.iron_cache_cache_name(@config)
      cache        = cache_client.cache(cache_name)
      
      key          = IronResponse::Common.iron_cache_key(task_id)
      response     = cache.get(key)

      IronResponse::Common.handle_response(response, task_id, @client)
    end

    def runtime
      return "ruby" if @worker.end_with?(".rb")
      return "node" if @worker.end_with?(".js")
    end

    def prepare_ruby_code(code)
      code.runtime = "ruby"
    end

    def prepare_node_code(code)
      code.runtime = "node"
      code.dir     = "node_modules"
      code.file    = "package.json"
    end

    def code
      if @code.nil?
        @code = IronWorkerNG::Code::Ruby.new(exec: @worker)
        @code.name = worker_name
        @code.merge_gem("iron_response", IronResponse::VERSION) # bootstraps the current version with the worker

        case runtime
        when "ruby"
          prepare_ruby_code(@code)
        when "node"
          prepare_node_code(@code)
        end
      end

      @code
    end

    def patch_code!
      @client.codes.patch(code)
    end

    def create_code!(options={})
      @client.codes.create(code, options)
    end
  end
end