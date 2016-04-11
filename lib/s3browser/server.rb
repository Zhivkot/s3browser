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
      params['q'] = nil if params['q'] == ''
      objects = store.get(bucket, term: params['q'], sort: params['s'], direction: params['d'])

      haml :bucket, locals: { title: bucket, bucket: bucket, objects: objects, q: params['q'] }
    end

    helpers do
      def store
        Store.new
      end

      def bucket
        @bucket ||= ENV['AWS_S3_BUCKET']
      end

      def sort_url(field)
        url = '?s=' + field
        if params['s'] == field
          if params['d'] == 'desc'
            url = url + '&d=asc'
          else
            url = url + '&d=desc'
          end
        end
        url
      end

      def sort_icon(field)
        if params['s'] == field
          if ['asc', 'desc'].include?(params['d'])
            'fa-sort-' + params['d']
          else
            'fa-sort-asc'
          end
        else
          'fa-sort'
        end
      end
    end

    run! if app_file == $0
  end
end
