# @name: FullIndex.sh
# @version: 0.1
# @creation_date: 2017-11-30
# @license: GNU General Public License version 3 (GPLv3) <https://www.gnu.org/licenses/gpl-3.0.en.html>
# @author: Suresh Subramanian <suresh.s@htcindia.com>
#
# @purpose: Runs a full reindex on OLE's Solr instance
#
# @instructions: 
# Memory allocation is given as "10g". Increase or decrease the Memory as required. Give solr-client port as well (-p port no)
# This script should be run on Soas's OLE servers only as user 'ole15'

SOLR_DIR='/usr/local/2ndhome/solr-6.5.0/';
cd $SOLR_DIR/bin
./solr stop
echo "stopped solr";
cd ../server/solr
if [ -d temp* ]; then rm -r temp*;fi
echo "Removed temp dir";
cd bib/data
rm -r *
cd $SOLR_DIR/bin
./solr start -m 10g
echo "Solr started"
curl -v -u admin:admin -H "Accept: application/json" -X POST -d "{\"noOfDbThreads\":\"5\",\"docsPerThread\":\"10000\"}" https://james.lis.soas.ac.uk:8443/solr-client/fullIndex -H "Content-Type:application/json"
