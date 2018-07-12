# frozen_string_literal: true

require 'aws-sdk'

module S3Browser
  class Store
    module StorePlugins
      module Manager
        module InstanceMethods
          def upload(bucket, file)
            filename = file[:filename]
            tempfile = file[:tempfile]

            s3 = Aws::S3::Resource.new
            s3.bucket(bucket).object(filename).upload_file(tempfile.path)

            super
          end

          def delete(bucket, file)
            s3 = Aws::S3::Client.new
            s3.delete_object(bucket: bucket, key: file)

            super
          end
        end
      end

      register_plugin(:manager, Manager)
    end
  end
end
