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
            result = super(bucket, options)
            result.map do |elm|
              elm[:thumbnail] = {
                url: "http://#{bucket}.s3.amazonaws.com/#{elm[:key]}",
                width: 200
              } if handle?(elm)
              elm
            end
          end

          def handle?(object)
            object[:content_type] =~ /^image\/.*/
          end
        end
      end

      register_plugin(:images, Images)
    end
  end
end
