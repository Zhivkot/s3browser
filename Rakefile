require 'bundler/gem_tasks'
task :default => :spec

task :server do
  require 's3browser/server'
  app = S3Browser::Server
  app.set :environment, :production
  app.set :bind, '0.0.0.0'
  app.set :port, 9292
  app.run!
end

task :fetch do
  require 's3browser/fetch'
  S3Browser::Fetch.new.run
end
