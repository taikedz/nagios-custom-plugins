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

main() {
	[[ "$UID" = 0 ]] || faile "You need to be root to run this script"

	cd "$(dirname "$0")"

	local pluginname="$1"; shift
	local plugin="$(filefrom plugins "$pluginname")"

	[[ -n "$plugin" ]] || faile "No such plugin '$1'"

	cp "$plugin" /usr/lib/nagios/plugins

	[[ -f "/etc/nagios/nrpe.cfg" ]] && echo "[$pluginname]=$plugin $*" | tee -a /etc/nagios/nrpe.cfg || :
}

main "$@"
