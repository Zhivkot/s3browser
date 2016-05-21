require 'aws-sdk'

module S3Browser
  class Store
    module StorePlugins
      module Upload
        module InstanceMethods
          def upload(bucket, file)
            filename = file[:filename]
            file     = file[:tempfile]

            s3 = Aws::S3::Resource.new
            s3.bucket(bucket).object(filename).upload_file(file.path)
          end
        end
      end

      register_plugin(:upload, Upload)
    end
  end
end
