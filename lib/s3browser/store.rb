require 'elasticsearch'
require 'logger'

# Use the index for client or app scope: localhost:9200/jadeit, localhost:9200/s3browser
# The type stays objects: localhost:9200/jadeit/objects, localhost:9200/s3browser/objects

module S3Browser
  class Store
    attr_reader :index

    def initialize(index = 's3browser')
      @index = index
      check_index
    end

    def add(bucket, object)
      object[:bucket] = bucket
      # TODO Can be optimized to do a bulk index every X requests
      client.index(index: index, type: 'objects', id: object[:key], body: object)
    end

    def get(bucket, key = nil)
      if key.nil?
        client.search(index: index, type: 'objects', q: "bucket:#{bucket}")['hits']['hits'].map {|val| val['_source']}
      else
        raise
      end
    end

    def buckets
      client.search(index: index, type: 'objects', body: {
        query: { match_all: {} },
        size: 0,
        aggregations: {
          buckets: {
            terms: {
              field: :bucket,
              size: 0,
              order: { '_term' => :asc }
            }
          }
        }
      })['aggregations']['buckets']['buckets'].map {|val| val['key'] }
    end

    def indices
      lines = client.cat.indices
      lines.split("\n").map do |line|
        line = Hash[*[
          :health,
          :state,
          :index,
          :primaries ,
          :replicas,
          :count,
          :deleted,
          :total_size,
          :size
        ].zip(line.split(' ')).flatten]

        [:primaries, :replicas, :count, :deleted].each {|key| line[key] = line[key].to_i}

        line
      end
    end

    private
    def client
      @client ||= ::Elasticsearch::Client.new(client_options)
    end

    private
    def client_options
      {
        log: true,
        logger: Logger.new(STDOUT),
        host: ENV['ELASTICSEARCH_URL'] || 'http://localhost:9200'
      }
    end

    private
    def check_index
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

    private
    def mappings
      {
        objects: {
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
  end
end
