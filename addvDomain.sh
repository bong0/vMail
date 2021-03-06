#!/bin/bash

trap "echo Booh!; exit -1" SIGINT SIGTERM

MYPATH=$(dirname $0)
# load config
if [ -f $MYPATH/conf.conf ]
then
    source $MYPATH/conf.conf
else
    echo "No config present"
    exit -1
fi
if [ -f $MYPATH/conf.local ]
then
    source $MYPATH/conf.local
fi


if [ ! $# = 1 ]
 then
  echo "Usage: $0 domain"
  exit 1
 else
  domain=$1
  if [ -x $domain ]
   then
    echo "No domain given\nUsage: $0 domain"
    exit 2
  fi

  if [ ! -f /etc/postfix/vdomains ]
  then 
      touch /etc/postfix/vdomains
  fi
  grep -q $domain /etc/postfix/vdomains
  if [ $? -eq 1 ]
   then
    echo "Insert Domain $domain in /etc/postfix/vdomains"
    echo "$domain" >> /etc/postfix/vdomains
    postfix reload
  else
    echo "Domain already in list"
  fi
fi
