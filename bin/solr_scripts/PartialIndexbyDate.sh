# @name: PartialIndexbyDate.sh
# @version: 0.1
# @creation_date: 2017-11-30
# @license: GNU General Public License version 3 (GPLv3) <https://www.gnu.org/licenses/gpl-3.0.en.html>
# @author: Suresh Subramanian <suresh.s@htcindia.com>
#
# @purpose: Runs a partial reindex on OLE's Solr instance
#
# @instructions: 
# PartialIndexbyDate script with optional parameter of integer value (i.e. 5 for index from current date -5). Default it will take as 1 (from previous day) e.g : 
# ./PartialIndexbyDate.sh 5 
# ./PartialIndexbyDate.sh
# This script should be run on Soas's OLE servers only as user 'ole15'

today=`date +%Y-%m-%d`
if [ -z $1 ]; then
    pastDay=$( date -d "${today} -1 days" +'%Y-%m-%d' )
else
    pastDay=$( date -d "${today} -$1 days" +'%Y-%m-%d' )
fi
echo $pastDay;
curl -v -u admin:admin -H "Accept: application/json" -X POST --data "fromDate="$pastDay"&docPerThread=1000&numberOfThreads=5" https://james.lis.soas.ac.uk:8443/solr-client/partialIndexByDate -H "Content-Type:application/x-www-form-urlencoded";

