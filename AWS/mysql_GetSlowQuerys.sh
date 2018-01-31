#!/bin/bash

#################################################
#												#
#				AWS RDS search by Tag			#
#	Created by - Thiago Reque					#
#			Date: 			15/01/2018			#
#			Last changed:	15/01/2018			#
#												#
#	Change log:									#
#		- Created the script					#
#												#
#################################################


# Ask the format or gets the default
echo "Path to file"
read PATHFILE

# Ask the format or gets the default
echo "MySQL Instance"
read MYSQL

# Ask the format or gets the default
echo "User"
read MYSQLU

# Ask the format or gets the default
echo "Password"
read MYSQLP

FILENAME="SlowQuery-`date +%Y-%m-%d_%H-%M`-$MYSQL.txt"

mysql -u$MYSQLU -p$MYSQLP -h $MYSQL -D mysql -s -r -e "SELECT CONCAT( '# Time: ', DATE_FORMAT(start_time, '%y%m%d %H%i%s'), '\n', '# User@Host: ', user_host, '\n', '# Query_time: ', TIME_TO_SEC(query_time),  '  Lock_time: ', TIME_TO_SEC(lock_time), '  Rows_sent: ', rows_sent, '  Rows_examined: ', rows_examined, '\n', sql_text, ';' ) FROM mysql.slow_log WHERE start_time > now() - interval 2 day AND user_host NOT IN ('rdsadmin[rdsadmin] @ localhost [127.0.0.1]') AND db NOT IN ('mysql','information_schema','tmp','performance_schema','sys','innodb') AND sql_text NOT LIKE '%ApplicationName=DBeaver%' AND sql_text NOT LIKE '%mysql.slow_log%'" > $PATHFILE/mysql.slow_log.log
pt-query-digest --limit 100% $PATHFILE/mysql.slow_log.log > $PATHFILE/$FILENAME
rm $PATHFILE/mysql.slow_log.log

ls -ltrh $PATHFILE/$FILENAME