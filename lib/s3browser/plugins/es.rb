require 'elasticsearch'
require 'logger'

module S3Browser
  class Store
    module StorePlugins
      module ES
        def self.configure(plugin)
          # TODO Maybe setup and check index here?
        end

        module InstanceMethods
          attr_reader :index

          def initialize(index)
            @index = index
            check_index
          end

          def add(bucket, object)
            # TODO Can be optimized to do a bulk index every X requests
            object[:bucket] = bucket
            object[:last_modified] = object[:last_modified].to_i
            object[:url] = "http://#{bucket}.s3.amazonaws.com/#{object[:key]}"
            client.index(index: index, type: 'objects', id: object[:key], body: object)
            super(bucket, object)
          end

          def objects(bucket, options)
            body = get_body(bucket, options)
            if options[:key]
              raise 'Not implemented yet'
            else
              result = client.search(index: index, type: 'objects', body: body)
              result['hits']['hits'].map {|val| val['_source'].inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo} }
            end
          end

          def search(bucket, term, options = {})
            get(bucket, {term: term}.merge(options))
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
          def get_body(bucket, options = {})
            body = {
              query: {
                bool: {
                  filter: {
                    terms: {
                      bucket: [ bucket ]
                    }
                  }
                }
              }
            }

            # Sort using the raw field
            options[:sort] = 'key.raw' if options[:sort] == 'key'
            body[:sort] = { options[:sort] => options[:direction] ? options[:direction] : 'asc'} if options[:sort]

            if options[:term]
              body[:query][:bool][:must] = {
                simple_query_string: {
                  fields: [ 'key', 'key.raw' ],
                  default_operator: 'OR',
                  query: options[:term]
                }
              }
            end

            body
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
                },
                analysis: {
                  analyzer: {
                    filename: {
                      type: :custom,
                      char_filter: [  ],
                      tokenizer: :standard,
                      filter: [ :word_delimiter, :standard, :lowercase, :stop ]
                    }
                  }
                }
              },
              mappings: mappings
            }
          rescue Elasticsearch::Transport::Transport::Errors::BadRequest
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
                    index: :analyzed,
                    analyzer: :filename,
                    fields: {
                      raw: {
                        type: :string,
                        index: :not_analyzed
                      }
                    }
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

      register_plugin(:es, ES)
    end
  end
end
