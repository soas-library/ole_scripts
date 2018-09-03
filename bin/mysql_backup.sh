#!/bin/bash 
# @name: mysql_backup.sh
# @version: 2.0
# @creation_date: Unknown
# @license: GNU General Public License version 3 (GPLv3) <https://www.gnu.org/licenses/gpl-3.0.en.html>
# @author: Simon Barron <sb174@soas.ac.uk>
#
# @purpose:
# This script runs a backup of the MySQL database for OLE
# Backups are retained for two days in /usr/local/2ndhome/mysql_backup/

# @edited_date: 2015-11-23
# 20151123 tg3 Added error detetion where possible, adjusted sequence to remove old backup before creating new (Clear space)
#              NB Can't test return code from OLE stop / start :-(
#              NB Will also need to schedule VuFind to go offline to prevent it accessing OLE DB whilst backup running
#
# @edited_date: 20160816
# 20160816 tg3 Added --add-drop-database to mysql dump to ensure all tables that exist in database that restore is writing into are
#              removed - this was  causing an issue on the reporting server where old tables from an earlier version of OLE remained in
#              in the restored copy of the db - thus leading to false negative error reports from the table record count cross check that 
#              is run as part of the recovery procedure on margaret to ensure we are generating consistant backups.  
#              See /home/oledbsync/james/refreshOleDb.bash for details and /home/oledbsync/james/refreshOleDb.log for the results.
#       
database=ole
local_backup_dir=/usr/local/2ndhome/mysql_backup

DAYS_ELAPSED=$(date --date=-2days +'%Y%m%d')
DATE=$(date +'%Y%m%d')
EMAIL1='ft9@soas.ac.uk bj1@soas.ac.uk library.systems@soas.ac.uk ap87@soas.ac.uk sb174@soas.ac.uk csbs@soas.ac.uk'
EMAIL='library.systems@soas.ac.uk ap87@soas.ac.uk sb174@soas.ac.uk csbs@soas.ac.uk'
HOST=$(hostname -s)
timestamp() {
  date +"%Y/%m/%d %H:%M:%S"
}

echo $(timestamp) Starting backup of OLE DB
cd $local_backup_dir 

echo $(timestamp) Taking OLE offline for duration of backup
/bin/bash /etc/init.d/ole stop

echo $(timestamp) Removing old backup [$local_backup_dir/ole_mysql_$DAYS_ELAPSED.sql]
rm -rf $local_backup_dir/ole_mysql_$DAYS_ELAPSED.sql

echo $(timestamp) Generating list of record counts for ole_%_s tables into [$local_backup_dir/ole_table_record_count_$DATE.txt]
time mysql -u xxxxxxxx -pxxxxxxxx ole -e 'call SOAS_COUNT_ALL_RECORDS_OLE_TABLES();' > $local_backup_dir/ole_table_record_count_$DATE.txt

echo $(timestamp) Taking dump of OLE DB into [$local_backup_dir/ole_mysql_$DATE.sql]
mysqldump -u xxxxxxxx -pxxxxxxxx $database --add-drop-database > $local_backup_dir/ole_mysql_$DATE.sql
status=$?
if [ $status -ne 0 ]; then
    echo $(timestamp) Error $status - dump of OLE DB into [$local_backup_dir/ole_mysql_$DATE.sql] failed!
    echo $(timestamp) Investigate and resolve NOW! | mailx -s "$HOST $(timestamp) Error $status - dump of OLE DB into [$local_backup_dir/ole_mysql_$DATE.sql] failed!" $EMAIL1
else
    echo $(timestamp) Success dump of OLE DB into [$local_backup_dir/ole_mysql_$DATE.sql] succeeded 
    echo $(timestamp) You may relax | mailx -s "$HOST $(timestamp) Success $status - dump of OLE DB into [$local_backup_dir/ole_mysql_$DATE.sql] succeeded" $EMAIL
fi

echo $(timestamp) Bringing OLE back online
/bin/bash /etc/init.d/ole start

echo $(timestamp) Copying dump and ole table row count to /mnt/BLMS/Live_OLE_backup/
rm -rf /mnt/BLMS/Live_OLE_backup/ole_mysql_*.sql /mnt/BLMS/Live_OLE_backup/ole_table_record_count_*.txt
cp $local_backup_dir/ole_mysql_$DATE.sql /mnt/BLMS/Live_OLE_backup/
cp $local_backup_dir/ole_table_record_count_$DATE.txt /mnt/BLMS/Live_OLE_backup/

echo $(timestamp) Copying dump and ole table row counts to william.lis.soas.ac.uk
# 2015-11-04 tg3 added copy of dump to margaret which is holds a copy of the OLE database used for reporting
scp -i /root/.ssh/id_ole15 $local_backup_dir/ole_mysql_$DATE.sql ole15@william.lis.soas.ac.uk:2ndhome/$HOST/ole_mysql.sql
scp -i /root/.ssh/id_ole15 $local_backup_dir/ole_table_record_count_$DATE.txt ole15@william.lis.soas.ac.uk:2ndhome/$HOST/ole_table_record_count_$DATE.txt

ls -lh $local_backup_dir/ole_mysql_$DATE.sql

minimumsize=9680000000
echo $(timestamp) Checking OLE DB Dump is at least $minimumsize bytes 
actualsize=$(wc -c < "$local_backup_dir/ole_mysql_$DATE.sql")
if [ $actualsize -ge $minimumsize ]; then
    echo $(timestamp) OLE DB Dump looks OK size = $actualsize bytes 
else
    echo $(timestamp) WARNING - OLE DB Dump looks Too Small - size = $actualsize bytes
    ls -lh $local_backup_dir/ole_mysql_$DATE.sql |  mailx -s "$HOST Warning - OLE DB Dump looks Too Small - size = $actualsize bytes - Check Now!" $EMAIL
fi

echo $(timestamp) OLE DB Backup all done
exit 0
