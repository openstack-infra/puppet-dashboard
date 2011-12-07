require 'puppet'
require 'puppet/network/http_pool'
require 'puppet/cloudpack'
module Puppet::Dashboard
  class Classifier
    def self.connection(options)
      @connection ||= Puppet::Dashboard::Classifier.new(options)
    end

    # convenience method for array munging
    def self.to_array(maybe_array)
      if maybe_array
        maybe_array.is_a?(Array) ? maybe_array : maybe_array.split(',')
      end
    end

    attr_reader :connection_options

    def initialize(options)
      # Workaround for the fact that Dashboard is typically insecure.
      @connection_options = {
        :enc_server => options[:enc_server],
        :enc_port => options[:enc_port],
        :enc_ssl => options[:enc_ssl],
        :enc_auth_passwd => options[:enc_auth_passwd],
        :enc_auth_user => options[:enc_auth_user]
      }
      ssldir_save = Puppet[:ssldir]
      Puppet[:ssldir] = '/dev/null'
      @http_connection = Puppet::Network::HttpPool.http_instance(options[:enc_server], options[:enc_port])
      Puppet[:ssldir] = ssldir_save
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

    # find a group if it exists
    def find_group(group_name)
      list('node_groups', "Listing groups").find do |group|
        group['name'] == group_name
      end
    end

    # create the specified class
    # this does not check to see if the class exists
    # if you want to check first, use create_classes
    def create_class(name)
      data = { 'node_class' => { 'name' => name } }
      create('node_classes', "Creating class #{name}", data)
    end

    # given a list of classes, create the ones that do not exist
    # return a hash of all of the specified hashes name => id
    def create_classes(klasses)
      klass_hash = {}
      if klasses
        node_classes = list('node_classes', 'Listing classes')

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

      end
      klass_hash
    end

    def create_node(certname, klasses, parameters, groups)

      # find the current list of nodes
      node = find_node(certname)

      # stop if node already exists
      return {:status => "Node #{certname} already exists"} if node

      # create any missing classes
      klass_ids = create_classes(klasses).values

      # make sure all groups exist and get their ids
      group_id_hash = {}
      (groups || []).collect do |group|
        group_hash = find_group(group)
        if group_hash
          group_id_hash[group_hash['name']] = group_hash['id']
        else
          return {:status => "Parent Group #{group} for node #{certname} does not exist"}
        end
      end
      group_ids = (group_id_hash || {} ).values

      data = { 'node' => { 'name' => certname } }
      data['node']['assigned_node_class_ids'] = klass_ids
      data['node']['assigned_node_group_ids'] = group_ids
      data['node']['parameter_attributes'] = []
      (parameters || {}).each do |key, value|
        data['node']['parameter_attributes'].push({'key' => key, 'value' => value})
      end

      create('nodes', "Creating node #{certname}", data)
    end

    def create_group(group_name, parameters, parent_groups, classes)

      # check if the group already exists
      group = find_group(group_name)

      # stop if group already exists
      return {:status => "Group #{group_name} already exists"} if group

      # make sure that the classes exist, create them if they do not
      klass_ids = (create_classes(classes) || {} ).values

      # make sure that the parent groups exist, fail if they do not...?
      # I dont want to support parent groups yet...
      parent_group_id_hash = {}
      (parent_groups || []).collect do |parent|
        group_hash = find_group(parent)
        if group_hash
          parent_group_id_hash[group_hash['name']] = group_hash['id']
        else
          return {:status => "Parent Group #{parent} for group #{group_name} does not exist"}
        end
      end
      parent_group_ids = (parent_group_id_hash || {} ).values

      # set up the post data
      data = { 'node_group' => { 'name' => group_name } }
      data['node_group']['assigned_node_class_ids'] = klass_ids
      data['node_group']['assigned_node_group_ids'] = parent_group_ids
      data['node_group']['parameter_attributes'] = []
      (parameters || {} ).each do |key, value|
        data['node_group']['parameter_attributes'].push({'key' => key, 'value' => value})
      end

      create('node_groups', "Creating group: #{group_name}", data)

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
        module_names.each do |module_name|
          # install the module into the modulepath
          # TODO - port to use the new faces version
          # Puppet::Face[:module, :current].install(module_name)
          `puppet module install #{module_name}`
          author, puppet_module = module_name.split('-', 2)
          register_module(puppet_module || module_name, modulepath)
        end
      end
    end
  end
end
