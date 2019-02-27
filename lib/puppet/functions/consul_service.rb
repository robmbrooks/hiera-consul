# Accepts up to 3 arguments, a service, a list of properties
# and options for Diplomat such as url.
# 
# Returns a hash of nodes filtered to selected keys
# or all properties if no second argument.
#
Puppet::Functions.create_function(:consul_service) do
  require 'backports/2.5.0/hash' unless {}.respond_to? :slice
  require 'backports/rails/hash' unless {}.respond_to? :stringify_keys
  require 'deep_merge'
  require 'diplomat'

  dispatch :consul_service do
    param          'String', :service
    optional_param 'Array',  :properties
    optional_param 'Hash',   :filter
    optional_param 'Hash',   :options
  end

  def consul_service(service, properties=false, filter={}, options={})
    property_filters = [] 
    property_filters << [ :slice ] + properties if properties


    Diplomat.configure do |config|
      # Set up a custom Consul URL
      config.url = options['url'] if options.key?('url')
      # Set up a custom Faraday Middleware
      config.middleware = options['middleware'] if options.key?('middleware')
      # Set extra Faraday configuration options and custom access token (ACL)
      config.options = options['options'] if options.key?('options')
    end

    begin
      nodes = (Diplomat::Service.get(service, :all,)).map { |node| node.to_h.stringify_keys }
    rescue => err
      raise Puppet::ParseError, "Consul lookup failed: " + err.to_s
    end

    nodes.each_with_object({}) { |node, result|
      next unless filter.dup.deep_merge(node) == node
      result[node['Node']] = property_filters.inject(node) { |obj, method_and_args| obj.send(*method_and_args) }
    }

  end
end
