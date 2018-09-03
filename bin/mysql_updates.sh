#!/bin/bash
# @name: mysql_updates.sh
# @version: 1.0
# @creation_date: Unknown
# @license: GNU General Public License version 3 (GPLv3) <https://www.gnu.org/licenses/gpl-3.0.en.html>
# @author: Simon Barron <sb174@soas.ac.uk>
#
# @purpose:
# Update MySQL database for requests

mysql --user=xxxxxxxx --password=xxxxxxxx --database=ole --execute="UPDATE ole.ole_dlvr_rqst_t SET PCKUP_LOC_ID = 1 WHERE PCKUP_LOC_ID IS NULL"
