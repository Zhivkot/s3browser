require 'shoryuken'
require 's3browser/store'

module S3Browser
  class Worker
    include Shoryuken::Worker

    raise 'Unconfigured' unless ENV['AWS_REGION']

    shoryuken_options queue: ENV['AWS_SQS_QUEUE'], body_parser: :json, auto_delete: true

    class Store < S3Browser::Store
      plugin :es
      plugin :images
    end

    def initialize
      Shoryuken.logger.level = ::Logger::DEBUG if ENV['RACK_ENV'] != 'production'
    end

    def perform(sqs_msg, body)
      Shoryuken.logger.debug body

      if body['Records']
        body['Records'].each do |record|
          case record['eventName']
          when 'ObjectRemoved:Delete'
            remove record
          when 'ObjectCreated:Put'
            add record
          end
        end
      else
        raise unless body['Event'] == 's3:TestEvent'
      end
    end

    def add(record)
      bucket = record['s3']['bucket']['name']
      key    = record['s3']['object']['key']

      info = s3.head_object({ bucket: bucket, key: key })
      info = info.to_h.merge(record['s3']['object'].inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo})

      store.add bucket, info
    end

    def remove(record)
      bucket = record['s3']['bucket']['name']
      key    = record['s3']['object']['key']

      store.remove bucket, key
    end

    private
    def store
      @store ||= Store.new('s3browser')
    end

    private
    def s3
      @s3 ||= Aws::S3::Client.new
    end
  end
end
