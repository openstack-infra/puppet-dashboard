require 'puppet'
require 'puppet/face'
require 'puppet/dashboard/classifier'
Puppet::Face.define(:dashboard, '0.0.1') do

  copyright "Puppet Labs", 2011
  license   "Apache 2 license; see COPYING"

  summary 'Reads and writes data to the ENC component of the Dashboard.'
  description <<-EOT
    This subcommand wraps functionality available through the REST
    interface of the Dashboard. It supports the ability to list
    all of the information about certain type from the Dashboard, as
    well as the ability to create nodes, classes, and groups. It
    does not yet support the ability to edit existing nodes, classes,
    and groups.
    It also supports the ability to add all classes from a module to the
    Dashboard as well as the ability to retrive a from the module
    forge and load all of its classes into the Dashboard.
  EOT

  # TODO - default run mode should be agent
  # this is actually adding an extra unused option node-group #10743
  Puppet::CloudPack.add_classify_options(self)

  # 404 cannot connect to URL
  # 500 database could be turned off (internal
  action 'list' do
    summary 'lists instances of classes, groups, or nodes from the dashboard'
    description <<-EOT
      List all of the occurrences of a certain type from the dashboard.
      The supported types are: classes, nodes, and groups.
    EOT
    arguments '(classes|nodes|groups)'
    when_invoked do |type, options|
      type_map = {'classes' => 'node_classes', 'nodes' => 'nodes', 'groups' => 'node_groups'}
      type_name = type_map[type] || raise(Puppet::Error, "Invalid type specified: #{type}. Allowed types are #{type_map.keys.join(',')}")
      connection = Puppet::Dashboard::Classifier.connection(options)
      connection.list(type_name, "Listing #{type}")
    end
  end

  # 422 for create node - means it does not exist
  action 'create_node' do
    summary 'Creates a node'
    option '--name=' do
      summary 'Certificate name of node to create'
      required
    end
    option '--parameters=' do
      summary 'Parameters that should be added to the node'
      description <<-EOT
        Parameters that should be added to node. This only
        accepts a Hash and thus is only expected to be specified
        programmatically.
      EOT
    end
    option '--classes=' do
      summary 'List of classes to be added to the node'
      description <<-EOT
        A List of classes to be added to the node. It expects
        a comma delimited list to be passed from the command line
        or an array of it is invoked programatically.
      EOT
    end
    option '--groups=' do
      summary 'List of groups to add to the node'
      description <<-EOT
        A List of groups to be added to the node. It expects
        a comma delimited list to be passed from the command line
        or an array of it is invoked programatically.
      EOT
    end
    when_invoked do |options|
      Puppet::Dashboard::Classifier.connection(options).create_node(
        options[:name],
        Puppet::Dashboard::Classifier.to_array(options[:classes]),
        options[:parameters],
        Puppet::Dashboard::Classifier.to_array(options[:groups])
      )
    end
  end

  action 'create_class' do
    summary 'Creates a class'
    option '--name=' do
      summary 'Name of class to create in the dashboard'
      required
    end
    when_invoked do |options|
      Puppet::Dashboard::Classifier.connection(options).create_classes([options[:name]])
    end
  end

  action 'create_group' do
    summary 'Creates a group'
    option '--name=' do
      summary 'Name of the group to be created'
      required
    end
    option '--parameters=' do
      summary 'Parameters to be added to the group'
      description <<-EOT
        Parameters that should be added to the group.
        This currently on accepts a Hash so it can only be used
        programmatically.
      EOT
    end
    option '--parent-groups=' do
      summary 'List of parent groups to add to the node'
      description <<-EOT
        A List of parent groups to be added to the group. It expects
        a comma delimited list to be passed from the command line
        or an Array of it is invoked programatically.
      EOT
    end
    option '--classes=' do
      summary 'List of classes to be added to the group'
      description <<-EOT
        A List of classes to be added to the group. Expects
        a comma delimited list to be passed from the command line
        or an Array of it is invoked programatically.
      EOT
    end
    when_invoked do |options|
      Puppet::Dashboard::Classifier.connection(options).create_group(
        options[:name],
        options[:parameters],
        Puppet::Dashboard::Classifier.to_array(options[:parent_groups]),
        Puppet::Dashboard::Classifier.to_array(options[:classes])
      )
    end
  end

  action 'register_module' do
    summary 'Imports classes from the puppet master into the dashboard'
    option '--module-name=' do
      description <<-EOT
        Name of module to query classes from to load into the Dashboard. By default, it
        will query all classes from all modules in the modulepath.
      EOT
      default_to do
        '*'
      end
    end
    option '--modulepath=' do
      description <<-EOT
        Path to search for the specified modules.
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
    summary 'Downloads modules from the Forge and imports their classes to the Dashboard'
    description <<-EOT
      Uses the puppet module tool to install the specified module from the
      Forge and load its classes into the Dashboard.
    EOT
    option '--modulepath=' do
      description <<-EOT
        Path to search for the specified modules.
      EOT
      default_to do
        Puppet[:modulepath]
      end
    end
    option '--module-names=' do
      description <<-EOT
        name of module from forge to download
        should follow convention of account-module
        This takes a list.
      EOT
      required
    end
    when_invoked do |options|
      connection = Puppet::Dashboard::Classifier.connection(options)
      connection.add_module(
        Puppet::Dashboard::Classifier.to_array(options[:module_names]),
        options[:modulepath]
      )
    end
  end

end

