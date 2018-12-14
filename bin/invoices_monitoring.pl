#!/usr/bin/perl
# @name: invoices_monitoring.pl
# @version: 1.0
# @creation_date: 2018-12-14
# @license: GNU General Public License version 3 (GPLv3) <https://www.gnu.org/licenses/gpl-3.0.en.html>
# @author: Simon Bowie <sb174@soas.ac.uk>
#
# @purpose:
# This script will scan the directory where the Agresso-OLE interface deposits invoices files. It looks for invoices created the previous day and, if there are no invoices created the previous day, sends an email to library.systems and ec7.
#
# This program is called with no parameters.
#

require 5.10.1;

use strict;

use POSIX qw(strftime);
use Switch;
use File::Find;
use constant ONE_DAY => 24 * 60 * 60;

my $MODE               = 'TEST';
#my $MODE                = 'LIVE';
#my $INVOICES_DIR = "/usr/local/2ndhome/kuali/main/prd/olefs-webapp/Agresso"; # Specific to james.lis.soas.ac.uk
#my $INVOICES_DIR = "/usr/local/2ndhome/kuali/main/qa_william/olefs-webapp/Agresso"; # Specific to william.lis.soas.ac.uk
my $INVOICES_DIR = "/usr/local/2ndhome/kuali/main/dev_lisbet/olefs-webapp/Agresso"; # Specific to lisbet.lis.soas.ac.uk
my $LOG_DIR             = '/home/ole_B2017/logs';
my $file_prefix         = 'LibraryInvoices_';
my $program_id          = $0;
my $program_log         = "$LOG_DIR/invoices_monitoring.log";
my $email_address       = 'sb174@soas.ac.uk';
#my $email_address		= 'library.systems@soas.ac.uk ec7@soas.ac.uk

my @yesterday = localtime time - ONE_DAY;
my $yesterday = strftime('%Y%m%d', @yesterday);

##############################################################################################################	

sub log_message {
	my $message = shift;
	my $timestamp = strftime("%Y%m%d%H%M%S", localtime);
	print program_log ("$timestamp\t$program_id\t$message\n") or die "Cannot print $program_log log file: $!";
	print "$timestamp\t$program_id\t$message\n" if ($MODE eq 'TEST');
}

##############################################################################################################	

sub exit_dir_not_exists {
	my $dir = shift;
	if (! -d $dir) {
		log_message( "Fatal error:\tDir '$dir' must exist! Program exiting.");
		exit 1;
	}
}

##############################################################################################################	

sub check_environment {
	exit_dir_not_exists($INVOICES_DIR);
	exit_dir_not_exists($LOG_DIR);
}

##############################################################################################################	

sub scan_for_invoices {
	log_message("Info:\tLooking for invoices files in $INVOICES_DIR");

	opendir(DIR, $INVOICES_DIR) or die $!;
	my @files = readdir(DIR);
	unless (grep(/^$file_prefix$yesterday\_.*.txt$/, @files)) {
		send_report();
	}
	else {
		log_message("Success: Invoices from $yesterday found");
	}
}

##############################################################################################################	

sub send_report {
	log_message("Issue:\tNo invoices from $yesterday found.\tSending email: mailx -s 'OLE: no invoices from $yesterday detected' $email_address");
	my $report = system("echo 'The OLE-Agresso interface did not generate any invoice files yesterday' | mailx -s 'OLE: no invoices detected' $email_address");
	log_message("Issue:\tSending email");
}

##############################################################################################################
#                      The main program flow follows
#
##############################################################################################################

sub main {
	open program_log, ">>$program_log" or die "Cannot open $program_id log: $!";
	log_message("Info:\tLooking for invoice files produced $yesterday");
	check_environment();
	scan_for_invoices();
	log_message("Info:\tInvoices monitoring complete");
}

main();
