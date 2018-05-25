#!/bin/bash
VERSION="0.1"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

echo "#============================================================"
echo "#= shift_restore.sh v0.1 created by mavnezz                 ="
echo "#= Please consider voting for delegate mavnezz              ="
echo "#= Additional thanks to mrgr                                ="
echo "#= Please consider voting for delegate mrgr                 ="
echo "#============================================================"
echo " "

if [ ! -f ~/shift/app.js ]; then
  echo "Error: No shift installation detected. Exiting."
  exit 1
fi

if [ "\$USER" == "root" ]; then
  echo "Error: SHIFT should not be run be as root. Exiting."
  exit 1
fi

SHIFT_CONFIG=~/shift/config.json
DB_NAME="$(grep "database" $SHIFT_CONFIG | cut -f 4 -d '"')"
DB_USER="$(grep "user" $SHIFT_CONFIG | cut -f 4 -d '"')"
DB_PASS="$(grep "password" $SHIFT_CONFIG | cut -f 4 -d '"' | head -1)"


# Loading snapshot from server (http://snapshot.shiftnrg.info)
load_snapshot(){
  echo "Prepare for loading snapshot from server (http://snapshot.shiftnrg.info)"

rm main_*.tar -f
rm test_*.tar -f

if [ $DB_NAME == "shift_db" ]; then
   files=$(curl -s 'http://snapshot.shiftnrg.info/listfiles.php?type=main')
fi

if [ $DB_NAME == "shift_db_testnet" ]; then
   files=$(curl -s 'http://snapshot.shiftnrg.info/listfiles.php?type=test')
fi

tarfile=($(echo "$files" | tr ' ' '\n'))
echo " "
echo "Select a file to restore:" 
echo " "
nr=1
for i in "${tarfile[@]}"
do
   echo "- $nr $i"
   ((nr++))   
done
echo " "

  read -p "Select 1 or 2 for restore; 'q' for exit: " -n 1 -r
  if [[ ! $REPLY =~ ^[12]$ ]]
  then
     echo " "
     echo "bye"
     exit 1
  else
     echo ""
     echo "Loading blockchain from server"
     echo "..."
	nr=1
	for i in "${tarfile[@]}"
	do
 		if [ $REPLY -eq $nr ]; then
		   #wget -q "http://snapshot.shiftnrg.info/$i"	
		   wget -O $i "http://snapshot.shiftnrg.info/$i"	
	  	   echo "Loading done"
		   bash ~/shift/shift_manager.bash stop
		   # restore snapshop
		 	echo " + Restoring snapshot"

			#snapshot restoring..
			  export PGPASSWORD=$DB_PASS
			  pg_restore -d $DB_NAME "$i" -U $DB_USER -h localhost -c -n public

			  if [ $? != 0 ]; then
			    echo "X Failed to restore."
			    exit 1
			  else
			    echo "OK snapshot restored successfully."
			  fi
		   rm main_*.tar -f
		   rm test_*.tar -f			  
		   bash ~/shift/shift_manager.bash start
                   echo "Finished"
		fi
  		((nr++))   
	done

  fi

}

load_snapshot

echo " "
