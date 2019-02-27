Consul query tools
==================

Puppet functions
----------------

### consul_service

`consul_service(service, [properties], [filter], [options])`

Provides service data from consul as a hash.

```consul_service('consul', ['Node', 'Address'], { 'Datacenter' => 'dc1' }, { 'url' => 'http://example:8500' })
# { 'consul1' => { 'Node' => 'consul1', 'Address' => '10.0.0.1' } , 'consul2' => { 'Node' => 'consul2', 'Address' => '10.0.0.2' }```



### consul_service_list

`consul_service(service, [property], [filter], [options])`

Provides service data from consul as a list.

```consul_service('consul', 'Address', { 'Datacenter' => 'dc1' }, { 'url' => 'http://example:8500' })
# [ '10.0.0.1', '10.0.0.2', ]```

Hiera backend
-------------

```  - name: "Consul"
    data_hash: hiera_consul_lookup
    options:
      url: "http://consul.service.consul:8500"
      search:
        - "%{::environment}"
        - ""
```
