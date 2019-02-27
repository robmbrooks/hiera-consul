Consul query tools
==================

Puppet functions
----------------

### consul_service

`consul_service(service, [properties], [filter], [options])`

Provides service data from consul as a hash.


### consul_service_list

`consul_service(service, [property], [filter], [options])`

Provides service data from consul as a list.

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
