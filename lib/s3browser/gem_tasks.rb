require 'rake'
require 'rake/tasklib'
require 's3browser'

module S3Browser
  class GemTasks < ::Rake::TaskLib
    include ::Rake::DSL if defined?(::Rake::DSL)

    def install_tasks
      require 'dotenv/tasks'

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

        desc 'Set up the S3Browser'
        task :setup => :dotenv do
          require 'highline'
          require 'json'
          require 'aws-sdk'
          require 'time'
          require 'logger'
          # Aws.config.update(logger: Logger.new($stdout), log_level: :debug, log_formatter: Aws::Log::Formatter.colored)


          if File.exist?('.env') == false || cli.agree('Do you want to update your .env file (y/n)?') { |q| q.default = 'n' }
            setup_env
          end

          if cli.agree('Should we set up SQS notification on the S3 bucket for you (y/n)?') { |q| q.default = 'y' }
            setup_bucket
            setup_sqs
          end
        end
      end
    end

    def setup_env
      envs = {}
      envs[:AWS_ACCESS_KEY_ID] = cli.ask('What is your AWS Access Key ID') { |q| q.validate = /^\w+$/; q.default = ENV['AWS_ACCESS_KEY_ID'] if ENV['AWS_ACCESS_KEY_ID'] }
      envs[:AWS_SECRET_ACCESS_KEY] = cli.ask('What is your AWS Secret Access Key') { |q| q.validate = /^[\w\/\+]+$/; q.default = ENV['AWS_SECRET_ACCESS_KEY'] if ENV['AWS_SECRET_ACCESS_KEY'] }
      envs[:AWS_REGION] = cli.ask('What AWS region should the service be located in') { |q| q.validate = /^[a-z]{2}\-[a-z]+\-\d$/; q.default = ENV['AWS_REGION'] if ENV['AWS_REGION'] }
      envs[:AWS_S3_BUCKET] = cli.ask('What is the name of the S3 bucket to use') { |q| q.validate = /^[^ ]+$/; ; q.default = ENV['AWS_S3_BUCKET'] if ENV['AWS_S3_BUCKET'] }
      envs[:AWS_SQS_QUEUE] = cli.ask('What is the name of the SQS queue to use') { |q| q.validate = /^[^ ]+$/; ; q.default = ENV['AWS_SQS_QUEUE'] if ENV['AWS_SQS_QUEUE'] }

      envs_string = envs.map {|k,v| "#{k}=#{v}"}.join("\n") + "\n"

      cli.say 'This is the proposed .env file:'
      cli.say envs_string + "\n"

      write_file = cli.agree 'Are you happy with the settings (y/n)? If yes, your current .env file will be overwritten'

      if write_file
        cli.say 'Writing .env file'
        File.open('.env', 'w') { |file| file.write('# export $(cat .env | grep -v ^# | xargs)' + "\n" + envs_string) }
        Dotenv.load! # Reload the .env files
      else
        cli.say 'Skipping the .env file'
      end
    end

    def setup_bucket
      # Ensure that the bucket exists
      s3.create_bucket({
        bucket: ENV['AWS_S3_BUCKET']
      })
      cli.say "Created the S3 bucket: #{ENV['AWS_S3_BUCKET']}"
    rescue
      cli.say "Bucket already exists: #{ENV['AWS_S3_BUCKET']}"
    end

    def setup_sqs
      # Create the Queue
      resp = sqs.create_queue(
        queue_name: ENV['AWS_SQS_QUEUE']
      )
      queue_url = resp.to_h[:queue_url]
      cli.say "Created queue: #{queue_url}"

      # Replace the access policy on the queue to allow the bucket to write to it
      queue_arn = sqs.get_queue_attributes(queue_url: queue_url, attribute_names: ['QueueArn']).attributes['QueueArn']
      sqs.set_queue_attributes(
        queue_url: queue_url,
        attributes: {
          'Policy' => sqs_policy(ENV['AWS_S3_BUCKET'], queue_arn)
        }
      )
      cli.say 'Created the correct queue policy'

      # Ensure that the bucket pushes notifications to the queue
      s3.put_bucket_notification_configuration({
        bucket: ENV['AWS_S3_BUCKET'],
        notification_configuration: {
          queue_configurations: [
            {
              id: "S3BrowserNotification",
              queue_arn: queue_arn,
              events: ['s3:ObjectCreated:*','s3:ObjectRemoved:*']
            }
          ]
        }
      })
      cli.say 'Set the bucket to push notifications to SQS'
    end

    def sqs
      @sqs ||= Aws::SQS::Client.new
    end

    def s3
      @s3 ||= Aws::S3::Client.new
    end

    def cli
      @cli ||= HighLine.new
    end

    def sqs_policy(bucket_name, queue_arn)
      folder = File.expand_path File.dirname(__FILE__)
      policy = JSON.parse(File.read("#{folder}/policy.json"))
      policy['Id'] = Time.now.strftime('%Y%m%dT%H%M%S')
      policy['Statement'][0]['Condition']['ArnLike']['aws:SourceArn'] = "arn:aws:s3:*:*:#{bucket_name}"
      policy['Statement'][0]['Resource'] = queue_arn
      JSON.generate(policy)
    end
  end
end

S3Browser::GemTasks.new.install_tasks
