#!/bin/bash

docker-compose down -v
mkdir -p ./master/data 
rm -rf ./master/data/*
mkdir -p ./slave1/data 
rm -rf ./slave1/data/*
mkdir -p ./slave2/data
rm -rf ./slave2/data/*
docker-compose build
docker-compose up -d

BIN_LOG_FORMAT=ROW

MASTER_NODE=hsa1021-mariadb-master
MASTER_PASS=mysqlmasterpass
MASTER_USER=root

SLAVE1_NODE=hsa1021-mariadb-slave1
SLAVE1_PASS=mysqlslave1pass
SLAVE1_USER=root
SLAVE1_REPLICATION_USER=slave1
SLAVE1_REPLICATION_PASS=mysqlslave1replicapass

SLAVE2_NODE=hsa1021-mariadb-slave2
SLAVE2_PASS=mysqlslave2pass
SLAVE2_USER=root
SLAVE2_REPLICATION_USER=slave2
SLAVE2_REPLICATION_PASS=mysqlslave2replicapass

until docker exec $MASTER_NODE bash -c "export MYSQL_PWD=$MASTER_PASS; mariadb -u $MASTER_USER -e ';'"
do
    echo "Waiting for mysql_master database connection..."
    sleep 4
done

grant_replication1_stmt='GRANT REPLICATION SLAVE ON *.* TO "'$SLAVE1_REPLICATION_USER'"@"%" IDENTIFIED BY "'$SLAVE1_REPLICATION_PASS'";FLUSH PRIVILEGES;'
docker exec $MASTER_NODE bash -c "export MYSQL_PWD=$MASTER_PASS; mariadb -u $MASTER_USER -e '$grant_replication1_stmt'"

grant_replication2_stmt='GRANT REPLICATION SLAVE ON *.* TO "'$SLAVE2_REPLICATION_USER'"@"%" IDENTIFIED BY "'$SLAVE2_REPLICATION_PASS'";FLUSH PRIVILEGES;'
docker exec $MASTER_NODE bash -c "export MYSQL_PWD=$MASTER_PASS; mariadb -u $MASTER_USER -e '$grant_replication2_stmt'"

bin_log_format_master_stmt='SET GLOBAL binlog_format = "'$BIN_LOG_FORMAT'";'
docker exec $MASTER_NODE bash -c "export MYSQL_PWD=$MASTER_PASS; mariadb -u $MASTER_USER -e '$bin_log_format_master_stmt'"

until docker exec $SLAVE1_NODE bash -c "export MYSQL_PWD=$SLAVE1_PASS; mariadb -u $SLAVE1_USER -e ';'"
do
    echo "Waiting for mysql_slave1 database connection..."
    sleep 4
done

MS_STATUS_SLAVE1=$(docker exec $MASTER_NODE bash -c "export MYSQL_PWD=$MASTER_PASS; mariadb -u $MASTER_USER -e 'SHOW MASTER STATUS'")

CURRENT_LOG_SLAVE1=`echo $MS_STATUS_SLAVE1 | awk '{print $5}'`
CURRENT_POS_SLAVE1=`echo $MS_STATUS_SLAVE1 | awk '{print $6}'`

echo current log: $CURRENT_LOG_SLAVE1
echo current pos: $CURRENT_POS_SLAVE1

bin_log_format_slave1_stmt='SET GLOBAL binlog_format = "'$BIN_LOG_FORMAT'";'
docker exec $SLAVE1_NODE bash -c "export MYSQL_PWD=$SLAVE1_PASS; mariadb -u $SLAVE1_USER -e '$bin_log_format_slave1_stmt'"

start_slave1_stmt='CHANGE MASTER TO MASTER_HOST="'$MASTER_NODE'", MASTER_USER="'$SLAVE1_REPLICATION_USER'", MASTER_PASSWORD="'$SLAVE1_REPLICATION_PASS'", MASTER_LOG_FILE="'$CURRENT_LOG_SLAVE1'", MASTER_LOG_POS='$CURRENT_POS_SLAVE1'; START SLAVE;'
docker exec $SLAVE1_NODE bash -c "export MYSQL_PWD=$SLAVE1_PASS; mariadb -u $SLAVE1_USER -e '$start_slave1_stmt'"

SLAVE1_STATUS=$(docker exec $SLAVE1_NODE bash -c "export MYSQL_PWD=$SLAVE1_PASS; mariadb -u $SLAVE1_USER -e 'SHOW SLAVE STATUS \G'")

echo slave1 status: $SLAVE1_STATUS

until docker exec $SLAVE2_NODE bash -c "export MYSQL_PWD=$SLAVE2_PASS; mariadb -u $SLAVE2_USER -e ';'"
do
    echo "Waiting for mysql_slave2 database connection..."
    sleep 4
done

MS_STATUS_SLAVE2=$(docker exec $MASTER_NODE bash -c "export MYSQL_PWD=$MASTER_PASS; mariadb -u $SLAVE2_USER -e 'SHOW MASTER STATUS'")

CURRENT_LOG_SLAVE2=`echo $MS_STATUS_SLAVE2 | awk '{print $5}'`
CURRENT_POS_SLAVE2=`echo $MS_STATUS_SLAVE2 | awk '{print $6}'`

echo current log: $CURRENT_LOG_SLAVE2
echo current pos: $CURRENT_POS_SLAVE2

bin_log_format_slave2_stmt='SET GLOBAL binlog_format = "'$BIN_LOG_FORMAT'";'
docker exec $SLAVE2_NODE bash -c "export MYSQL_PWD=$SLAVE2_PASS; mariadb -u $SLAVE2_USER -e '$bin_log_format_slave2_stmt'"

start_slave2_stmt='CHANGE MASTER TO MASTER_HOST="'$MASTER_NODE'", MASTER_USER="'$SLAVE2_REPLICATION_USER'", MASTER_PASSWORD="'$SLAVE2_REPLICATION_PASS'", MASTER_LOG_FILE="'$CURRENT_LOG_SLAVE2'", MASTER_LOG_POS='$CURRENT_POS_SLAVE2'; START SLAVE;'
docker exec $SLAVE2_NODE bash -c "export MYSQL_PWD=$SLAVE2_PASS; mariadb -u $SLAVE2_USER -e '$start_slave2_stmt'"

SLAVE2_STATUS=$(docker exec $SLAVE2_NODE bash -c "export MYSQL_PWD=$SLAVE2_PASS; mariadb -u $SLAVE2_USER -e 'SHOW SLAVE STATUS \G'")

echo slave2 status: $SLAVE2_STATUS