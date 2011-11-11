require 'puppet'
require 'puppet/network/http_pool'
require 'puppet/cloudpack'
module Puppet::Dashboard
  class Classifier
    def self.connection(options)
      @connection ||= Puppet::Dashboard::Classifier.new(options, false)
    end

    def initialize(options, use_ssl=false)
      # Workaround for the fact that Dashboard is typically insecure.
      @http_connection = Puppet::Network::HttpPool.http_instance(options[:enc_server], options[:enc_port])
      if options[:enc_ssl] then
        @http_connection.use_ssl = true
        @uri_scheme = 'https'
        # We intentionally use SSL only for encryption and not authenticity checking
        @http_connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
      else
        @http_connection.use_ssl = false
        @uri_scheme = 'http'
      end
      Puppet.info "Using #{@uri_scheme}://#{options[:enc_server]}:#{options[:enc_port]} as Dashboard."
    end

    # list expects a return of 200
    def list(type, action, options)
      nodes = Puppet::CloudPack.http_request(
        @http_connection,
        "/#{type}.json",
        options,
        action
      )
    end

    def create(type, action, data, options)
      response = Puppet::CloudPack.http_request(
        @http_connection,
        "/#{type}.json",
        options,
        action,
        '201',
        data
      )
    end
  end
end
