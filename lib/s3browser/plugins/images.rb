module S3Browser
  class Store
    module StorePlugins
      module Images
        module InstanceMethods
          def add(bucket, object)
            return super(bucket, object) unless handle?(object)
            # TODO Create a thumbnail and make it available

            super(bucket, object)
          end

          def objects(bucket, options)
            super(bucket, options).map do |elm|
              elm[:thumbnail] = {
                url: "http://#{bucket}.s3.amazonaws.com/#{elm[:key]}",
                width: 200
              } if handle?(elm)
              elm
            end
          end

          def handle?(object)
            return (object[:content_type] =~ /^image\/.*/) unless (object[:content_type].nil? || object[:content_type] == '')
            object[:key] =~ /jpg|jpeg|png|gif|bmp$/
          end
        end
      end

      register_plugin(:images, Images)
    end
  end
end
