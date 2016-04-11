require 'sinatra/base'
require 'tilt/haml'
require 's3browser/store'

module S3Browser
  class Server < Sinatra::Base
    configure :development do
      set :port, 9292
      set :bind, '0.0.0.0'
      enable :logging
    end

    get '/' do
      buckets = store.buckets
      haml :index, locals: { title: 'S3Browser', buckets: buckets }
    end

    get '/:bucket' do |bucket|
      objects = params['q'] ? store.search(bucket, params['q']) : store.get(bucket)

      haml :bucket, locals: { title: bucket, bucket: bucket, objects: objects, q: params['q'] }
    end

    helpers do
      def store
        Store.new
      end

      def bucket
        @bucket ||= ENV['AWS_S3_BUCKET']
      end
    end

    run! if app_file == $0
  end
end
