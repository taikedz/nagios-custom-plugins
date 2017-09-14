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

#!/bin/bash

### printhelp Usage:bbuild
# Write your help as documentation comments in your script
#
# If you need to output the help from a running script, call the
# `printhelp` function and it will print the help documentation
# in the current script to stdout
#
# A help comment looks like this:
#
#	### <title> Usage:help
#	#
#	# <some content>
#	#
#	# end with "###/doc" on its own line (whitespaces before
#	# and after are OK)
#	#
#	###/doc
#
###/doc

CHAR='#'

function printhelp {
	local USAGESTRING=help
	local TARGETFILE=$0
	if [[ -n "$*" ]]; then USAGESTRING="$1" ; shift; fi
	if [[ -n "$*" ]]; then TARGETFILE="$1" ; shift; fi

        echo -e "\n$(basename "$TARGETFILE")\n===\n"
        local SECSTART='^\s*'"$CHAR$CHAR$CHAR"'\s+(.+?)\s+Usage:'"$USAGESTRING"'\s*$'
        local SECEND='^\s*'"$CHAR$CHAR$CHAR"'\s*/doc\s*$'
        local insec="$(mktemp --tmpdir)"; rm "$insec"
        cat "$TARGETFILE" | while read secline; do
                if [[ "$secline" =~ $SECSTART ]]; then
                        touch "$insec"
                        echo -e "\n${BASH_REMATCH[1]}\n---\n"
                elif [[ -f $insec ]]; then
                        if [[ "$secline" =~ $SECEND ]]; then
                                rm "$insec"
                        else
				echo "$secline" | sed -r "s/^\s*$CHAR//g"
                        fi
                fi
        done
        if [[ -f "$insec" ]]; then
                echo "WARNING: Non-terminated help block." 1>&2
		rm "$insec"
        fi
	echo ""
}

### automatic help Usage:main
#
# automatically call help if "--help" is detected in arguments
#
###/doc
if [[ "$@" =~ --help ]]; then
	cols="$(tput cols)"
	printhelp | fold -w "$cols" -s
	exit 0
fi
#!/bin/bash


MODE_DEBUG=no
MODE_DEBUG_VERBOSE=no

### debuge MESSAGE Usage:bbuild
# print a blue debug message to stderr
# only prints if MODE_DEBUG is set to "yes"
###/doc
function debuge {
	if [[ "$MODE_DEBUG" = yes ]]; then
		echo -e "${CBBLU}DEBUG:$CBLU$*$CDEF" 1>&2
	fi
}

### infoe MESSAGE Usage:bbuild
# print a green informational message to stderr
###/doc
function infoe {
	echo -e "$CGRN$*$CDEF" 1>&2
}

### warne MESSAGE Usage:bbuild
# print a yellow warning message to stderr
###/doc
function warne {
	echo -e "${CBYEL}WARN:$CYEL $*$CDEF" 1>&2
}

### faile [CODE] MESSAGE Usage:bbuild
# print a red failure message to stderr and exit with CODE
# CODE must be a number
# if no code is specified, error code 127 is used
###/doc
function faile {
	local ERCODE=127
	local numpat='^[0-9]+$'

	if [[ "$1" =~ $numpat ]]; then
		ERCODE="$1"; shift
	fi

	echo "${CBRED}ERROR FAIL:$CRED$*$CDEF" 1>&2
	exit $ERCODE
}

function dumpe {
	echo -n "[1;35m$*" 1>&2
	echo -n "[0;35m" 1>&2
	cat - 1>&2
	echo -n "[0m" 1>&2
}

function breake {
	if [[ "$MODE_DEBUG" != yes ]]; then
		return
	fi

	read -p "${CRED}BREAKPOINT: $* >$CDEF " >&2
	if [[ "$REPLY" =~ $(echo 'quit|exit|stop') ]]; then
		faile "ABORT"
	fi
}

### Auto debug Usage:main
# When included, bashout processes a special "--debug" flag
#
# It does not remove the debug flag from arguments.
###/doc

if [[ "$*" =~ --debug ]]; then
	MODE_DEBUG=yes

	if [[ "$MODE_DEBUG_VERBOSE" = yes ]]; then
		set -x
	fi
fi
#!/bin/bash

### Colours for bash Usage:bbuild
# A series of colour flags for use in outputs.
#
# Example:
# 	
# 	echo "${CRED}Some red text ${CBBLU} some blue text $CDEF some text in the terminal's default colour"
#
# Colours available:
#
# CDEF -- switches to the terminal default
#
# CRED, CBRED -- red and bright/bold red
# CGRN, CBGRN -- green and bright/bold green
# CYEL, CBYEL -- yellow and bright/bold yellow
# CBLU, CBBLU -- blue and bright/bold blue
# CPUR, CBPUR -- purple and bright/bold purple
#
###/doc

export CRED="[31m"
export CGRN="[32m"
export CYEL="[33m"
export CBLU="[34m"
export CPUR="[35m"
export CBRED="[1;31m"
export CBGRN="[1;32m"
export CBYEL="[1;33m"
export CBBLU="[1;34m"
export CBPUR="[1;35m"
export CDEF="[0m"
#!/bin/bash

### Find a file given a path list Usage:bbuild
#
# Usage:
#
# 	filefrom PATHDEF FILES ...
#
# Locate a file along a search path. The following will look for each of the files
#  in order of preference of a local lib directory, a profile-wide one, then a system-
#  wide one.
#
# 	filefrom "./lib:$HOME/.local/lib:/usr/local/lib" file1 file2 file3
#
# Echoes the path of the first file found.
#
# Returns 1 on failure to find any file.
#
###/doc

function filefrom {
	local PATHS="$1"; shift
	local FILE="$1"; shift

	debuge "file [$FILE] from [$PATHS]"

	for path in $(echo "$PATHS"|tr ':' ' '); do
		debuge "Try path: $path"
		local fpath="$path/$FILE"
		if [[ -f "$fpath" ]]; then
			echo "$fpath"
			return
		else
			debuge "No $fpath"
		fi
	done
	return 1
}

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
