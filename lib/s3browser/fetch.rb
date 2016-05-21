require 'aws-sdk'
require 'time'
require 's3browser/store'

module S3Browser
  class Fetch
    raise 'Unconfigured' unless ENV['AWS_REGION']

    class Store < S3Browser::Store
      plugin :es
      plugin :images
    end

    def run
      s3.list_objects(bucket: bucket).contents.map do |object|
        info = s3.head_object({
          bucket: bucket,
          key: object.key
        })

        info = info.to_h.merge(object.to_h)
        store.add bucket, info
      end
    end

    private
    def bucket
      @bucket ||= ENV['AWS_S3_BUCKET']
    end

    private
    def s3
      @s3 ||= Aws::S3::Client.new
    end

    private
    def store
      @store ||= Store.new('s3browser')
    end
  end
end

if $0 == __FILE__
  S3Browser::Fetch.new.run
end
