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
      objects = store.get
p objects
      haml :index, locals: { title: 'S3Browser', objects: objects }
    end

    helpers do
      def store
        @store ||= Store.new(bucket)
      end

      def bucket
        @bucket ||= ENV['AWS_S3_BUCKET']
      end
    end

    run! if app_file == $0
  end
end
