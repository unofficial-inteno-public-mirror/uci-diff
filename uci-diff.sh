#!/bin/sh

#Author: Reidar Cederqvist
####### includes ######################
#. /usr/share/libubox/jshn.sh
####### end of includes ###############
####### helper functions ##############
print_usage() {
	echo -e "usage: $0 <action>\n"
	echo -e "actions:\n"
	echo -e "\t-d|--diff diff-file orig-file out-file //create a JSON diff between file1 and file2 and print the result in out-file"
	echo -e "\t-a|--apply file                        //apply a diff file"
	echo -e "\t-e|--extract <config/all> out-file     //create a JSON file for the specified (or all) config(s)"
	echo -e "\t-h|--help                              //print usage\n"
}

apply_diff(){
	echo $1
}

extract_config(){
	if [ "$1" == "all" ]; then
		echo -e '{' > $2
		for file in $(ls /etc/config); do
			echo -en "\rparsing $file                                 "
			res="$(ubus call uci get "{\"config\":\"$file\"}" 2>/dev/null)"
			if [ "$res" != "" ]; then
				echo -e "$(echo -e "$res" | sed "s/\"values\":/\"$file\":/g" | sed 's/^\t}$/\t},/g' | sed '/^[{}]$/d')" >>$2
			else
				echo "\n\nERROR: Couldn't parse config: $file\n\n"
			fi
		done
		sed -i '$ d' $2
		echo -e '\t}\n}' >>$2
		echo -e "\nFinished\n"
	else
		echo -e "$(ubus call uci get "{\"config\":\"$1\"}" | sed "s/\"values\":/\"$1\":/g")" >$2
	fi
}

can_write(){
	[ -e "$1" ] || touch "$1"
	[ -f "$1" -a -w "$1" ] && return 0 || return 1
}
can_read(){
	[ -f "$1" -a -r "$1" ] && return 0 || return 1
}

####### end of helper functions ##############

case $1 in
-d|--diff)
	[ $# -ne 4 ] && print_usage && exit 1
	[ "$2" == "$3" ] && print_usage && exit 1
	can_read $2 || (echo -e "Can't read file: $2" && exit 1)
	can_read $3 || (echo -e "Can't read file: $3" && exit 1)
	can_write $4 || (echo -e "Can't write to file: $4" && exit 1)
	create_diff "$2" "$3" "$4"
	;;
-a|--apply)
	[ $# -ne 2 ] && print_usage && exit 1
	can_read $2 || (echo -e "Can't read file: $2" && exit 1)
	apply_diff $2
	;;
-e|--extract)
	[ $# -ne 3 ] && print_usage && exit 1
	[ "$2" == "all" -o "$(ls /etc/config 2>/dev/null| grep "$2")" ] || (echo -e "$2 is not a config" && exit 1)
	can_write "$3" || (echo -e "Can't write to file: $3" && exit 1)
	extract_config $2 $3
	;;
-h|--help)
	print_usage
	exit 0
	;;
*)
	print_usage
	exit 1
	;;
esac
		
