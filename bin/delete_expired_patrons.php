<?php
# @name: delete_expired_patrons.php
# @version: 0.1
# @creation_date: 2018-05-08
# @license: GNU General Public License version 3 (GPLv3) <https://www.gnu.org/licenses/gpl-3.0.en.html>
# @author: Simon Barron <sb174@soas.ac.uk>
#
# @purpose: 
# This script deletes patrons in OLE who expired over 4 years ago: it removes any personal detail that could be used to uniquely identify the individual.
?>
<?php

date_default_timezone_set('Europe/London');
$servername = "localhost";
$username = "xxxxxxxx";
$password = "xxxxxxxx";
$dbname = "ole";
$run_date = date("Y-m-d H:i:s");
$expiration_date = "2014-06-01 00:00:00";

$output_report = '/home/ole_B2017/bin/delete_expired_patrons.txt';
$log_dir = "/home/ole_B2017/bin/logs/";
$sql_file_select = '/home/ole_B2017/sql/select_expired_patrons.sql';
$sql_file_delete = '/home/ole_B2017/sql/delete_one_patron.sql';
$program_log = "delete_expired_patrons.log";
$program_id = "delete_expired_patrons.php";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
} 

/* change character set to utf8 */
if (!$conn->set_charset("utf8")) {
    printf("Error loading character set utf8: %s\n", $conn->error);
    exit();
} else {
    #printf("Current character set: %s\n", $conn->character_set_name());
} 

// SELECT statement to get patron IDs based on expiration date
$select_sql = file_get_contents($sql_file_select);

$pattern = '/expiration_date/s';
$replacement = $expiration_date;
$select_sql = preg_replace($pattern, $replacement, $select_sql);

// Open first statement
$result = $conn->query($select_sql);

if ($result->num_rows > 0) {
    // Output data of each row
    while($row = mysqli_fetch_assoc($result)) {
	// Process one row at a time from first statement
	//while($row = $result->fetch_array(MYSQLI_ASSOC)) {
		#echo $row["OLE_PTRN_ID"];
		
		// Free stored results
		clearStoredResults($conn);
		
		// DELETE statement to delete patron and attached table rows based on patron IDs from first statement
		$ole_patron_id = $row["OLE_PTRN_ID"];
		$delete_sql = file_get_contents($sql_file_delete);
		
		$pattern = '/ole_patron_id/s';
		$replacement = $ole_patron_id;
		$delete_sql = preg_replace($pattern, $replacement, $delete_sql);
		
		// Execute multi-query using value from first statement as a parameter
		if ($conn->multi_query($delete_sql) === TRUE) {
			$log_message = file_get_contents($output_report);
			$log_message .= $run_date . " - Patron " . $ole_patron_id . " deleted successfully\n";
			file_put_contents($output_report, $log_message);
		} else {
			$log_message = file_get_contents($output_report);
			$log_message .= $run_date . " - Error updating record " . $ole_patron_id . ": " . $conn->error . "\n";
			file_put_contents($output_report, $log_message);
		}
		
    }
} else {
	$log_message = file_get_contents($output_report);
	$log_message .= $run_date . " - 0 results\n";
	file_put_contents($output_report, $log_message);
}

// Free results from first statement
$result->free();

$conn->close();

#------------------------------------------
function clearStoredResults($mysqli_link){
#------------------------------------------
    while($mysqli_link->next_result()){
      if($l_result = $mysqli_link->store_result()){
              $l_result->free();
      }
    }
}
?>
