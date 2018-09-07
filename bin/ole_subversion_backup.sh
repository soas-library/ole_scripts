#!/bin/bash -v
# @name: ole_subversion_backup.sh
# @version: 1.0
# @creation_date: 2018-09-07
# @license: GNU General Public License version 3 (GPLv3) <https://www.gnu.org/licenses/gpl-3.0.en.html>
# @author Simon Bowie <sb174@soas.ac.uk>
#
# @purpose:
# This script backs up OLE integration scripts to Subversion

DATE=$(date +'%Y%m%d')

cd /home/ole_B2017/svn

cp -ra /home/ole_B2017/bin/* bin/
cp -ra /home/ole_B2017/sql/* sql/

crontab -l > cron_jobs/crontab.txt

svn add --force .

svn commit -m "Updating Subversion copy of OLE integration scripts"
