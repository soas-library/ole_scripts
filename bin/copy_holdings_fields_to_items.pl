#!/usr/bin/perl -w
# @name: copy_holdings_fields_to_items.pl
# @version: 0.1
# @creation_date: 2018-03-23
# @license: GNU General Public License version 3 (GPLv3) <https://www.gnu.org/licenses/gpl-3.0.en.html>
# @author: Simon Barron <sb174@soas.ac.uk>
#
# @purpose: Copy location and classmark fields from holdings records to item records
#
use strict;
use warnings;

use POSIX qw(strftime);
use DBI;

my $data_source = q/DBI:mysql:ole/;
my $user = 'xxxxxxxx';
my $password = 'xxxxxxxx';
my $dbname = '';

my $email_address = 'sb174@soas.ac.uk';
my $ERROR_REPORT = '/home/ole_B2017/copy_holdings_fields_to_items.txt';

my $LOG_DIR = "/home/ole_B2017/logs/";
my $SQLFile1 = '/home/ole_B2017/sql/copy_location_fields_to_items.sql';
my $SQLFile2 = '/home/ole_B2017/sql/copy_callnumber_fields_to_items.sql';
my $program_log = "copy_holdings_fields_to_items.log";
my $program_id = "copy_holdings_fields_to_items.pl";
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
#
	my $message = shift;
	my $timestamp = strftime("%Y%m%d%H%M%S", localtime);
	print program_log ("$timestamp\t$program_id\t$message\n") or die "Cannot print $program_log log file: $!";
}

sub copy_location_fields {
	$myConnection = DBI->connect($data_source, $user, $password)
		or die "Can't connect to $data_source: $DBI::errstr";
	
	# Obtain the SQL Statement
	open(INPUT, "<" . $SQLFile1) or die "Can't open $SQLFile1 for reading: $!"; 
	my $SQLString;
	{ local $/ = undef;     # Read entire file at once
	$SQLString = <INPUT>;      # Return file as one single `line'
	}                       # $/ regains its old value	
	close(INPUT);

	# Prepare the SQL statement.
	$query = $myConnection->prepare($SQLString)
		or die "Can't prepare statement: $DBI::errstr";

	$query->execute();

	log_message("Number of location fields affected: " . $query->rows . "\n");

	$myConnection->disconnect;
}

sub copy_callnumber_fields {
	$myConnection = DBI->connect($data_source, $user, $password)
		or die "Can't connect to $data_source: $DBI::errstr";
	
	# Obtain the SQL Statement
	open(INPUT, "<" . $SQLFile2) or die "Can't open $SQLFile2 for reading: $!"; 
	my $SQLString;
	{ local $/ = undef;     # Read entire file at once
	$SQLString = <INPUT>;      # Return file as one single `line'
	}                       # $/ regains its old value	
	close(INPUT);

	# Prepare the SQL statement.
	$query = $myConnection->prepare($SQLString)
		or die "Can't prepare statement: $DBI::errstr";

	$query->execute();

	log_message("Number of callnumber fields affected: " . $query->rows . "\n");

	$myConnection->disconnect;
}

################################################################################################################
sub main{
	open program_log, ">>$LOG_DIR$program_log" or die "Cannot open $program_id log: $!";
	copy_location_fields;
	copy_callnumber_fields;
}

main();