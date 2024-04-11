#!/bin/bash

### BEGIN INIT INFO
# Provides:             Notify inbound folder event service
# Short-Description:    Script part of single RPA
# Author:          		Sandro Regis Cardoso | Software Eng.
### END INIT INFO

export LANG=pt_BR.UTF-8;

actions=CREATE,MOVED_TO,DELETE,ACCESS

parent_dir="$(dirname "$(pwd)")"
bash_log_dir=$parent_dir/log/bash
current_dir=${PWD##*/}
dir_datasource=$parent_dir/datasource
dir_inbound=$parent_dir/inbound
inotify=/usr/bin/inotifywait
log_file=$bash_log_dir/datasource_notify.log

know_extensions=("csv" "xml" "xls" "xlsx")


set -e

if ! [[ -e $bash_log_dir ]]
	then
		mkdir -p $bash_log_dir;
fi

if ! [[ -e $log_file ]]
	then
		touch $log_file
fi


gen_unique_key() {
	sleep 0.79s
	unique_key=$( date +%Y%m%d%H%M%S%s )
	echo $unique_key
}

get_client_ip() {
	client_ip=$( netstat -putan | awk '/:22 / && / ESTABLISHED / {split($4, result, ":"); print result[1]}' ) 
	echo $client_ip
}

get_auth_user() {
	client_auth_user=$( netstat -putan | awk '/:22 / && / ESTABLISHED / {split($8,result,":"); print result[1]}' )
	echo $client_auth_user
}

get_file_extension() {
	filename=$1;
	file_extension=${filename##*.};
	echo $file_extension
}

rename_inbound_file() {
	filename=$1
	ukey=$( gen_unique_key );
	new_file_name=$ukey"_"$file_name
	echo $new_file_name
}

move_file() {
	file_name=$1;
	file_extension=$2;
	newfile_name=$3;
	mv $dir_inbound"/"$file_name $dir_datasource"/"$file_extension"/"$newfile_name;
}

inbound_monitor() {
	while $inotify --recursive --event $actions "$dir_inbound"
		do
			sleep 0.7
			#($client_ip, $client_auth_user) will be used on json rest data header
			#client_ip=$( get_client_ip );
			#echo $client_ip;
			#client_auth_user=$( get_auth_user );
			#echo $client_auth_user;
			
			FILES=$(ls $dir_inbound)
			
			for file_name in $FILES
				do
				  	file_extension=$( get_file_extension $file_name )
					case "${know_extensions[@]}" in 
						*"$file_extension"* )
							#change font color for dev proposal only
							#tput setaf 2;
							echo "Inbound Action : Move $file_extension file to parser dir.";
							newfile_name=$( rename_inbound_file $file_name );
							
							#@todo: create bash function to move files
							#mv $dir_inbound"/"$file_name $dir_datasource"/"$file_extension"/"$newfile_name;
							$( move_file $file_name $file_extension $newfile_name );;
							#reset font color
							#tput sgr 0;;
						* )
							#change font color for dev proposal only
							#tput setaf 1;
							echo "Inbound Action : Send push and mail notification: Extension $file_extension not supported.";
							newfile_name=$( rename_inbound_file $file_name );
							mv $dir_inbound"/"$file_name $dir_inbound"/.not_supported/"$newfile_name;;
							
							#reset font color
							#tput sgr 0;;
			  		esac
				done
		done
}


datasource_monitor() {
	while $inotify --recursive --event $actions $dir_datasource 
		do
			echo "Data Source Action : Run parser to added..."
			cd $dir_datasource;
			folders=$( ls -d */ )
			for dir in $folders
			do
				files_on_dir=$( ls $dir )
				num_of_files=${#files_on_dir[*]}
				if [ $num_of_files -gt 0 ] 
				then 
					echo $files_on_dir
				fi
			done
			
			for element in "${know_extensions[@]}"
				do
				    echo "$element"
				done

			#set PYTHONPATH for test proposal
			export PYTHONPATH="$PYTHONPATH:$PWD/logger_framework/:$PWD/logger_framework/logger_multi_modules/:$PWD/rpa_datasources/addons_community/pid-3.0.4"
			python "../main.py";
		done
}


#for dev
inbound_monitor & datasource_monitor &

#for production
#inbound_monitor >> $log_file & datasource_monitor >> $log_file &




