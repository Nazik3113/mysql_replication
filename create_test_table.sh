#!/bin/bash

MASTER_NODE=hsa1021-mariadb-master
MASTER_PASS=mysqlmasterpass
MASTER_USER=root

DATABASE_NAME=hsa1021
TABLE_NAME=test

create_test_table_stmt='CREATE TABLE IF NOT EXISTS `'$DATABASE_NAME'`.`'$TABLE_NAME'` (`idtest` INT NOT NULL, `testcol1` VARCHAR(45) NULL, `testcol2` VARCHAR(45) NULL, `testcol3` VARCHAR(45) NULL, `testcol4` VARCHAR(45) NULL, PRIMARY KEY (`idtest`));'
docker exec $MASTER_NODE bash -c "export MYSQL_PWD=$MASTER_PASS; mariadb -u root -e '$create_test_table_stmt'"