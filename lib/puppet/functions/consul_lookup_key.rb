# The `consul_lookup_key` is a hiera 5 `lookup_key` backend function.
# See (https://puppet.com/docs/puppet/latest/hiera_custom_backends.html) for
# more info.
#
# See README.md#hiera-backend for usage.
#
Puppet::Functions.create_function(:consul_lookup_key) do
  require 'deep_merge'
  require 'diplomat'
  # require 'backports' unless {}.respond_to? :dig

  dispatch :consul_lookup_key do
    param 'String[1]', :key
    param 'Hash', :options
    param 'Puppet::LookupContext', :context
  end

  def consul_lookup_key(key, options, context)
    return context.cached_value(key) if context.cache_has_key(key)

    options['search'] =  [''] unless options.key?('search')

    if context.cache_has_key(nil)
      consul_data = context.cached_value(nil)
    else
      Diplomat.configure do |config|
        # Set up a custom Consul URL
        config.url = options['url'] if options.key?('url')
        # Set up a custom Faraday Middleware
        config.middleware = options['middleware'] if options.key?('middleware')
        # Set extra Faraday configuration options and custom access token (ACL)
        config.options = options['options'] if options.key?('options')
      end

      consul_data = options['search'].map { |search|
        diplomat_kv_get(search)
      }.reduce(:deep_merge)

      context.cache_all(consul_data)
      context.cache(nil,consul_data)
    end

    if consul_data.include?(key)
      return consul_data[key]
    else
      return context.not_found
    end
  end

  def diplomat_kv_get(search)
    begin
      kv = Diplomat::Kv.get(search + '/', recurse: true, convert_to_hash: true)
      kv.delete('vault')
      search_path = search.split('/')
      search_path.length.zero? ? kv : kv.dig(*search_path)
    rescue
      return {}
    end
  end
end
