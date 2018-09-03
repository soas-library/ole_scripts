# @name: PartialIndexbyFile.sh
# @version: 0.1
# @creation_date: 2017-11-30
# @license: GNU General Public License version 3 (GPLv3) <https://www.gnu.org/licenses/gpl-3.0.en.html>
# @author: Suresh Subramanian <suresh.s@htcindia.com>
#
# @purpose: Runs a partial reindex on OLE's Solr instance
#
# @instructions: 
# PartialIndexbyFile script file needs to be run with parameter of bibId file name with full path e.g. ./PartialIndexbyFile.sh /home/ole_B2017/bibIds.txt
# This script should be run on Soas's OLE servers only as user 'ole15'

curl -v -u admin:admin -H "Accept: application/json" -X POST -F "file=@"$1 -F "docPerThread=1000" -F "numberOfThreads=5" https://james.lis.soas.ac.uk:8443/solr-client/partialIndexByFile -H "Content-Type:multipart/form-data"
