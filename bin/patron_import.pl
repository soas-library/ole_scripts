#!/usr/bin/perl -w
# @name: patron_import.pl
# @version: 1.8
# @creation_date: 2015-04-10
# @license: GNU General Public License version 3 (GPLv3) <https://www.gnu.org/licenses/gpl-3.0.en.html>
# @author: Simon Bowie <sb174@soas.ac.uk>
# @author: Tim Green <tg3@soas.ac.uk>
#
# @purpose:
# This program will mount an SMB shared drive and then copy XML files across to the required folder for the OLE polling service to pick up.
#
# It will then unmount the SMB drive.
#
# This program is called with no parameters.
#
# @edited_date: 2015-08-16 Remove routines to mount and unmount $FILE_DIR as done in OS now
# @edited_date: 2015-08-16 Remove routines and variables associated with getting user id & password to use during mount process
# @edited_date: 2015-08-16 Refactor setting of global variables to facilitate testing sub environment('Test') or environment('Live')
# @edited_date: 2015-08-18 Added routine to tag patron.xml file with new_ or xmod_ depending on where they came from avoids any chance of name conflict.
# @edited_date: 2015-09-25 Adusted code to add file name tags to moved source files rather than retaining original names for same reason
# @edited_date: 2015-11-03 Included Mark and Alex Shipman in error alert emails 
# @edited_date: 2016-07-04 Adjusted to move processed files to .../Archives rather than .../Archives/2015
# @edited_date: 2017-09-21 Added Simon Bowie and Alistair Patient to error alert emails
# @edited_date: 2018-11-28 Added patron deletions functionality

require 5.10.1;

use strict;

use POSIX qw(strftime);
use Switch;
#use File::Slurp;
use DBI;

################################################################################################################# 
#
# IMPORTANT: $ENV should be set to Test or Live  - NB Live mode must only be enabled on James
#
#################################################################################################################
#my $ENV                 = 'Live';
my $ENV                = 'Test';

# _DIR constants should not be set here: see sub environment()
my $PATRON_HOME_DIR                = '';
my $PATRON_SOURCE_BASE_DIR         = '';
my $PATRON_SOURCE_NEW_DIR          = '';
my $PATRON_SOURCE_UPDATES_DIR      = '';
my $PATRON_PROBLEMS_DIR            = '';
my $PATRON_ARCHIVE_DIR             = '';
my $PATRON_SOURCE_DELETIONS_DIR	   = '';
my $PATRON_SOURCE_DELETIONS_ARCHIVE_DIR = '';
my $OLE_PATRON_POLLING_DIR         = '';
my $OLE_PATRON_SCHEMA              = '';
my $LOG_DIR                        = '';
my $XML_LINT_ERROR_FILE            = '/tmp/xmllint.txt';
my $PATRON_SOURCE_BASE_DIR_MASTER  = ''; # Only used during testing
my $EMAIL_ADDRESS                  = '';
my $deletion_files                 = '';
my $sql_file_update                = '';
my $data_source;
my $user                           = 'xxxxxxxxxxxx';
my $password                       = 'xxxxxxxxxxxx';
my $dbname                         = 'xxxxxxxxxxxx';

my $program_id = $0;
my $program_log = $ENV . "_patron_import.log";
my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime);
my $date = strftime("%d.%m.%y", localtime);
my $file_date = strftime("%d-%m-%y", localtime);
my $file_time = strftime("%H.%M", localtime);
my $file_name="xml-";

my @newPatronFiles;
my @newPatronUpdateFiles;

my $CMD;
my $message;
my $query;

sub log_message {
	my $message = shift;
	my $timestamp = strftime("%Y%m%d%H%M%S", localtime);
	print program_log ("$timestamp\t$program_id\t$message\n") or die "Cannot print $program_log log file: $!";
	print "$timestamp\t$program_id\t$message\n" if $ENV eq 'Test';
	if ($message =~ /^Error|Warning/) {
		chomp $message;
		my $err = system("echo '$timestamp\t$program_id\t$message' | mailx -s 'Patron Feed Problem!' $EMAIL_ADDRESS");
		print "$timestamp\t$program_id\tSending email: echo '$timestamp\t$program_id\t$message' | mailx -s 'Patron Feed Problem!' $EMAIL_ADDRESS\n" if $ENV eq 'Test';
		print program_log ("$timestamp\t$program_id\tSending email: echo '$timestamp\t$program_id\t$message' | mailx -s 'Patron Feed Problem!' $EMAIL_ADDRESS\n");
	}
}

sub environment {
	my $env = shift;
	switch ($env) {
		case 'Test' {
			$PATRON_HOME_DIR                ='/home/ole_B2017';
			$PATRON_SOURCE_BASE_DIR         ='Test_User_Import';
			$PATRON_SOURCE_BASE_DIR_MASTER  ='Master_Test_User_Import';
			$PATRON_SOURCE_NEW_DIR          ="$PATRON_HOME_DIR/$PATRON_SOURCE_BASE_DIR/new";
			$PATRON_SOURCE_UPDATES_DIR      ="$PATRON_HOME_DIR/$PATRON_SOURCE_BASE_DIR/mods";
			$PATRON_PROBLEMS_DIR            ="$PATRON_HOME_DIR/$PATRON_SOURCE_BASE_DIR/problems";
			$PATRON_ARCHIVE_DIR             ="$PATRON_HOME_DIR/$PATRON_SOURCE_BASE_DIR/Archives";
			$OLE_PATRON_POLLING_DIR         ='/home/ole_B2017/Test_Patrons/pending';
			$OLE_PATRON_SCHEMA              ="$PATRON_HOME_DIR/olePatronRecord.xsd";
			$LOG_DIR                        ='/home/ole_B2017/logs';
			$EMAIL_ADDRESS                  ='sb174@soas.ac.uk';
			$PATRON_SOURCE_DELETIONS_DIR 	= "$PATRON_HOME_DIR/$PATRON_SOURCE_BASE_DIR/dels";
			$PATRON_SOURCE_DELETIONS_ARCHIVE_DIR = "$PATRON_SOURCE_DELETIONS_DIR/deletions_archive";
			$deletion_files                 = "$PATRON_SOURCE_DELETIONS_DIR/del-*.txt";
			$sql_file_update                = '/home/ole_B2017/sql/update_expire_patrons.sql';
			$data_source                    = q/DBI:mysql:ole/;
		}
		case 'Live' {
			$PATRON_HOME_DIR                ='/mnt'; # This should be mnt/BLMS or somthing similar mounting directly
			$PATRON_SOURCE_BASE_DIR         ='BLMS/Live_User_Import';
			$PATRON_SOURCE_NEW_DIR          ="$PATRON_HOME_DIR/$PATRON_SOURCE_BASE_DIR/new";
			$PATRON_SOURCE_UPDATES_DIR      ="$PATRON_HOME_DIR/$PATRON_SOURCE_BASE_DIR/mods";
			$PATRON_PROBLEMS_DIR            ="$PATRON_HOME_DIR/$PATRON_SOURCE_BASE_DIR/problems";
			$PATRON_ARCHIVE_DIR             ="$PATRON_HOME_DIR/$PATRON_SOURCE_BASE_DIR/Archives";
			#$OLE_PATRON_POLLING_DIR         ='/usr/local/ole15/kuali/main/prd/olefs-webapp/patrons/pending';      # Specific to james.lis.soas.ac.uk
			#$OLE_PATRON_POLLING_DIR	='/home/ole15/kuali/main/qa_william/olefs-webapp/patrons/pending/'; # Specific to william.lis.soas.ac.uk
			$OLE_PATRON_POLLING_DIR	='/usr/local/ole15/kuali/main/dev_lisbet/olefs-webapp/patrons/pending/'; # Specific to lisbet.lis.soas.ac.uk
			$OLE_PATRON_SCHEMA              ="/home/ole_B2017/olePatronRecord.xsd";
			$LOG_DIR                        ='/home/ole_B2017/logs'; # Think of better home for these
			$EMAIL_ADDRESS                  ='library.systems@soas.ac.uk md11@soas.ac.uk as126@soas.ac.uk bj1@soas.ac.uk ft9@soas.ac.uk ap87@soas.ac.uk sb174@soas.ac.uk';
			$PATRON_SOURCE_DELETIONS_DIR 	= "$PATRON_HOME_DIR/$PATRON_SOURCE_BASE_DIR/dels";
			$PATRON_SOURCE_DELETIONS_ARCHIVE_DIR = "$PATRON_SOURCE_DELETIONS_DIR/deletions_archive";
			$deletion_files                 = "$PATRON_SOURCE_DELETIONS_DIR/del-*.txt";
			$sql_file_update                = '/home/ole_B2017/sql/update_expire_patrons.sql';
			$data_source                    = q/DBI:mysql:ole/;
		}
	}
}

sub exit_dir_not_exists {
	my $dir = shift;
	if (! -d $dir) {
		log_message( "Fatal error:\tDir '$dir' must exist! Program exiting.");
		# To Do: include email alert to library.systems here!
		exit 1;
	}
}

sub check_environment {
	exit_dir_not_exists($PATRON_SOURCE_NEW_DIR);
	exit_dir_not_exists($PATRON_SOURCE_UPDATES_DIR);
	exit_dir_not_exists($PATRON_PROBLEMS_DIR);
	exit_dir_not_exists($PATRON_ARCHIVE_DIR);
	exit_dir_not_exists($OLE_PATRON_POLLING_DIR);
	exit_dir_not_exists($LOG_DIR);
	exit_dir_not_exists($PATRON_SOURCE_DELETIONS_DIR);
	log_message("Info:\tAll required directories located");
}

sub remove_dir_and_contents {
	my $dir = shift;
	my $err = system("rm -R $dir");
	log_message("Info:\tRemoving $dir\tError = $err\tEnvironment = $ENV");
	return $err;
}

sub copy_dir_and_contents {
	my $srcDir      = shift;
	my $targetDir   = shift;
	my $err = system("cp -R $srcDir $targetDir");
	log_message("Info:\tCopying $srcDir to $targetDir\tError = $err:$!\tEnvironment = $ENV");
	return $err;
}

sub create_dir {
	my $newDir = shift;
	my $err = system("mkdir -p $newDir");
	log_message("Info:\tMkdir -p $newDir\tError = $err\tEnvironment = $ENV");
	return $err
}

sub count_files {
	my $filePattern = shift;
	my @files = glob( $filePattern );
	return $#files + 1
}

sub test_dir_contains_x_files {
#       print "test_dir_contains: " . @_ . " params\n";
#       foreach my $arg (@_) {
#               print "$arg\n";
#       } 
	my $testDesc                    = shift;
	my $testFilePattern             = shift;
	my $testFilePatternCount        = shift;

	my $numFiles = count_files($testFilePattern);
	if ($numFiles == $testFilePatternCount) {
		log_message("Test:\tSuccess ->\t$testDesc\tExpected: $testFilePatternCount Found: $numFiles\tPattern: $testFilePattern");
	} else {
		log_message("Test:\tFail    ->\t$testDesc\tExpected: $testFilePatternCount Found: $numFiles\tPattern: $testFilePattern");
	}
}

sub test_initialise {
	#make a copy of the Master source dir as we will be adjusting its contents
	#by moving the files we are processing from the new and mods dir to the
	#Archive dir
	remove_dir_and_contents("$PATRON_HOME_DIR/$PATRON_SOURCE_BASE_DIR");
	copy_dir_and_contents("$PATRON_HOME_DIR/$PATRON_SOURCE_BASE_DIR_MASTER","$PATRON_HOME_DIR/$PATRON_SOURCE_BASE_DIR");
	#remove the testing target dir hierarchy and recreate
	remove_dir_and_contents($OLE_PATRON_POLLING_DIR);
	create_dir($OLE_PATRON_POLLING_DIR);
}

sub test_run {
	test_dir_contains_x_files("Confirming new patron test data in place", "$PATRON_HOME_DIR/$PATRON_SOURCE_BASE_DIR_MASTER/new/*.xml", 34);
	test_dir_contains_x_files("Confirming modified patron test data in place", "$PATRON_HOME_DIR/$PATRON_SOURCE_BASE_DIR_MASTER/mods/*.xml",14);
	test_dir_contains_x_files("Confirming all valid patron XML new and modified files copied to pending for processing", "$OLE_PATRON_POLLING_DIR/*.xml", 41);
	test_dir_contains_x_files("Confirming all valid patron XML new files copied to pending for processing and tagged new_", "$OLE_PATRON_POLLING_DIR/new_*.xml", 32);
	test_dir_contains_x_files("Confirming all valid patron XML mod files copied to pending for processing and tagged xmod_", "$OLE_PATRON_POLLING_DIR/xmod_*.xml", 9);
	test_dir_contains_x_files("Confirming all valid patron XML new files copied to Archive dir", "$PATRON_ARCHIVE_DIR/new_*.xml", 32);
	test_dir_contains_x_files("Confirming all valid patron XML mod files copied to Archive dir", "$PATRON_ARCHIVE_DIR/xmod_*.xml", 9);
	test_dir_contains_x_files("Confirming INVALID new patron files copied to problems dir", "$PATRON_PROBLEMS_DIR/new_*.xml", 2);
	test_dir_contains_x_files("Confirming INVALID mod patron files copied to problems dir", "$PATRON_PROBLEMS_DIR/xmod_*.xml", 5);
}

sub read_file {
	my $file = shift;
	open(FILE, $file ) or die "Can't read file 'filename' [$!]\n";
	my $content = <FILE>;
	close (FILE);
	return $content;
}

sub check_patron_xml {
	my $file = shift;
	system("xmllint --noout --schema $OLE_PATRON_SCHEMA $file 2> $XML_LINT_ERROR_FILE");
	my $err = $?;
	my $errMsg = read_file($XML_LINT_ERROR_FILE) ;
	log_message("Warning:\txmllint --noout --schema $OLE_PATRON_SCHEMA $file\tError: $err\tMessage: $errMsg") if ($err != 0);
	return ($err, $errMsg);
}

sub copy_file {
	my $sourceFile = shift;
	my $targetFile = shift;
	my $err = system("cp $sourceFile $targetFile");
	log_message("Info:\tcp $sourceFile $targetFile\tError = $err\tEnvironment = $ENV");
	return $err
}

sub move_file {
	my $sourceFile = shift;
	my $targetFile = shift;
	my $err = system("mv $sourceFile $targetFile");
	log_message("Info:\tmv $sourceFile $targetFile\tError = $err\tEnvironment = $ENV");
	return $err
}

sub process_patron_file {
	my $path                        = shift;
	my $file                        = shift;
	my $fileNameTag                 = shift;
	my ($xmlErr, $xmlErrMsg)        = check_patron_xml("$path/$file");
	# Only copy file to polling dir and move it to the Archive dir if it passes the xml validation test.
	if ($xmlErr == 0) {
		if (copy_file("$path/$file", "$OLE_PATRON_POLLING_DIR/$fileNameTag$file") == 0) {move_file("$path/$file", "$PATRON_ARCHIVE_DIR/$fileNameTag$file")};
	} else {
		move_file("$path/$file", "$PATRON_PROBLEMS_DIR/$fileNameTag$file");
	}
}

sub process_patron_files {
	# 
	# Process all of the new patron files
	#
	foreach my $patronFile (@newPatronFiles) {
		process_patron_file($PATRON_SOURCE_NEW_DIR, $patronFile, 'new_');
	}

	#################################################################################################################### 
	#
	# Process all of the update patron files - 
	# 
	# IMPORTANT: xmod chosen to ensure all patron updates appear after new files for any given run in the polling dir.  
	#
	# Not clear wether polling picks up files based on time they are created in
	# the polling dir or alphabetically - Hence new files processed first and name prefix to chosen to ensure they occur
	# last in any alphabetic listing
	#
	####################################################################################################################
	foreach my $patronUpdateFile (@newPatronUpdateFiles) {
		process_patron_file($PATRON_SOURCE_UPDATES_DIR, $patronUpdateFile, 'xmod_');
	}
}

sub get_new_patron_files {
	my $path = shift;
	my $fileSpec = shift;
	chdir ($path);
	return glob( $fileSpec);
}

sub process_deletion_files
{
	foreach my $file (glob($deletion_files)) {
		open(my $fh, '<:encoding(UTF-8)', $file)
			or die "Could not open file '$file' $!";
 
		while (my $row = <$fh>) {
			chomp $row;
			my @elements = split /,/, $row;
			my $patron_id = $elements[-1];
			
			my $result = run_patron_deletions_sql($patron_id);
			
			if ($result eq 'Successfully updated') {
				move_deletion_files($file);
			}
			else {
				$message = $result;
				log_message;
			}
		}
	}
}

sub run_patron_deletions_sql
{
	my $database_connection = DBI->connect($data_source, $user, $password)
		or die "Can't connect to $data_source: $DBI::errstr";
	
	# Obtain the SQL Statement
	open(INPUT, "<" . $sql_file_update) or die "Can't open $sql_file_update for reading: $!"; 
	my $sql_string;
	{ local $/ = undef;     # Read entire file at once
		$sql_string = <INPUT>;      # Return file as one single `line'
	}                       # $/ regains its old value	
	close(INPUT);

	# Prepare the SQL statement.
	$query = $database_connection->prepare($sql_string)
		or die "Can't prepare statement: $DBI::errstr";
		
	my $patron_id = shift;
		
	my $return = $query->execute($patron_id)
		or die "Couldn't execute query: " . $query->errstr;

	# while (my @row = $query->fetchrow_array)
	# {
		# print "@row\n";
	# }

	if ($return) {
		if ($return eq '0E0') {
			my $error = "No rows updated";
			return($error);
		} 
		else {
			my $success = "Successfully updated";
			return($success);
		}
	} 
	else {
		my $error = "Connection error";
		return($error);
	}	
		
	$query->finish();

	$database_connection->disconnect;
}

sub move_deletion_files
{
	my $source_file = shift;
	my @source_file_elements = split /\//, $source_file;
	my $target_file = "$PATRON_SOURCE_DELETIONS_ARCHIVE_DIR/$source_file_elements[-1]";
	my $command = system("mv $source_file $target_file");
	return $command
}


sub main {
	# Set up environment appropriately for Test or Live running
	environment($ENV);
	open program_log, ">>$LOG_DIR/$program_log" or die "Cannot open $program_id log: $!";
	# Run Tests if $ENV eq Test
	test_initialise() if ($ENV eq 'Test');
	# Confirm access to all required directories is available.  NB will exit if all not OK
	check_environment();
	# Process deletion files
	log_message ("Info:\tStarted processing deletion files");
	process_deletion_files;
	log_message ("Info:\tFinished processing deletion files");
	# Get lists of all new and update Patron files to be processed
	log_message ("Info:\tStarted processing\tEnvironment = $ENV");
	@newPatronFiles = get_new_patron_files( $PATRON_SOURCE_NEW_DIR,  '*.xml' );
	log_message ("Info:\tNew patron files: @{[$#newPatronFiles + 1]}" );
	@newPatronUpdateFiles = get_new_patron_files ( $PATRON_SOURCE_UPDATES_DIR, '*.xml' );
	log_message ("Info:\tNew patron update files: @{[$#newPatronUpdateFiles +1]}");
	# Process all of the patron files
	process_patron_files();
	# All done
	log_message("2017 Info:\tFinished processing\tEnvironment = $ENV");
	# Check all as expected if running in test mode
	test_run() if ($ENV eq 'Test');
	close program_log or die "Cannot close program log: $!";
}

main();
