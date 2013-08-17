require "aws/s3"
require "iron_cache"
require "json"

module IronResponse
  class Worker
    def initialize(binding, &block)
      task_id = eval("@iron_task_id", binding)
      params  = eval("params", binding)
      @config = params[:config]

      case IronResponse::Common.response_provider(@config)
      when :iron_cache
        send_data_to_iron_cache(params, task_id, block.call)
      when :aws_s3
        send_data_to_s3(params, task_id, block.call)
      end
    end

    def send_data_to_iron_cache(params, task_id, data)
      cache_client = IronCache::Client.new(@config[:iron_io])
      cache_name   = IronResponse::Common.iron_cache_cache_name(@config)
      cache        = cache_client.cache(cache_name)

      key   = IronResponse::Common.iron_cache_key(task_id)
      value = data.to_json

      cache.put(key, value)
    end

    def send_data_to_s3(params, task_id, data)
      aws_s3 = @config[:aws_s3]
      AWS::S3::Base.establish_connection! access_key_id:     aws_s3[:access_key_id],
                                          secret_access_key: aws_s3[:secret_access_key]
      
      path        = IronResponse::Common.s3_path(task_id)
      bucket_name = IronResponse::Common.s3_bucket_name(@config)
      value       = data.to_json

      AWS::S3::S3Object.store(path, value, bucket_name)
    end
  end
end