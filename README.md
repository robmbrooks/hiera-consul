Consul query tools
==================

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
