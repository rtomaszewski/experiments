#!/bin/bash

IP=$1
req=/tmp/super-search-request.txt
html=/tmp/super-search-$$-tmp.html

echo > curl.log

export cookie="IS_UASrackuid=xxx; RackSID=xxx; COOKIE_last_login=xxx; rackspace_admin_session=xxx;"

echo "account_name=&first_name=&last_name=&phone_number=&email_address=&server_name=&ip_address=$IP&privatenet_ip_address=&search=Search" > $req
curl -s -o $html  -d @$req -b "$cookie"  https://url >> curl.log

echo -en "$IP "
html-parser.py $html
