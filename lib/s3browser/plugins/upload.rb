require 'aws-sdk'

module S3Browser
  class Store
    module StorePlugins
      module Upload
        module InstanceMethods
          def upload(bucket, file)
            filename = file[:filename]
            tempfile = file[:tempfile]

            s3 = Aws::S3::Resource.new
            s3.bucket(bucket).object(filename).upload_file(tempfile.path)

            super(bucket, file)
          end
        end
      end

      register_plugin(:upload, Upload)
    end
  end
end
