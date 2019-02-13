require 'backports/2.5.0/hash' unless {}.respond_to? :slice
require 'backports/rails/hash' unless {}.respond_to? :stringify_keys
require 'deep_merge'
require 'diplomat'

module Puppet::Parser::Functions
  newfunction(:consul_service, :type => :rvalue, :doc => <<-EOS
Parse the incoming consul info and return a value
    EOS
  ) do |args|

    options = {}
    filters = [] 

    service  = args[0]

    filters << [ :slice ] + args[1] if args[1] 
    options = args[2] if args[2]

    Diplomat.configure do |config|
      # Set up a custom Consul URL
      config.url = options['url'] if options.key?('url')
      # Set up a custom Faraday Middleware
      config.middleware = options['middleware'] if options.key?('middleware')
      # Set extra Faraday configuration options and custom access token (ACL)
      config.options = options['options'] if options.key?('options')
    end
    nodes = Diplomat::Service.get(service, :all)

    nodes.each_with_object({}) { |node, result|
      result[node[:Node]] = filters.inject(node.to_h.stringify_keys) { |obj, method_and_args| obj.send(*method_and_args) }
    }
  end
end
