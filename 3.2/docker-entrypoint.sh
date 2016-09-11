#!/bin/bash
set -e

if [ "${1:0:1}" = '-' ]; then
	set -- mongod "$@"
fi

# --- CONFIGURE MONGO AGENT ---

if [ ! "$MMS_API_KEY" ]; then
	{
		echo 'error: MMS_API_KEY was not specified'
		echo 'try something like: docker run -e MMS_API_KEY=... ...'
		echo '(see https://mms.mongodb.com/settings/monitoring-agent for your mmsApiKey)'
	} >&2
	exit 1
fi

# a function that does sed stuff to set the config
set_config() {
	key="$1"
	value="$2"
	sed_escaped_value="$(echo "$value" | sed 's/[\/&]/\\&/g')"
	sed -ri "s/^($key)[ ]*=.*$/\1 = $sed_escaped_value/" "$config_tmp"
}

configure_monitoring_agent(){
	
	# Set the API Key for the monitoring agent
	# For additional optional (but not implemented) settings, please see
	# https://docs.cloud.mongodb.com/reference/monitoring-agent/
	

	# "sed -i" can't operate on the file directly, and it tries to make a copy in the same directory, which our user can't do
	config_tmp="$(mktemp)"
	cat /etc/mongodb-mms/monitoring-agent.config > "$config_tmp"

	# trigger the function to set the config
	# add more of these for more custom settings, see https://github.com/Ulexus/docker-mms-agent/blob/master/entrypoint.sh#L33
	# (But they need defaults then, see https://github.com/Ulexus/docker-mms-agent/blob/master/entrypoint.sh#L4)
	set_config mmsApiKey "$MMS_API_KEY"

	cat "$config_tmp" > /etc/mongodb-mms/monitoring-agent.config
	rm "$config_tmp"
}

configure_backup_agent(){
	# Set the API Key for the backup agent
	# For additional optional (but not implemented) settings, please see
	# https://docs.cloud.mongodb.com/reference/monitoring-agent/

	# "sed -i" can't operate on the file directly, and it tries to make a copy in the same directory, which our user can't do
	config_tmp="$(mktemp)"
	cat /etc/mongodb-mms/backup-agent.config > "$config_tmp"

	# trigger the function to set the config
	# add more of these for more custom settings, see https://github.com/Ulexus/docker-mms-agent/blob/master/entrypoint.sh#L33
	# (But they need defaults then, see https://github.com/Ulexus/docker-mms-agent/blob/master/entrypoint.sh#L4)
	set_config mmsApiKey "$MMS_API_KEY"

	cat "$config_tmp" > /etc/mongodb-mms/backup-agent.config
	rm "$config_tmp"
}

# actually run the functions
configure_monitoring_agent
configure_backup_agent

# -- ALLOW THE CONTAINER TO BE STARTED WITH `--USER` --

if [ "$1" = 'mongod' -a "$(id -u)" = '0' ]; then
	chown -R mongodb /data/configdb /data/db
	exec gosu mongodb "$BASH_SOURCE" "$@"
fi

if [ "$1" = 'mongod' ]; then
	numa='numactl --interleave=all'
	if $numa true &> /dev/null; then
		set -- $numa "$@"
	fi
fi

# Run the agents here, instead of in the Dockerfile, because you can only define 1 `cmd` action in Dockerfile, 
# and we're interested in remaining close to the base mongodb dockerfile. This is dirty, but works.
/usr/bin/mongodb-mms-monitoring-agent -conf  /etc/mongodb-mms/monitoring-agent.config &
/usr/bin/mongodb-mms-backup-agent -c  /etc/mongodb-mms/backup-agent.config &

exec "$@"