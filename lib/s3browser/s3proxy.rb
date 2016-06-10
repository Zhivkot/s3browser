require 'sinatra/base'

module S3Browser
  class S3Proxy < Sinatra::Base
    raise 'Unconfigured' unless ENV['AWS_REGION']

    configure :development do
      enable :logging
    end

    get %r{(.+)} do |filename|
      read_file filename
    end

    helpers do
      def read_file(file)
        cached_file = cache_location(file)

        matches = file.match(/([^\/]+)\/(.*)/)
        options = {
          bucket: matches[1],
          key: matches[2],
        }
        options[:if_modified_since] = File.mtime(cached_file) if File.exists?(cached_file)

        begin
          s3object = s3.get_object(options, target: cached_file)
        rescue Aws::S3::Errors::NotModified
          options.delete(:if_modified_since)
          s3object = s3.head_object(options)
        rescue
          halt(404)
        end
        send_file cached_file, file_name: File.basename(file), type: s3object.content_type
      end

      def cache_location(file)
        matches = file.match(/([^\/]+)\/(.*)/)
        "#{cache_folder}/#{matches[2]}"
      end

      def cache_folder
        path = '/tmp/s3proxy'
        Dir.mkdir(path) unless File.exists?(path)
        path
      end

      def s3
        @s3 ||= Aws::S3::Client.new
      end
    end

    run! if app_file == $0
  end
end
