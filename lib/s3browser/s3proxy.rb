# frozen_string_literal: true

require 'sinatra/base'
require 's3proxy'

module S3Browser
  class S3Proxy < Sinatra::Base
    raise 'Unconfigured' unless ENV['AWS_REGION']

    configure :development do
      enable :logging
    end

    get(/(.+)/) do |filename|
      matches = filename.match(%r{([^\/]+)\/(.*)})
      bucket = matches[1]
      key = matches[2]
      send_file proxy_s3_file(bucket, key)
    end

    helpers ::S3Proxy

    run! if app_file == $PROGRAM_NAME
  end
end
