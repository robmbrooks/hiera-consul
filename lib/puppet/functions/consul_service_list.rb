# Accepts up to 3 arguments, a service, an option property
# and options for Diplomat such as url.
# 
# Returns a list of nodes if no second argumet
# return list of the chosen key otherwise
#
Puppet::Functions.create_function(:consul_service_list) do
  require 'backports/2.5.0/hash' unless {}.respond_to? :slice
  require 'backports/rails/hash' unless {}.respond_to? :stringify_keys
  require 'diplomat'

  dispatch :consul_service_list do
    param          'String', :service
    optional_param 'String', :property
    optional_param 'Hash',   :filter
    optional_param 'Hash',   :options
  end

  def consul_service_list(service, property='Node', filter={}, options={})

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

    nodes.each_with_object([]) { |node,result|
      result << node[property] if filter.dup.deep_merge(node) == node
    }
  end
end
