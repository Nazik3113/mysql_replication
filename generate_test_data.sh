#!/bin/bash

MASTER_NODE=hsa1021-mariadb-master
MASTER_PASS=mysqlmasterpass
MASTER_USER=root

DATABASE_NAME=hsa1021
TABLE_NAME=test

ITERATIONS=5

MIN=10
MAX=1000

for (( iterations=1; iterations<=$ITERATIONS; iterations++ ))
do  
   random_int=$(($RANDOM % $MAX + $MIN))

    create_test_record_stmt='INSERT INTO `'$DATABASE_NAME'`.`'$TABLE_NAME'` (`idtest`, `testcol1`, `testcol2`, `testcol3`, `testcol4`) VALUES ("'$random_int'", "'$random_int'", "'$random_int'", "'$random_int'", "'$random_int'");'
    docker exec $MASTER_NODE bash -c "export MYSQL_PWD=$MASTER_PASS; mariadb -u root -e '$create_test_record_stmt'"
done