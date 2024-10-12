#!/bin/sh

# ***************************************************************************************************************************************
#  * install-config-psql.sh                                                                                                             *
#  **************************************************************************************************************************************
#  *                                                                                                                                    *
#  * @License Starts                                                                                                                    *
#  *                                                                                                                                    *
#  * Copyright © 2024. MongoExpUser.  All Rights Reserved.                                                                              *
#  *                                                                                                                                    *
#  * License: Apache 2.0 - https://github.com/MongoExpUser/Automated-Incremental-Backup-Of-Ubuntu-Based-PostgreSQL/blob/main/LICENSE    *
#  *                                                                                                                                    *
#  * @License Ends                                                                                                                      *
#  **************************************************************************************************************************************
# *                                                                                                                                     *
# *  Project: Automated Incremental Backup On Ubuntu-Based PostgreSQL (Require PostgreSQL 17+)                                          *
# *                                                                                                                                     *
# *  This script:                                                                                                                       *
# *                                                                                                                                     *
# *     1)  Installs and configures  PostgreSQL 17                                                                                      *
# *                                                                                                                                     *
# ***************************************************************************************************************************************

# ***************************************************************************************************************************************
#  Run the script with following command                                                                                                *
#  -------------------------------------------------------------------------------------------------------------------------------------*
#  sudo bash  install-config-psql.sh                                                                                                    *
# ***************************************************************************************************************************************



architecture='x86_64' # or 'aarch64'

install()
{
    # postgresql
    sudo apt install curl ca-certificates
    sudo install -d /usr/share/postgresql-common/pgdg
    sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
    sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    sudo apt update
    sudo apt -y install postgresql-17
    # other relevant packages
    sudo apt install zip unzip
    # aws-cli v2
    sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-${architecture}.zip" -o "awscliv2.zip"
    sudo chmod 777 awscliv2.zip
    sudo unzip awscliv2.zip
    sudo ./aws/install
    sudo aws --version
}

configure()
{
    # a. sleep for , set summarize_wal, reload and confirm - note: summarize_wal is a parameter in the postgresql.conf file
    sudo sleep 10
    sudo -u postgres psql -c "ALTER SYSTEM SET summarize_wal = 'ON';"
    sudo -u postgres psql -c "SELECT pg_reload_conf();"
    sudo -u postgres psql -c "SHOW summarize_wal;"
    sudo -u postgres psql -c "CREATE ROLE backup_user WITH CREATEROLE CREATEDB LOGIN ENCRYPTED PASSWORD 'mypasd';"
    sudo -u postgres psql -c "ALTER ROLE backup_user WITH SUPERUSER;"
    # b. stop server and update pg_hba.conf file: ensure the modified pg_hba.conf file is in the current working directory (CWD)
    sudo service postgresql stop
    sudo cp /etc/postgresql/17/main/pg_hba.conf /etc/postgresql/17/main/pg_hba.conf.backup
    sudo cp pg_hba.conf /etc/postgresql/17/main/
    sudo chmod 777 /etc/postgresql/17/main/pg_hba.conf
    sudo ls -lhs /etc/postgresql/17/main/
}

main()
{
    install
    configure
    sudo service postgresql start
}


main
