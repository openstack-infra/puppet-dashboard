require 'puppet'
require 'puppet/face'
require 'puppet/dashboard/classifier'
Puppet::Face.define(:dashboard, '0.0.1') do
  # TODO - default run mode should be agent
  Puppet::CloudPack.add_classify_options(self)
  # 404 cannot connect to URL
  # 500 database could be turned off (internal
  action 'list' do
    description 'lists instances of classes, groups, or nodes from the dashboard'
    when_invoked do |type, options|
      type_map = {'classes' => 'node_classes', 'nodes' => 'nodes', 'groups' => 'node_groups'}
      type_name = type_map[type] || raise(Puppet::Error, "Invalid type specified: #{type}. Allowed types are #{type_map.keys.join(',')}")
      connection = Puppet::Dashboard::Classifier.connection(options)
      connection.list(type_name, "Listing #{type}")
    end
  end
  # 422 for create node - means it does not exist

  action 'create_node' do
    option '--name=' do
      summary 'Certificate name of node to create'
      required
    end
    option '--parameter=' do
      summary 'Parameter that should be added to the node'
      description <<-EOT
        Param that should be added to node. This is only expected to
        be specified programmatically.
      EOT
    end
    option '--classes=' do
      summary 'a comma delimited list of classes'
    end
    when_invoked do |options|
      klasses = options[:classes].is_a?(Array) ? options[:classes] : options[:classes].join(',')
      Puppet::Dashboard::Classifier.connection(options).create_node(options[:name], klasses)
    end
  end

  action 'create_class' do
    option '--name=' do
      summary 'Name of class to create in the dashboard'
      required
    end
    when_invoked do |options|
      Puppet::Dashboard::Classifier.connection(options).create_classes([options[:name]])
    end
  end

  action 'register_module' do
    description 'Imports classes from the puppet master into the dashboard'
    option '--module-name=' do
      description <<-EOT
        Name of module to query classes from
      EOT
      default_to do
        '*'
      end
    end
    option '--modulepath=' do
      description <<-EOT
        Environment where modules should be introspected
      EOT
      default_to do
        Puppet[:modulepath]
      end
    end
    when_invoked do |options|
      connection = Puppet::Dashboard::Classifier.connection(options)
      connection.register_module(options[:module_name], options[:modulepath])
    end
  end


  action 'add_module' do
    description <<-EOT
      Installs a list of modules and adds their classes to the Dashboard.
    EOT
    option '--modulepath=' do
      default_to do
        Puppet[:modulepath]
      end
    end
    option '--module-name=' do
      description <<-EOT
        name of module from forge to download
        should follow convention of account-module
        This takes a list.
      EOT
      required
    end
    when_invoked do |options|
      connection = Puppet::Dashboard::Classifier.connection(options)
      connection.add_module(options[:module_name], options[:modulepath])
    end
  end

  # if you pass data, then this is not intended to be used from the command line
  # we should just parse a YAML file for this
  action 'create_group' do
    option '--name=' do
      required
    end
    when_invoked do |options|
      # I need data for being able
      data = { 'node_group' => { 'name' => options[:name] } }
      connection = Puppet::Dashboard::Classifier.connection(options)
      connection.create('node_groups', "Creating group: #{options[:name]}", data, options)
    end
  end
  # 422 - mssing group
  # 422 - mossing node
  action 'add_group_to_node' do
    option '--node-name=' do
      required
    end
    option '--group-name=' do
      required
    end
    when_invoked do |options|
      data = { 'node_name' => options[:node_name], 'group_name' => options[:group_name] }
      connection = Puppet::Dashboard::Classifier.connection(options)
      connection.create('memberships', "Adding group to node", data, options)
    end
  end

end

