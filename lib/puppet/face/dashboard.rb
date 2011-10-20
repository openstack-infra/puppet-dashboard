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

  action 'list' do
    summary 'list all of a certain type from the dashboard, this currently supports the ability to list: classes, nodes, and groups'
    when_invoked do |type, options|
      type_map = {'classes' => 'node_classes', 'nodes' => 'nodes', 'groups' => 'node_groups'}
      connection = Puppet::Dashboard::Classifier.connection(options)
      connection.list(type_map[type], "Listing #{type}")
    end
  end
end

