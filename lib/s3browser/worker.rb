require 'shoryuken'
require 's3browser/store'

module S3Browser
  class Worker
    include Shoryuken::Worker

    shoryuken_options queue: ENV['AWS_SQS_QUEUE'], body_parser: :json, auto_delete: true

    def perform(sqs_msg, body)
      if body['Records']
        body['Records'].each do |record|
          bucket = record['s3']['bucket']['name']
          key    = record['s3']['object']['key']

          info = s3.head_object({ bucket: bucket, key: key })

          info = info.to_h
          store.add bucket, info
        end
      else
        raise unless body['Event'] == 's3:TestEvent'
      end
    end

    private
    def store
      @store ||= S3Browser::Store.new
    end

    private
    def s3
      @s3 ||= Aws::S3::Client.new
    end
  end
end
