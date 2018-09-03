#!/bin/bash 
# @name: patron_housekeeping.sh
# @version: 1.0
# @creation_date: 2016-07-04
# @license: GNU General Public License version 3 (GPLv3) <https://www.gnu.org/licenses/gpl-3.0.en.html>
# @author: Tim Green <tg3@soas.ac.uk>
#
# @purpose:
# This script removes old patron import files from /mnt/BLMS/Live_User_Import/Archives/
# Agreed time period is 46 days - script to be scheduled on 15th of each month
#
patron_xml_archive_dir=/mnt/BLMS/Live_User_Import/Archives/

#Be sure to express days as '+No of Days' omitting the + or including a - could be painful ;-)
DAYS='+77'
DAYS_ELAPSED=$(date --date=-2days +'%Y%m%d')
DATE=$(date +'%Y%m%d')
EMAIL='ft9@soas.ac.uk library.systems@soas.ac.uk csbs@soas.ac.uk'
HOST=$(hostname -s)
timestamp() {
  date +"%Y/%m/%d %H:%M:%S"
}

echo $(timestamp) Removing old patron xml import and update files
printf "$(timestamp) Files to be removed = "; find /mnt/BLMS/Live_User_Import/Archives/ -type f -mtime ${DAYS}  -name '*.xml' -ls | wc -l
find /mnt/BLMS/Live_User_Import/Archives/ -type f -mtime ${DAYS} -name '*.xml' -exec rm -f {} \;
echo $(timestamp) Old patron import and update files removed
exit 0
