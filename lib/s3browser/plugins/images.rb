# frozen_string_literal: true

module S3Browser
  class Store
    module StorePlugins
      module Images
        module InstanceMethods
          def objects(bucket, options = {})
            super(bucket, options).map do |object|
              if handle?(object)
                object[:thumbnail] = {
                  url: "#{thumbnail_url}/#{bucket}/#{object[:key]}",
                  width: 200
                }
              end
              object
            end
          end

          def object(bucket, key)
            object = super(bucket, key)
            if handle?(object)
              object[:thumbnail] = {
                url: "#{thumbnail_url}/#{bucket}/#{object[:key]}",
                width: 200
              }
            end
            object
          end

          def handle?(object)
            return (object[:content_type] =~ %r{^image/.*}) unless [nil, ''].include? object[:content_type]
            return (object[:type] =~ %r{^image/.*}) unless [nil, ''].include? object[:type]
            object[:key] =~ /\.(jpg|jpeg|png|gif|bmp)$/
          end

          def thumbnail_url
            @thumbnail_url ||= begin
              return ENV['S3BROWSER_THUMBNAIL_URL'] if ENV['S3BROWSER_THUMBNAIL_URL']
              "http://s3-#{ENV['AWS_REGION']}.amazonaws.com"
            end
          end
        end
      end

      register_plugin(:images, Images)
    end
  end
end
