Puppet::Functions.create_function(:hiera_consul) do
  begin
    require 'diplomat'
  rescue LoadError
    raise Puppet::DataBinding::LookupError, "Error loading diplomat gem library."
  end

  dispatch :consul_data_hash do
    param 'Hash', :options
    param 'Puppet::LookupContext', :context
  end

  def consul_data_hash(options, context)
    Diplomat.configure do |config|
      # Set up a custom Consul URL
      config.url = options['url'] if options.key?('url')
      # Set up a custom Faraday Middleware
      config.middleware = options['middleware'] if options.key?('middleware')
      # Set extra Faraday configuration options and custom access token (ACL)
      config.options = options['options'] if options.key?('options')
    end
    begin
      kv = Diplomat::Kv.get('/', recurse: true, convert_to_hash: true)
    rescue
      context.not_found
    end
    return kv
  end
end
