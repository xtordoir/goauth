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
			"get")
			ACTION=$1;shift;
			ID=$1;
			shift;;
			"train")
			ACTION=$1;shift;
			OBJECT=$1; shift;
			ID=$1;
			# SHOULD ADD SUPPORT FOR PMML AND UTILITY....
			shift;;
			"predict")
			ACTION=$1;shift;
			ID=$1;shift;
			CSV=$1;
			shift;;
			"delete")
			ACTION=$1;shift;
			ID=$1;
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
	TOKEN=`cat $TOKENFILE | tr -d " " | sed $ESED "s/.*\"access_token\":\"([^\"]+)\".*/\1/"`
fi

function get {
	ID=$1
	URL="https://www.googleapis.com/prediction/v1.4/trainedmodels/$ID"
	echo $URL
	curl -w %{http_code} -X GET   \
	-H "Authorization: OAuth $TOKEN"  \
	-H "x-goog-api-version: 2"        \
	-H "accept: application/json"     \
	$URL 2>/dev/null
}

function train {
	OBJECT=$1
	ID=$2
	MESSAGE="{\"id\":\"$ID\", \"storageDataLocation\":\"$OBJECT\"}"
	URL="https://www.googleapis.com/prediction/v1.4/trainedmodels"
	curl -w %{http_code} -X POST     \
	-d "$MESSAGE"                      \
	-H 	"Authorization: OAuth $TOKEN"  \
	-H "x-goog-api-version: 2"        \
	-H "accept: application/json"     \
	-H "content-type: application/json" \
	$URL 2>/dev/null
}

function delete {
	ID=$1
	URL="https://www.googleapis.com/prediction/v1.4/trainedmodels/$ID"
	curl -w %{http_code} -X DELETE   \
	-H "Authorization: OAuth $TOKEN"  \
	-H "x-goog-api-version: 2"        \
	-H "accept: application/json"     \
	$URL 2>/dev/null
}

function predict {
	ID=$1
	CSV=$2
	MESSAGE="{\"input\":{\"csvInstance\":[$CSV]}}"
	URL="https://www.googleapis.com/prediction/v1.4/trainedmodels/$ID/predict"
	curl -w %{http_code} -X POST     \
	-d "$MESSAGE"                      \
	-H 	"Authorization: OAuth $TOKEN"  \
	-H "x-goog-api-version: 2"        \
	-H "accept: application/json"     \
	-H "content-type: application/json" \
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
	get $ID
elif [ $ACTION = "train" ]
	then
	train $OBJECT $ID
elif [ $ACTION = "predict" ]
	then
	predict $ID $CSV
elif [ $ACTION = "delete" ]
	then
	delete $ID
fi