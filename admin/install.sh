#!/bin/bash

# get the base directory
BASE_ABS=$(cd "$(dirname $0)/.." && pwd)
BUILD_CONFIG=$(cat $BASE_ABS/admin/config/settings.json | jq .build)
OS=$(uname)
CP=cp
if [ "$OS" = "Darwin" ]; then
	CP=gcp
fi

echo "BASE_ABS ${BASE_ABS}"

stage() {
	rm -rf $BASE_ABS/stage/*
	rm -rf $BASE_ABS/stage/.*

	echo "emptied stage/"
	ls -lA $BASE_ABS/stage/

	EXTRA_INCLUDES=$(echo $BUILD_CONFIG | jq .include | jq -r '.[]')
	USE_SHARED=$(echo $BUILD_CONFIG | jq .useShared)

	if [ "$USE_SHARED" == "true" ];
	then
		cp -r $BASE_ABS/src/configs/shared/. $BASE_ABS/stage
	fi
	
	echo "copied dotfiles"
	ls -lA $BASE_ABS/stage/

	for include in $EXTRA_INCLUDES;
	do
		if [ -d $BASE_ABS/src/configs/$include ];
		then
			$CP -r $BASE_ABS/src/configs/$include/. $BASE_ABS/stage
			$CP -rT $BASE_ABS/src/configs/$include/. $BASE_ABS/stage
		fi
	done
	$CP -r $BASE_ABS/src/configs/local/. $BASE_ABS/stage
	
	echo "staging utils (with preference for local utils)"

	if [ "$USE_SHARED" == "true" ];
	then
		$CP -r $BASE_ABS/src/utils/shared/. $BASE_ABS/stage/bin
	fi
	for include in $EXTRA_INCLUDES;
	do
		if [ -d $BASE_ABS/src/utils/$include ];
		then
			$CP -r $BASE_ABS/src/utils/$include/. $BASE_ABS/stage/bin
		fi
	done
	$CP -r $BASE_ABS/src/utils/local/. $BASE_ABS/stage/bin

	echo "staging cron jobs (with preference for local)"
	mkdir -p $BASE_ABS/stage/cronjobs
	if [ "$USE_SHARED" == "true" ];
	then
		$CP -r $BASE_ABS/src/cronjobs/shared/. $BASE_ABS/stage/cronjobs
	fi
	for include in $EXTRA_INCLUDES;
	do
		if [ -d $BASE_ABS/src/cronjobs/$include ];
		then
			$CP -r $BASE_ABS/src/cronjobs/$include/. $BASE_ABS/stage/cronjobs
		fi
	done
	$CP -r $BASE_ABS/src/cronjobs/local/. $BASE_ABS/stage/cronjobs
	
	echo "staging systemd services (with preference for local)"

	if [ "$USE_SHARED" == "true" ];
	then
		$CP -r $BASE_ABS/src/systemd/shared/. $BASE_ABS/stage/systemd
	fi
	for include in $EXTRA_INCLUDES;
	do
		if [ -d $BASE_ABS/src/systemd/$include ];
		then
			$CP -r $BASE_ABS/src/systemd/$include/. $BASE_ABS/stage/systemd
		fi
	done
	$CP -r $BASE_ABS/src/systemd/local/. $BASE_ABS/stage/systemd

	echo "staging docker-compose.yml files for starting docker services"
	if [ "$USE_SHARED" == "true" ];
	then
		$CP -r $BASE_ABS/src/docker/shared $BASE_ABS/stage/docker/
	fi
	for include in $EXTRA_INCLUDES;
	do
		if [ -d $BASE_ABS/src/docker/$include ];
		then
			$CP -r $BASE_ABS/src/docker/$include $BASE_ABS/stage/docker/
		fi
	done
	$CP -r $BASE_ABS/src/docker/local $BASE_ABS/stage/docker/

	# preprocess staged output
	# change <USER> tag to $USER wherever it appears in files
	find stage -type f -exec sed -i -e "s@<USER>@$USER@g" {} \;
}

update_home() {
	echo "WARNING: If the following files exist, they will be overwritten"
	find "$BASE_ABS/stage" -type f | sed 's/.*stage/\~/g' \
		| grep -v ".keep" \
		| grep -v "cronjobs/" \
		| grep -v "systemd/" \
		| grep -v "README.md"

	read -p "Proceed? (y/n) " RESPONSE

	if [ $RESPONSE = "y" ]; 
	then
		# NOTE: make sure you copy staged cronjobs and systemd services before running
		#		this function!
		rm -rf $BASE_ABS/stage/README.md
		rm -rf $BASE_ABS/stage/.keep

		# copy config build and utils to ~
		sudo $CP -rT $BASE_ABS/stage/docker/ ~/.config/docker
		rm -rf $BASE_ABS/stage/docker
		sudo $CP -r $BASE_ABS/stage/ ~/ && sudo chown -R $(whoami) $BASE_ABS/stage
		sudo $CP -r $BASE_ABS/stage/.[^.]* ~/
		sudo $CP $BASE_ABS/stage/.bashrc ~/
		sudo $CP -rT $BASE_ABS/stage/.config ~/.config
		sudo $CP -rT $BASE_ABS/stage/bin/ /usr/local/bin/

        rm ~/.keep
		rm ~/README.md
        sudo rm -rf ~/stage
        sudo rm -rf ~/cronjobs
        sudo rm -rf ~/systemd
	fi

	mkdir -p ~/.cache/.workflow
}

update_cronjobs() {
	sudo $CP -r $BASE_ABS/stage/cronjobs/* /etc/cron.d/
}

update_systemd_services() {
	if [ -d /etc/systemd ];
	then

		sudo $CP -r $BASE_ABS/stage/systemd/* /etc/systemd/system/

		SERVICES=$(ls -lA $BASE_ABS/stage/systemd | awk '{print $9}' | grep -v ".keep")

		for service in $SERVICES;
		do
			sudo systemctl enable $service
			sudo systemctl start $service
		done

		sudo systemctl daemon-reload
	fi
}

# start_docker_services() {
# 	# TODO: start docker services and call this function




#}

refresh() {
	if [ -d $BASE_ABS/stage/.config/i3/config ];
	then
	    i3-msg restart
	fi
}

$1 "${@:2}"
