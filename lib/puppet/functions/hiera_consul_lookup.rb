Puppet::Functions.create_function(:hiera_consul_lookup) do
  begin
    require 'deep_merge'
    require 'diplomat'
    require 'backports' unless {}.respond_to? :dig
  rescue LoadError => err
    raise Puppet::DataBinding::LookupError, "Error loading required gems for hiera_consul: " + err.to_s
  end

  dispatch :consul_data_hash do
    param 'Hash', :options
    param 'Puppet::LookupContext', :context
  end

  def consul_data_hash(options, context)
    options['search'] =  [''] unless options.key?('search')
    Diplomat.configure do |config|
      # Set up a custom Consul URL
      config.url = options['url'] if options.key?('url')
      # Set up a custom Faraday Middleware
      config.middleware = options['middleware'] if options.key?('middleware')
      # Set extra Faraday configuration options and custom access token (ACL)
      config.options = options['options'] if options.key?('options')
    end
    options['search'].map { |search|
      diplomat_kv_get(search)
    }.reduce(:deep_merge)
  end

  def diplomat_kv_get(search)
    begin
      kv = Diplomat::Kv.get(search + '/', recurse: true, convert_to_hash: true)
      search_path = search.split('/')
      search_path.length.zero? ? kv : kv.dig(*search_path)
    rescue
      return {}
    end
  end
end
