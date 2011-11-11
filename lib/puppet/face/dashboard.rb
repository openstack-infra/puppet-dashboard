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
      connection.list(type_name, "Listing #{type}", options)
    end
  end
  # 422 for create node - means it does not exist

  {'node' => ['node', 'nodes'], 'class' => ['node_class', 'node_classes']}.each do |type, dash_type|
    action "create_#{type}" do
      option '--name=' do
        required
      end
      when_invoked do |options|
        data = { dash_type[0] => { 'name' => options[:name] } }
        connection = Puppet::Dashboard::Classifier.connection(options)
        connection.create(dash_type[1], "Creating #{type} #{options[:name]}", data, options)
      end
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
      Puppet[:modulepath] = options[:modulepath]
      (Puppet::Face[:resource_type, :current].search(options[:module_name]) || []).collect do |resource_type|
        # I am not going to bother checking that everything we find is loadable
        # This patch assumes that the modules are properly organized
        if resource_type.type == :hostclass
          options.delete(:module_name)
          options.delete(:modulepath)
          Puppet::Face[:dashboard, :current].create_class(options.merge(:name => resource_type.name))
          resource_type.name
        else
          nil
        end
      end.compact
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
      Dir.chdir(options[:modulepath].split(':').first) do
        options[:module_name].split(',').each do |module_name|
          # install the module into the modulepath
          `puppet module install #{module_name}`
          author, puppet_module = module_name.split('-', 2)
          override_hash = if puppet_module
            {:module_name => puppet_module }
          else
            {:module_name => module_name }
          end
          Puppet::Face[:dashboard, :current].register_module(options.merge(override_hash))
          # do nothing
        end
      end
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

