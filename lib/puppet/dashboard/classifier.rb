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


    # find a node by certname
    def find_node(certname)
      list('nodes', "Listing nodes").find do |node|
        node['name'] == certname
      end
    end

    # create the specified class
    def create_class(name)
      data = { 'node_class' => { 'name' => name } }
      create('node_classes', "Creating class #{name}", data)
    end

    # given a list of classes, create the ones that do not exist
    # return a hash of all of the specified hashes name => id
    def create_classes(klasses)
      node_classes = list('node_classes', 'Listing classes')

      klass_hash = {}
      # build a hash of class_name => id
      node_classes.each do |x|
        if klasses.include?(x['name'])
          klass_hash[x['name']] = x['id']
        end
      end

      klasses.each do |k|
        unless klass_hash[k]
          # detect any classes that were not found and creat them
          result = create_class(k)
          Puppet.info("Created class: #{result.inspect}")
          klass_hash[result['name']] = result['id']
        end
      end

      klass_hash
    end

    def create_node(certname, klasses)
      data = { 'node' => { 'name' => certname } }

      # find the current list of nodes
      node = find_node(certname)

      # stop if node already exists
      # I will eventually need to support the ability to edit an existing node
      return {:status => "Node #{certname} already exists"} if node

      # create any missing classes
      klass_ids = create_classes(klasses).values

      data['node']['assigned_node_class_ids'] = klass_ids

      create('nodes', "Creating node #{certname}", data)
    end

    # list expects a return of 200
    def list(type, action)
      nodes = Puppet::CloudPack.http_request(
        @http_connection,
        "/#{type}.json",
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

    # regist all classes from a module in the dashboard
    def register_module(module_name, modulepath)
      Puppet[:modulepath] = modulepath
      klasses = (Puppet::Face[:resource_type, :current].search(module_name) || []).collect do |resource_type|
        # I am not going to bother checking that everything we find is loadable
        # This patch assumes that the modules are properly organized
        if resource_type.type == :hostclass
          resource_type.name
        else
          nil
        end
      end.compact
      create_classes(klasses)
    end

    def add_module(module_names, modulepath)
      Dir.chdir(modulepath.split(':').first) do
        module_names.split(',').each do |module_name|
          # install the module into the modulepath
          `puppet module install #{module_name}`
          author, puppet_module = module_name.split('-', 2)
          module_name = if puppet_module
            puppet_module
          else
            module_name
          end
          register_module(puppet_module, modulepath)
        end
      end
    end
  end
end
