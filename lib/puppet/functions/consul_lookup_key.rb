# The `consul_lookup_key` is a hiera 5 `lookup_key` backend function.
# See (https://puppet.com/docs/puppet/latest/hiera_custom_backends.html) for
# more info.
#
# See README.md#hiera-backend for usage.
#
Puppet::Functions.create_function(:consul_lookup_key) do
  begin
    require 'deep_merge'
    require 'diplomat'
    require 'backports' unless {}.respond_to? :dig
  rescue LoadError => err
    raise Puppet::DataBinding::LookupError, "Error loading required gems for hiera_consul: " + err.to_s
  end

  dispatch :consul_lookup_key do
    param 'String[1]', :key
    param 'Hash', :options
    param 'Puppet::LookupContext', :context
  end

  def consul_lookup_key(key, options, context)
    options['search'] =  [''] unless options.key?('search')
    options['mount'] = 'consul' unless options.key?('mount')

    unless key == options['mount']
      context.explain() { "skipping this backend as #{key} not under path of mount at #{options['mount']}" }

      return context.not_found
    end

    if context.cache_has_key(key)
      context.explain() { 'cached value present returning from cache' }
      return context.cached_value(key)
    end

    context.explain() { 'cached value not found performing consul lookup' }

    consul_data = options['search'].map { |search|
        diplomat_kv_get(search,context,options)
    }.reduce(:deep_merge)

    return context.cache(key, consul_data)
  end

  def diplomat_kv_get(search,context,options)
    return context.cached_value("__#{search}") if context.cache_has_key("__#{search}")
    begin
      Diplomat.configure do |config|
        # Set up a custom Consul URL
        config.url = options['url'] if options.key?('url')
        # Set up a custom Faraday Middleware
        config.middleware = options['middleware'] if options.key?('middleware')
        # Set extra Faraday configuration options and custom access token (ACL)
        config.options = options['options'] if options.key?('options')
      end

      kv = Diplomat::Kv.get(search + '/', recurse: true, convert_to_hash: true)
      kv.delete('vault')
      search_path = search.split('/')
      context.cache("__#{search}", search_path.length.zero? ? kv : kv.dig(*search_path))
    rescue
      return {}
    end
  end
end
