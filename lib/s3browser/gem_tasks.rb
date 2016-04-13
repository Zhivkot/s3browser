require 'rake'
require 'rake/tasklib'
require 's3browser'

module S3Browser
  class GemTasks < ::Rake::TaskLib
    include ::Rake::DSL if defined?(::Rake::DSL)

    def install_tasks
      namespace :s3browser do
        desc 'Run the web server for S3Browser'
        task :server do
          require 's3browser/server'
          app = S3Browser::Server
          app.set :environment, :production
          app.set :bind, '0.0.0.0'
          app.set :port, 9292
          app.run!
        end

        desc 'Fetch and store all the S3 objects'
        task :fetch do
          require 's3browser/fetch'
          S3Browser::Fetch.new.run
        end
      end
    end
  end
end

S3Browser::GemTasks.new.install_tasks
