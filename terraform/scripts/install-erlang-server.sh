#!/bin/bash
#  https://brad-simonin.medium.com/learning-how-to-execute-a-bash-script-from-terraform-for-aws-b7fe513b6406

echo 'Preparing workspace...'
mkdir Workspace && cd Workspace
export HOME=/root

# Pulls repository with my Erlang server.
echo 'Pulling repo...'
# TODO: Do not hardcode repo URL
git clone https://github.com/apetrisor1/erlangseatsserver.git
apt-get -y update

# Pulls Erlang binaries and installs.
# TODO: Do not hardcode Erlang URL
echo 'Pulling Erlang and installing...'
curl https://packages.erlang-solutions.com/erlang/debian/pool/esl-erlang_23.3.4.5-1~ubuntu~focal_amd64.deb > erlanginstaller
dpkg -i /Workspace/erlanginstaller
apt-get install -y -f
rm /Workspace/erlanginstaller

#  Fixes some missing packages, required by esl-erlang.
echo 'Fixing broken packages...'
yes | apt --fix-broken install

#  Install Docker Engine
echo 'Installing Docker Engine...'
apt-get install -y ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get -y update
apt-get install -y docker-ce docker-ce-cli containerd.io

#  Install Docker Compose
echo 'Installing Docker Compose...'
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

#  Install ODBC Driver
echo 'Installing ODBC Driver...'
apt-get install -y odbc-postgresql
apt-get install -y unixodbc-dev

#  Install Rebar3
echo 'Installing Rebar3...'
wget https://s3.amazonaws.com/rebar3/rebar3 && chmod +x rebar3
apt-get install -y build-essential

/Workspace/rebar3 update
/Workspace/rebar3 upgrade
/Workspace/rebar3 clean

#  Configure ODBC settings (for DB connection).
echo 'Configuring ODBC files...'
rm /etc/odbcinst.ini

# TODO: Would probably be better to store these in my repo
echo '[PostgreSQL ANSI]
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
UsageCount=1' > /etc/odbcinst.ini

rm /etc/odbc.ini
echo '[ODBC Data Sources]
erlang-db-data-source="Postgresql database for my Erlang App"

[erlang-db-data-source]
Driver=PostgreSQL Unicode
Description=PostgreSQL Data Source
Servername=localhost
Port=5432
UserName=postgres
Password=postgres
Database=erlang' > /etc/odbc.ini
# TODO: Do not hardcode DB user and password above (why do they live in that file anyway?)

#  Go to project root
cd erlangseatsserver

#  Start PostgreSQL via Docker.
echo 'Starting Postgres via Docker Compose...'
docker-compose -f docker-compose.yml up -d

#  Do DB migrations.
echo 'Do DB migrations'
sleep 5 && cat ./apps/venues_configurator/src/services/database_services/migrations.sql \
  | docker exec -i $(docker ps | grep postgres | awk '{print $1;}') psql -U postgres -d erlang
# TODO: Do not hardcode DB user and password
# TODO: Do not hardcode migrations file location

#  Build & Start as daemon.
echo 'Starting app...'
/Workspace/rebar3 release
_build/default/rel/venues_configurator/bin/venues_configurator daemon

# TODO: route stdout to some file.
#_build/default/rel/venues_configurator/bin/venues_configurator daemon_attach | tee /var/log/web.stdout.log >/dev/null