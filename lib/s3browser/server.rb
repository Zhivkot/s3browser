# frozen_string_literal: true

require 'sinatra/base'
require 'rack-flash'
require 'tilt/haml'
require 's3browser/store'

module S3Browser
  class Server < Sinatra::Base
    raise 'Unconfigured' unless ENV['AWS_REGION']

    use Rack::Flash

    class Store < S3Browser::Store
      plugin :es
      plugin :images
      plugin :manager
    end

    configure do
      enable :sessions
      enable :method_override
      set :store, Store.new('s3browser')
    end

    configure :development do
      enable :logging
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

    get '/:bucket/*' do |bucket, key|
      begin
        object = settings.store.object(bucket, key)
      rescue StandardError
        halt(404)
      end
      haml :object, locals: { title: key, bucket: bucket, key: key, object: object }
    end

    delete '/:bucket/:key/?' do |bucket, key|
      begin
        settings.store.delete(bucket, key)
        flash[:success] = 'File deleted'
        redirect "/#{bucket}"
      rescue StandardError => e
        flash[:error] = 'Could not remove the file: ' + e.message
        redirect back
      end
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
          url = if params['d'] == 'desc'
                  url + '&d=asc'
                else
                  url + '&d=desc'
                end
        end
        url
      end

      def sort_icon(field)
        field = field.to_s
        if params['s'] == field
          if %w[asc desc].include?(params['d'])
            'fa-sort-' + params['d']
          else
            'fa-sort-asc'
          end
        else
          'fa-sort'
        end
      end
    end

    run! if app_file == $PROGRAM_NAME
  end
end
