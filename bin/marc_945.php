<?php
# @name: marc_945.php
# @version: 0.1
# @creation_date: 2017-12-07
# @license: GNU General Public License version 3 (GPLv3) <https://www.gnu.org/licenses/gpl-3.0.en.html>
# @author: Simon Barron <sb174@soas.ac.uk>
# @purpose: Find Marc records containing a 945 field in OLE's database and remove that field.
?>
<?php
$servername = "localhost";
$username = "xxxxxxxx";
$password = "xxxxxxxx";
$dbname = "";
$expiration_date = date("Y-m-d H:i:s");

// Create connection
$conn = new mysqli($servername, $username, $password);

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

$sql = "SELECT bib.BIB_ID, bib.CONTENT
FROM ole.ole_ds_bib_t bib
WHERE bib.CONTENT REGEXP '<datafield tag=\"945\".*<\/datafield>'
;
";
#AND bib.BIB_ID BETWEEN 203000 AND 206000
#;
#";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    // output data of each row
    while($row = mysqli_fetch_assoc($result)) {
		$ole_bib_id = $row["BIB_ID"];
		$ole_content = $row["CONTENT"];
		#echo htmlspecialchars($ole_content);
		#echo '</br></br>';
		$pattern = '/<datafield tag="945".*<\/datafield>/s';
		$replacement = '';
		$ole_content = preg_replace($pattern, $replacement, $ole_content);
        #echo htmlspecialchars($ole_content);
		
		$ole_content = $conn->real_escape_string($ole_content);
		
		$update_sql = "UPDATE ole.ole_ds_bib_t bib SET bib.content = '" . $ole_content . "' WHERE bib.BIB_ID = " . $ole_bib_id . ";";
		
		#$update_sql = $conn->real_escape_string($update_sql);
		
		if ($conn->query($update_sql) === TRUE) {
			echo "Bib ID no. " . $ole_bib_id . " updated successfully\n";
		} else {
			echo "Error updating record " . $ole_bib_id . ": " . $conn->error . "\n";
		}
    }
} else {
    echo "0 results";
}

$conn->close();
?>
