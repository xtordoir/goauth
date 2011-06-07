#!/bin/bash

# end point for google oauth 
TOKEN_ENDPOINT="https://accounts.google.com/o/oauth2/token"

# set the option for extended regexp fir sed
ESED="-r"
unamestr=`uname`
if [[ "$unamestr" == 'Darwin' ]]; then
   ESED="-E"
fi

# string used for usage
export HELP_STRING=$(cat <<EOT
Tools to get OAuth2.0 codes and tokens

EOT
)
export USAGE_STRING=$(cat <<EOT
[options] action
where action is either:
code     : to obtain a code for requesting authorization tokens on a domain
auth     : to obtain the authorization tokens from a code
refresh  : to refresh an authorization token, will return the token json

where options are:
--conf <configfile>          : config file containing the callback, client_id and client_secret in the format:
GOAUTH_CALLBACK_URL="__XXX__"
GOAUTH_CLIENT_ID="__YYY__"
GOAUTH_CLIENT_SECRET="__XXX__"

--token <tokenfile>          : file containing the token and refresh token in the format:
-h | --help                  : diplay this help message
EOT
)
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
			*)
			ACTION=$1;
			shift;;
		esac
	done
}

# read options
getopt $@

# test if usage string is required
if [ $HELP ]; then
	echo
	echo $HELP_STRING
	echo
	echo "Usage: `basename $0` $USAGE_STRING"
	exit 0
fi

# need to set all parameters GOAUTH_CALLBACK_URL, GOAUTH_CLIENT_ID, GOAUTH_CLIENT_SECRET
if [ -e $CONFIGFILE ]
	then
	. $CONFIGFILE
fi

function getTokenFromFile {
	if [ -f $TOKENFILE ]
		then
		TOKEN=`cat $TOKENFILE | sed $ESED "s/.*\"access_token\":\"([^\"]+)\".*/\1/"`
		REFRESH_TOKEN=`cat $TOKENFILE | sed $ESED "s/.*\"refresh_token\":\"([^\"]+)\".*/\1/"`
	fi
}
function refreshToken {
	TOKEN_RESPONSE=`curl -X "POST" \
		-d "client_id=$GOAUTH_CLIENT_ID" \
		-d "client_secret=$GOAUTH_CLIENT_SECRET" \
		-d "refresh_token=$REFRESH_TOKEN" \
		-d "grant_type=refresh_token" \
	$TOKEN_ENDPOINT 2>/dev/null`
	echo $TOKEN_RESPONSE
}

if [ $ACTION = 'code' ] 
	then
	echo -n "Scope:"
	read SCOPE
	echo "Get the code at the following url:"
	echo "https://accounts.google.com/o/oauth2/auth?client_id=$GOAUTH_CLIENT_ID&redirect_uri=$GOAUTH_CALLBACK_URL&scope=$SCOPE&response_type=code"
#	open "https://accounts.google.com/o/oauth2/auth?client_id=$GOAUTH_CLIENT_ID&redirect_uri=$GOAUTH_CALLBACK_URL&scope=$SCOPE&response_type=code"
elif [ $ACTION = 'auth' ] 
	then
	echo -n "Code:"
	read CODE
	curl -X "POST" -d "client_id=$GOAUTH_CLIENT_ID" -d "client_secret=$GOAUTH_CLIENT_SECRET" -d "code=$CODE" -d "redirect_uri=$GOAUTH_CALLBACK_URL" -d "grant_type=authorization_code"  https://accounts.google.com/o/oauth2/token
	echo
elif [ $ACTION = 'refresh' ]
	then
	getTokenFromFile
	refreshToken
fi


