# @name: PartialIndexbyBibIds.sh
# @version: 0.1
# @creation_date: 2017-11-30
# @license: GNU General Public License version 3 (GPLv3) <https://www.gnu.org/licenses/gpl-3.0.en.html>
# @author: Suresh Subramanian <suresh.s@htcindia.com>
#
# @purpose: Runs a partial reindex on OLE's Solr instance
#
# @instructions: PartialIndexbyBibIds script command should be run with parameter start bib Id value and End Bib Id Value e.g. ./PartialIndexbyBibIds.sh 10000 10100
# This script should also be run on Soas's OLE servers only as user 'ole15'

curl -v -u admin:admin -H "Accept: application/json" -X POST --data "fromBibId="$1"&toBibId="$2"&docPerThread=1000&numberOfThreads=5" https://james.lis.soas.ac.uk:8443/solr-client/partialIndexByBibIdRange -H "Content-Type:application/x-www-form-urlencoded";

