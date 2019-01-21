#!/usr/bin/perl -w
# @name: monitor_loan_item_mismatches.pl
# @version: 0.2
# @creation_date: 2018-01-29
# @edit_date: 2018-08-20
# @license: GNU General Public License version 3 (GPLv3) <https://www.gnu.org/licenses/gpl-3.0.en.html>
# @author: Simon Barron <sb174@soas.ac.uk>
#
# @purpose: Check for mismatches between the ole.ole_ds_item_t table and the ole.ole_dlvr_loan_t database tables and send an email when a mismatch is detected. 
#
use strict;
use warnings;

use POSIX qw(strftime);
use DBI;

my $data_source = q/DBI:mysql:ole/;
my $user = 'xxxxxxxx';
my $password = 'xxxxxxxx';
my $dbname = '';

my $email_address = 'library.systems@soas.ac.uk';
my $ERROR_REPORT = '/home/ole_B2017/monitor_loan_item_mismatches.txt';

my $LOG_DIR = "/home/ole_B2017/logs/";
my $SQLFile = '/home/ole_B2017/sql/mismatch_loan_item.sql';
my $program_log = "monitor_loan_item_mismatches.log";
my $program_id = "monitor_loan_item_mismatches.pl";
my $message;
my $timestamp;
my $myConnection;
my $query;
my $result;
my $barcode;
my @barcodes;

##############################################################################################################
sub log_message {
	# Writes messages to the log file
	my $message = shift;
	my $timestamp = strftime("%Y%m%d%H%M%S", localtime);
	print program_log ("$timestamp\t$program_id\t$message\n") or die "Cannot print $program_log log file: $!";
}

sub check_for_mismatches {
	$myConnection = DBI->connect($data_source, $user, $password)
		or die "Can't connect to $data_source: $DBI::errstr";
	
	# Obtain the SQL Statement
	open(INPUT, "<" . $SQLFile) or die "Can't open $SQLFile for reading: $!"; 
	my $SQLString;
	{ local $/ = undef;     # Read entire file at once
	$SQLString = <INPUT>;      # Return file as one single `line'
	}                       # $/ regains its old value	
	close(INPUT);

	# Prepare the SQL statement.
	$query = $myConnection->prepare($SQLString)
		or die "Can't prepare statement: $DBI::errstr";

	$query->execute();
	
	# Check whether the query returned empty or not
	# if ($query eq ''){
	# 	log_message("No mismatch detected");
	# }
	# # If not empty, push barcodes into array
	# else {
	
	# 	while (my @row = $query->fetchrow_array) {
	# 		$barcode = "$row[1]\n";
	# 		push @barcodes, $barcode;
	# 	}
	# 	# Begin subroutine to send report of mismatches
	# 	report_mismatches (@barcodes);
	# }
	
	my $count = 0;
	
	while (my @row = $query->fetchrow_array) {
		$barcode = "$row[1]\n";
		push @barcodes, $barcode;
	
		my $filename = $ERROR_REPORT;
		
		open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
		my $report   = '';
	
		foreach my $line(@barcodes) {
			log_message("Mismatch detected between loans and items table on item barcode:\t$line");
			print $fh "Mismatch detected between loans and items table on item barcode:\t$line\n";
		}

		close $fh;
		
		$count++;
	}
	
	if ($count){
		# Begin subroutine to send report of mismatches
		report_mismatches (@barcodes);
	}
	
	$myConnection->disconnect;
}

sub report_mismatches {
	# Sends report of mismatches to specified email address
	my $filename = $ERROR_REPORT;

	log_message("Info:\tSending email: mailx -s 'OLE: loans mismatch detected' $email_address < $filename");
	my $err = system("mailx -s 'OLE: loans mismatch detected' $email_address < $filename");
	log_message("Info:\tSending email Error = $err:$!");
}

################################################################################################################
sub main{
	open program_log, ">>$LOG_DIR$program_log" or die "Cannot open $program_id log: $!";
	check_for_mismatches;
}

main();
