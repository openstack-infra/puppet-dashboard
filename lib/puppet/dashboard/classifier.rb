require 'puppet'
require 'puppet/network/http_pool'
require 'puppet/cloudpack'
module Puppet::Dashboard
  class Classifier
    def self.connection(options)
      @connection ||= Puppet::Dashboard::Classifier.new(options, false)
    end

    attr_reader :connection_options

    def initialize(options, use_ssl=false)
      # Workaround for the fact that Dashboard is typically insecure.
      @connection_options = {
        :enc_server => options[:enc_server],
        :enc_port => options[:enc_port],
        :enc_ssl => options[:enc_ssl],
        :enc_auth_passwd => options[:enc_auth_passwd],
        :enc_auth_user => options[:enc_auth_user]
      }
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
    def list(type, action)
      nodes = Puppet::CloudPack.http_request(
        @http_connection,
        "/#{type}.json",
        options,
        connection_options,
        action
      )
    end

    def create(type, action, data)
      response = Puppet::CloudPack.http_request(
        @http_connection,
        "/#{type}.json",
        connection_options,
        action,
        '201',
        data
      )
    end
  end
end
