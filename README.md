Install
-------

```
apt-get -y update
```

1. Get the URL link to the Erlang/OTP .deb binary file from https://www.erlang-solutions.com/downloads/

(Stick with release 23)
```
curl <link> —output erlanginstaller
```
2. Install it
```
sudo dpkg -i /absolute/path/to/deb/file
sudo apt-get install -f
```
May be needed
```
apt --fix-broken install
```
3. Install Docker Engine
4. Install Docker Compose
5. Install ubuntu ODBC driver (Erlang has an ODBC interface)
```
sudo apt-get install -y odbc-postgresql
sudo apt-get install -y unixodbc-dev
```

6. Install rebar3
```
wget https://s3.amazonaws.com/rebar3/rebar3 && chmod +x rebar3
export PATH=$PATH:/Workspace
```

7. Pull this repo (build in repo root)
```
git clone https://github.com/apetrisor1/erlangseatsserver.git
```

Start Postgres
--------------

8. Update /etc/odbcinst.ini with
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

9. Update /etc/odbc.ini config file with:
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

To use the connection, we will use the Erlang API, see section 2.2 from
https://erlang.org/doc/apps/odbc/getting_started.html

For the value of DSN, you will use the name declared in 4.
```{ok, Ref} = odbc:connect("DSN=erlang-db-data-source;UID=postgres;PWD=postgres", []).```

10. Start PostgreSQL via docker

```
    $ docker-compose -f docker-compose.yml up
```

You can see it under open processes using: 
```
    $ docker ps
```
Optionally, connect to it via terminal (we will do the DB migrations from this psql CLI):
```
    $ docker exec -it <container_name> bash
    $ psql -U postgress
```

11. Do database migrations. (run the queries in: apps/venues_configurator/src/services/database_services/migrations.sql)

Build & Start
-------------

    $ rebar3 shell

When using the server on the the cloud alongside other apps on the same machine, or if priced by CPU cycles,
add these lines to vm.args, to disable busy waits on the BEAM:

```
+sbwt none
+sbwtdcpu none
+sbwtdio none
```
