gen_rest_api
=====
Small back-end in Erlang.
MongoDB, Postgres, JWT , authorization, validation.

Build
-----

    $ rebar3 shell


Databases
-----

Mongo:

Make sure mongo daemon is running locally, connect(localhost, 27017) in db.erl

TODO: Link app to postgress.

You can spin up the postgres Docker image locally using
```
    $ docker-compose -f docker-compose.yml up
```

You can see it under open processes using: 
```
    $ docker ps
```

Connect to it via terminal:
```
    $ docker exec -it <container_name> bash
    $ psql -U postgress
```