#!/bin/bash

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
			"--token")
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
	TOKEN=`cat $TOKENFILE | sed -E "s/.*\"access_token\":\"([^\"]+)\".*/\1/"`
fi

function get {
	BUCKET=$1
	OBJECT=$2
	URL="https://$BUCKET.commondatastorage.googleapis.com/$OBJECT"
	echo $URL
	curl -X GET   \
	-H "Authorization: OAuth $TOKEN"  \
	-H "x-goog-api-version: 2"        \
	-H "accept: application/json"     \
	$URL
}

function put {
	FILE=$1
	BUCKET=$2
	OBJECT=$3
	
	LENGTH=$(cat $FILE | wc -c)
	URL="https://$BUCKET.commondatastorage.googleapis.com/$OBJECT"
	curl -X PUT                       \
	-H "Authorization: OAuth $TOKEN"  \
	-H "x-goog-api-version: 2"        \
	--data-binary "@$FILE"            \
	$URL
}

if [ $ACTION = "get" ]
	then
	echo "get $BUCKET $OBJECT"
	get $BUCKET $OBJECT
elif [ $ACTION = "put" ]
	then
	put $SOURCE $BUCKET $OBJECT
fi