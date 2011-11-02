require 'puppet/face'
require 'puppet/dashboard/classifier'
Puppet::Face.define(:dashboard, '0.0.1') do
  option '--enc-server=' do
    summary 'The External Node Classifier URL.'
    description <<-EOT
      The URL of the External Node Classifier.
      This currently only supports the Dashboard
      as an external node classifier.
    EOT
    default_to do
      Puppet[:server]
    end
  end

  option '--enc-port=' do
    summary 'The External Node Classifier Port'
    description <<-EOT
      The port of the External Node Classifier.
      This currently only supports the Dashboard
      as an external node classifier.
    EOT
    default_to do
      3000
    end
  end
  # 404 cannot connect to URL
  # 500 database could be turned off (internal
  action 'list' do
    summary 'list all of a certain type from the dashboard, this currently supports the ability to list: classes, nodes, and groups'
    when_invoked do |type, options|
      type_map = {'classes' => 'node_classes', 'nodes' => 'nodes', 'groups' => 'node_groups'}
      connection = Puppet::Dashboard::Classifier.connection(options)
      connection.list(type_map[type], "Listing #{type}")
    end
  end
  # 422 for create node - means it does not exist
  action 'create_node' do
    option '--name=' do
      required
    end
    when_invoked do |options|
      data = { 'node' => { 'name' => options[:name] } }
      connection = Puppet::Dashboard::Classifier.connection(options)
      connection.create('nodes', "Creating node", data)
    end
  end
  # 422 for create class - means it does not exist
  action 'create_class' do
    option '--name=' do
      required
    end
    when_invoked do |options|
      data = { 'node_class' => { 'name' => options[:name] } }
      connection = Puppet::Dashboard::Classifier.connection(options)
      connection.create('node_classes', "Creating class", data)
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
      connection.create('node_groups', "Creating group", data)
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
      connection.create('memberships', "Adding group to node", data)
    end
  end

end

