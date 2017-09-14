#!/bin/bash

### Install Monitoring Plugin Usage:help
#
# Adds a plugin from the plugins folder of this project to /usr/lib/nagios/plugins
#
###/doc

#%include autohelp.sh bashout.sh colours.sh searchpaths.sh

main() {
	[[ "$UID" = 0 ]] || faile "You need to be root to run this script"

	cd "$(dirname "$0")"

	local pluginname="$1"; shift
	local plugin="$(filefrom plugins "$pluginname" "$pluginname.sh" "$pluginname.py")"

	[[ -n "$plugin" ]] || faile "No such plugin '$1'"

	cp "$plugin" /usr/lib/nagios/plugins
}

main "$@"
