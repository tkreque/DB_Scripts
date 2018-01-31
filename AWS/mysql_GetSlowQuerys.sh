#!/bin/bash

#################################################
#												#
#				AWS Get Slow Query Log			#
#	Created by - Thiago Reque					#
#			Date: 			30/01/2018			#
#			Last changed:	30/01/2018			#
#												#
#	Change log:									#
#		- Created the script					#
#												#
#################################################


# Ask the path of the temp and final file
echo "Path to file"
read PATHFILE

# Ask the instance to connect
echo "MySQL Instance"
read MYSQL

# Ask the user
echo "User"
read MYSQLU

# Ask the password
echo "Password"
read MYSQLP

# Adjust the path
if [[ $PATHFILE != */ ]]; then 
	PATHFILE=$PATHFILE'/'
fi

# Set filename
FILENAME="SlowQuery-`date +%Y-%m-%d_%H-%M`-$MYSQL.txt"

# Generate the temp file
if mysql -u$MYSQLU -p$MYSQLP -h $MYSQL -D mysql -s -r -e "SELECT CONCAT( '# Time: ', DATE_FORMAT(start_time, '%y%m%d %H%i%s'), '\n', '# User@Host: ', user_host, '\n', '# Query_time: ', TIME_TO_SEC(query_time),  '  Lock_time: ', TIME_TO_SEC(lock_time), '  Rows_sent: ', rows_sent, '  Rows_examined: ', rows_examined, '\n', sql_text, ';' ) FROM mysql.slow_log WHERE start_time > now() - interval 2 day AND user_host NOT IN ('rdsadmin[rdsadmin] @ localhost [127.0.0.1]') AND db NOT IN ('mysql','information_schema','tmp','performance_schema','sys','innodb') AND sql_text NOT LIKE '%ApplicationName=DBeaver%' AND sql_text NOT LIKE '%mysql.slow_log%'" > $PATHFILE/mysql.slow_log.log; then

	# Generate the final file
	# Require percona-toolkit (sudo apt install percona-toolkit)
	if pt-query-digest --limit 100% $PATHFILE/mysql.slow_log.log > $PATHFILE/$FILENAME; then

		# Remove the temp file
		if rm $PATHFILE/mysql.slow_log.log; then

			# Show the file created
			ls -ltrh $PATHFILE/$FILENAME
		else
			echo "Error - Not able to remove temporary file! Check and try again!"
		fi
	else
		echo "Error - Not able to generate the file! Check and try again! (Maybe you need to instal percona-toolkit ;)"
	fi
else
	echo "Error - Not able to connect to MySQL! Check and try again!"
fi