#!/bin/bash

### Install Monitoring Plugin Usage:help
#
#	add_plugin.sh PLUGIN [OPTIONS ...]
#
#
# Adds a plugin from the plugins folder of this project to /usr/lib/nagios/plugins ,
# and adds an entry to /etc/nagios/nrpe.cfg
#
# PLUGIN - the name of the plugin file
#
# OPTIONS - options to pass to the plugin at runtime (nrpe configuration)
#
###/doc

#%include autohelp.sh bashout.sh colours.sh searchpaths.sh

NRPE_CONFIG=/etc/nagios/nrpe.cfg

main() {
	[[ "$UID" = 0 ]] || faile "You need to be root to run this script"

	[[ -f "$NRPE_CONFIG" ]] || faile "Please install nagios-nrpe-server"

	cd "$(dirname "$0")"

	local pluginname="$1"; shift
	local plugin="$(filefrom plugins "$pluginname")"

	[[ -n "$plugin" ]] || faile "No such plugin '$1'"

	cp "$plugin" "$NRPE_CONFIG/"

	info "Task in $NRPE_CONFIG:"
	grep -P "^[$pluginname]="  "NRPE_CONFIG" || {
		echo "[$pluginname]=$plugin $*"| tee -a "$NRPE_CONFIG"

	}
}

main "$@"
