module IronResponse
  module Common
    S3_PATH = "tasks"

    DEFAULT_S3_BUCKET = "iron_response"
    DEFAULT_IRON_CACHE_CACHE_NAME = "iron_response"

    def Common.s3_path(task_id)
      "#{S3_PATH}/#{task_id}.json"
    end

    def Common.s3_bucket_name(config)
      config[:aws_s3][:bucket].nil? ? DEFAULT_S3_BUCKET : @config[:aws_s3][:bucket]
    end

    def Common.iron_cache_key(task_id)
      task_id
    end

    def Common.iron_cache_cache_name(config)
      config[:iron_io][:cache].nil? ? DEFAULT_IRON_CACHE_CACHE_NAME : @config[:iron_io][:cache]
    end

    def Common.response_provider(config)
      config[:aws_s3].nil? ? :iron_cache : :aws_s3
    end

    def Common.handle_response(response, task_id, client)
      if response.nil?
        msg = client.tasks_log(task_id)
        IronResponse::Error.new("IronWorker error: #{msg}")
      else 
        JSON.parse(response.value)
      end
    end
  end
end