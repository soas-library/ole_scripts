#!/bin/bash 
# @name: mysql_patron_deactivations.sh
# @version: 1.0
# @creation_date: 2017-09-14
# @license: GNU General Public License version 3 (GPLv3) <https://www.gnu.org/licenses/gpl-3.0.en.html>
# @author: Simon Barron <sb174@soas.ac.uk>
#
# @purpose:
# This script deactivates OLE patrons who are past their expiry date at the time of running.
#
database=ole

EXPIRATION_DATE=$(date +'%Y-%m-%d %H:%M:%S')
HOST=$(hostname -s)
EMAIL1='library.systems@soas.ac.uk'
EMAIL2='library.systems@soas.ac.uk'
USERNAME=xxxxxxxx
PASSWORD=xxxxxxxx
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

echo $(timestamp) Starting deactivation of expired OLE users
time mysql -u $USERNAME -p$PASSWORD $database -e "UPDATE ole.ole_ptrn_t SET ACTV_IND='N' WHERE ACTV_IND='Y' AND EXPIRATION_DATE < '$EXPIRATION_DATE';"

if [ $status -ne 0 ]; then
    echo $(timestamp) Error $status - deactiving OLE users on $timestamp failed!
    echo $(timestamp) Investigate and resolve NOW! | mailx -s "$HOST $(timestamp) Error $status - deactiving OLE users on $timestamp failed!" $EMAIL1
else
    echo $(timestamp) Successful deactivation of expired OLE users.
    echo $(timestamp) You have received this email because expired users have been successfully deactivated | mailx -s "$HOST $(timestamp) Successful deactivation of expired OLE users." $EMAIL2
fi

echo $(timestamp) Completed deactivation of expired OLE users
exit 0