require 'elasticsearch'
require 'logger'

module S3Browser
  class Store
    attr_reader :index, :type

    def initialize(name)
      @index = 'buckets'
      @type = name
      begin
        client.indices.create index: index, body: {
          settings: {
            index: {
              number_of_shards: 1,
              number_of_replicas: 0
            }
          },
          mappings: mappings
        }
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
      end
    end

    def add(info)
      # TODO Can be optimized to do a bulk index every X requests
      client.index(index: index, type: type, id: info[:key], body: info)
    end

    def get(key = nil)
      if key.nil?
        client.search(index: index, type: type)['hits']['hits'].map {|val| val['_source']}
      else
        raise
      end
    end

    private
    def mappings
      {
        type => {
          _timestamp: {
            enabled: false
          },
          properties: {
            accept_ranges: {
              type: :string,
              index: :not_analyzed
            },
            last_modified: {
              type: :date
            },
            content_length: {
              type: :integer
            },
            etag: {
              type: :string,
              index: :not_analyzed
            },
            content_type: {
              type: :string,
              index: :not_analyzed
            },
            metadata: {
              type: :nested
            },
            key: {
              type: :string,
              index: :not_analyzed
            },
            size: {
              type: :integer
            },
            storage_class: {
              type: :string,
              index: :not_analyzed
            }
          }
        }
      }
    end

    private
    def client
      @client = ::Elasticsearch::Client.new(client_options)
    end

    private
    def client_options
      {
        log: true,
        logger: Logger.new(STDOUT),
        host: ENV['ELASTICSEARCH_URL'] || 'http://localhost:9200'
      }
    end
  end
end
