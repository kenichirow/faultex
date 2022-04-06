# FaultexExample

```bash
mix deps.get

# start server at localhost:4040
mix run --no-halt
```

```bash
$ curl localhost:4040/example1
> OK

$ curl localhost:4040/example1 -H 'x-example-fault-inject:true'
> request failed
```
