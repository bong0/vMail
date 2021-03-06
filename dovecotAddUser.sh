#!/bin/bash
trap "echo Booh!; exit -1" SIGINT SIGTERM

MYPATH=$(dirname $0)
# load config                                                                                                                    
if [ -f $MYPATH/conf.conf ]
then
    source $MYPATH/conf.conf
else
    echo "No Config present"
    exit -1;
fi
if [ -f $MYPATH/conf.local ]
then
    source $MYPATH/conf.local
fi


if [ ! $# = 1 ]
 then
  echo "Usage: $0 username@domain"
  exit 1
 else
  user=`echo "$1" | cut -f1 -d "@" | tr '[:upper:]' '[:lower:]'`
  domain=`echo "$1" | cut -s -f2 -d "@" | tr '[:upper:]' '[:lower:]'`
  if [ -x $domain ]
   then
    echo "No domain given\nUsage: $0 username@domain"
    exit 2
  fi
  echo " \nCreate a password for the new email user"
  passwd=`dovecotpw -s ssha256`
  echo "Adding password for $user@$domain to /var/mail/auth.d/$domain/passwd"

  if [ ! -x /var/mail/auth.d/$domain ]
   then
    mkdir /var/mail/auth.d/$domain
    chown doveauth:doveauth /var/mail/auth.d/$domain
    chmod 700 /var/mail/auth.d/$domain
  fi
  if [ ! -x /var/mail/auth.d/$domain/passwd ]
   then
    touch /var/mail/auth.d/$domain/passwd
    chown doveauth:doveauth /var/mail/auth.d/$domain/passwd
    chmod 640 /var/mail/auth.d/$domain/passwd
  fi
  echo  "$user@$domain:$passwd" >> /var/mail/auth.d/$domain/passwd

  # To add user to Postfix virtual map file and relode Postfix
  echo "Adding user to /etc/postfix/vmaps"
  echo $1  $domain/$user/Maildir >> /etc/postfix/vmaps
  postmap /etc/postfix/vmaps
  postfix reload
 # Create virtual domain
 eval "$(dirname $0)/addvDomain.sh $domain"

 # Create the needed Maildir directories
  echo "Creating domain direcotry /var/mail/$domain"
  # maildirmake.dovecot does only chown on user directory, we'll create domain directory instead
  if [ ! -x /var/mail/$domain ]
   then
    mkdir /var/mail/$domain
    chown $MAIL_ACCESS_UID:$MAIL_ACCESS_GID /var/mail/$domain
    chmod 700 /var/mail/$domain
  fi
  if [ ! -x /var/mail/$domain/$user ]
  then
      mkdir /var/mail/$domain/$user
      chown $MAIL_ACCESS_UID:$MAIL_ACCESS_GID /var/mail/$domain/$user
      chmod 700 /var/mail/$domain/$user
  fi
fi
