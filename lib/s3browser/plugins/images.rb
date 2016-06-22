module S3Browser
  class Store
    module StorePlugins
      module Images
        module InstanceMethods
          def objects(bucket, options = {})
            super(bucket, options).map do |object|
              object[:thumbnail] = {
                url: "#{thumbnail_url}/#{bucket}/#{object[:key]}",
                width: 200
              } if handle?(object)
              object
            end
          end

          def object(bucket, key)
            object = super(bucket, key)
            object[:thumbnail] = {
              url: "#{thumbnail_url}/#{bucket}/#{object[:key]}",
              width: 200
            } if handle?(object)
            object
          end

          def handle?(object)
            return (object[:content_type] =~ /^image\/.*/) unless (object[:content_type].nil? || object[:content_type] == '')
            return (object[:type] =~ /^image\/.*/) unless (object[:type].nil? || object[:type] == '')
            object[:key] =~ /(jpg|jpeg|png|gif|bmp)$/
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
