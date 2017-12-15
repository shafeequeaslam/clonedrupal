#!/bin/bash
#Author: Shafeeque Aslam
#Script to clone drupal from one server to another ( devel server to developers home directory in developer's server ).

display_usage() { 
	figlet  "Admin ' s    Stuff ! !" 
	echo -e "Usage: $0 [ProjectName]  [Developers's name ]  \n" 
	} 

# if less than two arguments supplied, display usage 
if [  $# -le 1 ] 
	then 
	display_usage
	exit 1
fi 

if [ -d "/home/$2/$1-$2" ]; then
  read -p " $1-$2 Already exist in $2's home directory do you want to delete and continue.? " -n 1 -r
  echo    # (optional) move to a new line
	if [[ ! $REPLY =~ ^[Yy]$ ]]
        then
        exit # handle exits from shell or function but don't exit interactive shell
	fi
fi

rm -rf /home/$2/$1-$2

#Variables

ORIGIN_SERVER=
ORIGIN_SERVER_USER=
ORIGIN_SERVER_KEY=
ORIGIN_SERVER_SITES_LOCATION=
ORIGIN_SERVER_DB_PASSWD=
DESTINATION_SERVER_DB_PASSWD=

ssh -i $ORIGIN_SERVER_KEY  $ORIGIN_SERVER_USER@$ORIGIN_SERVER << EOF
	cd $ORIGIN_SERVER_SITE_LOCATION/$1
	drush ard --destination=/tmp/$1tmp.tgz
EOF


rsync -Pavzhe 'ssh -i $ORIGIN_SERVER_KEY' $ORIGIN_SERVER_USER@$ORIGIN_SERVER:/tmp/$1tmp.tgz  ~$2

ssh -i $ORIGIN_SERVER_KEY  $ORIGIN_SERVER_USER@$ORIGIN_SERVER << EOF
	rm -rf  /tmp/$1tmp.tgz
EOF

cd ~$2

mv *.sql drush-backups/ 

tar -xvf $1tmp.tgz

mv $1 $1-$2

rm -rf $1tmp.tgz

fdp $2 $1-$2

read -p " Files fetched from devel server. Replay with Y to continue with script or Choose N to manually deal with DB and settings files. " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
	then
    	exit # handle exits from shell or function but don't exit interactive shell
fi

sed -i s/$ORIGIN_SERVER_DB_PASSWD/$DESTINATION_SERVER_DB_PASSWD/g ./$1-$2/sites/default/settings.php

sed -i s/$1/$1$2/g ./$1-$2/sites/default/settings.php


mysql -u root -p -e "drop database $1$2;"

mysql -u root -p -e "create database $1$2;"

mysql -u root -p $1$2 < *.sql

rm -rf MANIFEST.ini

rm -rf ./*.sql


chown $2:www-data $1-$2  -R 

find $1-$2 -type d -exec chmod 775 {} + 
find $1-$2 -type f -exec chmod 664 {} + 

