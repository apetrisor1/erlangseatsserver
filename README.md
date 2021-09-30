Build
-----

    $ rebar3 shell

# Postgres:

1. Start PostgreSQL via docker

```
    $ docker-compose -f docker-compose.yml up
```

You can see it under open processes using: 
```
    $ docker ps
```
Optionally, connect to it via terminal:
```
    $ docker exec -it <container_name> bash
    $ psql -U postgress
```

2. Install ubuntu ODBC driver (Erlang has an ODBC interface)
apt-get install odbc-postgresql

3. Update /etc/odbcinst.ini with
```
[PostgreSQL ANSI]
Description=PostgreSQL ODBC driver (ANSI version)
Driver=/usr/lib/x86_64-linux-gnu/odbc/psqlodbca.so
Setup=libodbcpsqlS.so
Debug=0
CommLog=1
UsageCount=1

[PostgreSQL Unicode]
Description=PostgreSQL ODBC driver (Unicode version)
Driver=/usr/lib/x86_64-linux-gnu/odbc/psqlodbcw.so
Setup=libodbcpsqlS.so
Debug=0
CommLog=1
UsageCount=1
```
Notice how the driver in this file points to the location in /usr/lib.
The driver also gets the name declared in square brackets, to be used next.

4. Update /etc/odbc.ini config file with:
```
[ODBC Data Sources]
erlang-db-data-source = "Postgresql database for my Erlang App"

[erlang-db-data-source]
Driver = PostgreSQL Unicode
Description = PostgreSQL Data Source
Servername = localhost
Port = 5432
UserName = postgres
Password = postgres
Database = erlang
```
Notice how this file points to the driver using the name declared in square brackets in
```odbcinst.ini.```

5. To test the connection, you can use the Erlang API, see section 2.2 from
https://erlang.org/doc/apps/odbc/getting_started.html

For now we will use this API when connecting the main app robust.
An alternative is using this:
https://github.com/epgsql/epgsql

For the value of DSN, you will use the name declared in 4.
```{ok, Ref} = odbc:connect("DSN=erlang-db-data-source;UID=postgres;PWD=postgres", []).```