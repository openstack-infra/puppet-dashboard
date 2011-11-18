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
    option '--parameters=' do
      summary 'Parameter that should be added to the node'
      description <<-EOT
        Param that should be added to node. This is only expected to
        be specified programmatically.
      EOT
    end
    option '--classes=' do
      summary 'a comma delimited list of classes'
    end
    option '--groups=' do
      summary 'a list of groups to add to the node'
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
    option '--name=' do
      summary 'Name of class to create in the dashboard'
      required
    end
    when_invoked do |options|
      Puppet::Dashboard::Classifier.connection(options).create_classes([options[:name]])
    end
  end

  action 'create_group' do
    option '--name=' do
      summary 'Name of the group to be created'
      required
    end
    option '--parameters=' do
      description <<-EOT
        This is only intended to be used programmatically.
      EOT
    end
    option '--parent-groups=' do
      summary 'The parent groups'
    end
    option '--classes=' do
      summary 'classes to add to the group'
    end
    when_invoked do |options|
      Puppet::Dashboard::Classifier.connection(options).create_group(
        options[:name],
        options[:parameters],
        options[:parent_groups],
        Puppet::Dashboard::Classifier.to_array(options[:classes])
      )
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

end

