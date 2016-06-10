require 'sinatra/base'
require 'rack-flash'
require 'tilt/haml'
require 's3browser/store'

module S3Browser
  class Server < Sinatra::Base
    enable :sessions
    use Rack::Flash
    raise 'Unconfigured' unless ENV['AWS_REGION']

    class Store < S3Browser::Store
      plugin :es
      plugin :images
      plugin :upload
    end

    configure :development do
      enable :logging
      set :store, Store.new('s3browser')
    end

    get '/' do
      buckets = settings.store.buckets
      haml :index, locals: { title: 'S3Browser', buckets: buckets }
    end

    get '/:bucket/?' do |bucket|
      params['q'] = nil if params['q'] == ''
      objects = settings.store.objects(bucket, term: params['q'], sort: params['s'], direction: params['d'])
      haml :bucket, locals: { title: bucket, bucket: bucket, objects: objects, q: params['q'] }
    end

    get '/:bucket/:key/?' do |bucket, key|
      object = settings.store.object(bucket, key)
      haml :object, locals: { title: key, bucket: bucket, key: key, object: object }
    end

    post '/upload/:bucket/?' do |bucket|
      if params['upload']
        begin
          settings.store.upload bucket, params['upload']
          flash[:success] = 'File uploaded'
        rescue StandardError => e
          flash[:error] = 'Could not upload the file: ' + e.message
        end
      end
      redirect back
    end

    helpers do
      def bucket
        ENV['AWS_S3_BUCKET']
      end

      def sort_url(field)
        field = field.to_s
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
        field = field.to_s
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
