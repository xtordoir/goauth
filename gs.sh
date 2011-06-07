#!/bin/bash

# set the option for extended regexp fir sed
ESED="-r"
unamestr=`uname`
if [[ "$unamestr" == 'Darwin' ]]; then
   ESED="-E"
fi

#######################
#
# read options from the command line, store in variables
#
#######################
getopt() {
	while [ $# -gt 0 ]; do
		case $1 in
			"--conf")
			shift;
			CONFIGFILE=$1;
			shift;;
			"--tokenfile")
			shift;
			TOKENFILE=$1;
			shift;;
			-h | --h | -help | --help)
			shift;
			HELP=1;;
			"put")
			ACTION=$1;
			shift;
			SOURCE=$1; shift;
			BUCKET=$1; shift;
			OBJECT=$1;
			shift;;
			"get")
			ACTION=$1;
			shift;
			BUCKET=$1; 
			shift;
			OBJECT=$1;
			shift;
			TARGET=$1;
			shift;;
			*)
			shift;;
		esac
	done
}
# read options
getopt $@
if [ -f $TOKENFILE ]
	then
	TOKEN=`cat $TOKENFILE | sed $ESED "s/.*\"access_token\":\"([^\"]+)\".*/\1/"`
fi

function get {
	BUCKET=$1
	OBJECT=$2
	TARGET=$3
	URL="https://$BUCKET.commondatastorage.googleapis.com/$OBJECT"
	curl -w %{http_code} -X GET   \
	-H "Authorization: OAuth $TOKEN"  \
	-H "x-goog-api-version: 2"        \
	-H "accept: application/json"     \
	-o $TARGET                        \
	$URL 2>/dev/null
}

function put {
	FILE=$1
	BUCKET=$2
	OBJECT=$3
	
	LENGTH=$(cat $FILE | wc -c)
	URL="https://$BUCKET.commondatastorage.googleapis.com/$OBJECT"
	curl  -w %{http_code}  -X PUT                       \
	-H "Authorization: OAuth $TOKEN"  \
	-H "x-goog-api-version: 2"        \
	--data-binary "@$FILE"            \
	$URL 2>/dev/null
}

if [ $ACTION = "get" ]
	then
	get $BUCKET $OBJECT $TARGET
elif [ $ACTION = "put" ]
	then
	put $SOURCE $BUCKET $OBJECT
fi