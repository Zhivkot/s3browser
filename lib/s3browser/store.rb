require 'aws-sdk'

module S3Browser
  class Store
    class StoreError < StandardError; end

    # A thread safe cache class, offering only #[] and #[]= methods,
    # each protected by a mutex.
    # Ripped off from Roda - https://github.com/jeremyevans/roda
    class StoreCache
      # Create a new thread safe cache.
      def initialize
        @mutex = Mutex.new
        @hash = {}
      end

      # Make getting value from underlying hash thread safe.
      def [](key)
        @mutex.synchronize{@hash[key]}
      end

      # Make setting value in underlying hash thread safe.
      def []=(key, value)
        @mutex.synchronize{@hash[key] = value}
      end
    end

    # Ripped off from Roda - https://github.com/jeremyevans/roda
    module StorePlugins
      # Stores registered plugins
      @plugins = StoreCache.new

      # If the registered plugin already exists, use it.  Otherwise,
      # require it and return it.  This raises a LoadError if such a
      # plugin doesn't exist, or a StoreError if it exists but it does
      # not register itself correctly.
      def self.load_plugin(name)
        h = @plugins
        unless plugin = h[name]
          require "s3browser/plugins/#{name}"
          raise StoreError, "Plugin #{name} did not register itself correctly in S3Browser::Store::StorePlugins" unless plugin = h[name]
        end
        plugin
      end

      # Register the given plugin with Store, so that it can be loaded using #plugin
      # with a symbol.  Should be used by plugin files. Example:
      #
      #   S3Browser::Store::StorePlugins.register_plugin(:plugin_name, PluginModule)
      def self.register_plugin(name, mod)
        @plugins[name] = mod
      end

      module Base
        module ClassMethods
          # Load a new plugin into the current class.  A plugin can be a module
          # which is used directly, or a symbol represented a registered plugin
          # which will be required and then used. Returns nil.
          #
          #   Store.plugin PluginModule
          #   Store.plugin :csrf
          def plugin(plugin, *args, &block)
            raise StoreError, "Cannot add a plugin to a frozen Store class" if frozen?
            plugin = StorePlugins.load_plugin(plugin) if plugin.is_a?(Symbol)
            plugin.load_dependencies(self, *args, &block) if plugin.respond_to?(:load_dependencies)
            include(plugin::InstanceMethods) if defined?(plugin::InstanceMethods)
            extend(plugin::ClassMethods) if defined?(plugin::ClassMethods)
            plugin.configure(self, *args, &block) if plugin.respond_to?(:configure)
            nil
          end
        end

        module InstanceMethods
          def add(bucket, object)
            nil
          end

          def remove(bucket, key)
            nil
          end

          def upload(bucket, file)
          end

          def delete(bucket, file)
          end

          def objects(bucket, options)
            s3.list_objects(bucket: bucket).contents.map do |object|
              object.to_h.merge(bucket: bucket, url: "#{object_url}/#{bucket}/#{object[:key]}")
            end
          end

          def object(bucket, key)
            s3.head_object(bucket: bucket, key: key)
          end

          def buckets
            s3.list_buckets.buckets.map {|val| val['name'] }
          end

          def object_url
            @object_url ||= begin
              return ENV['S3BROWSER_OBJECT_URL'] if ENV['S3BROWSER_OBJECT_URL']
              "http://s3-#{ENV['AWS_REGION']}.amazonaws.com"
            end
          end

          private
          def s3
            @s3 ||= Aws::S3::Client.new
          end
        end
      end
    end

    extend StorePlugins::Base::ClassMethods
    plugin StorePlugins::Base
  end
end
