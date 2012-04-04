require 'interpol/endpoint'
require 'interpol/errors'
require 'yaml'

module Interpol
  module DefinitionFinder
    include HashFetcher
    NoDefinitionFound = Class.new

    def find_definition(options)
      method, path, version = extract_search_options_from(options)
      endpoint = find { |e| e.method == method && e.route_matches?(path) }
      return NoDefinitionFound if endpoint.nil?
      endpoint.definitions.find { |d| d.version == version } || NoDefinitionFound
    end

  private

    def extract_search_options_from(options)
      method  = fetch_from(options, :method).downcase.to_sym
      path    = fetch_from(options, :path)
      version = fetch_from(options, :version)

      return method, path, version
    end
  end

  # Public: Defines interpol configuration.
  class Configuration
    attr_reader :endpoint_definition_files, :endpoints
    attr_accessor :validation_mode

    def initialize
      api_version do
        raise ConfigurationError, "api_version has not been configured"
      end

      validate_if do |env, status, headers, body|
        (200..299).cover?(status) && status != 204 # No Content
      end

      on_unavailable_request_version do |requested, available|
        message = "The requested API version is invalid. " +
                  "Requested: #{requested}. " +
                  "Available: #{available}"
        halt 406, JSON.dump(error: message)
      end

      self.endpoint_definition_files = []
      yield self if block_given?
    end

    def endpoint_definition_files=(files)
      self.endpoints = files.map do |file|
        Endpoint.new(YAML.load_file file)
      end
      @endpoint_definition_files = files
    end

    def endpoints=(endpoints)
      @endpoints = endpoints.extend(DefinitionFinder)
    end

    def api_version(version=nil, &block)
      if [version, block].compact.size.even?
        raise ConfigurationError.new("api_version requires a static version " +
                                     "or a dynamic block, but not both")
      end

      @api_version_block = block || lambda { |env| version }
    end

    def api_version_for(rack_env_hash)
      @api_version_block.call(rack_env_hash).to_s
    end

    def validate_if(&block)
      @validate_if_block = block
    end

    def validate?(*args)
      @validate_if_block.call(*args)
    end

    def on_unavailable_request_version(&block)
      @unavailable_request_version_block = block
    end

    def request_version_unavailable(execution_context, *args)
      execution_context.instance_exec(*args, &@unavailable_request_version_block)
    end

    def self.default
      @default ||= Configuration.new
    end

    def customized_duplicate(&block)
      block ||= lambda { |c| }
      dup.tap(&block)
    end
  end
end

