#!/usr/bin/perl
# @name: notices_sent_alert_v0-4.pl
# @version: 0.4
# @creation_date: 2015-04-10
# @license: GNU General Public License version 3 (GPLv3) <https://www.gnu.org/licenses/gpl-3.0.en.html>
# @author: Tim Green <tg3@soas.ac.uk>
#
# @purpose:
# This program will scan the OLE notice directory looking for notices generated within the last 24hrs.
# It will collate these and send a simple report by email to library.systems@soas.ac.uk 
#
# This program is called with no parameters.
#
# @edited_date: 2015-10-16

require 5.10.1;

use strict;

use POSIX qw(strftime);
use Switch;
use File::Find;
#use File::Grep;

#my $MODE               = 'TEST';
my $MODE                = 'LIVE';
#my $NOTICES_ROOT = "/usr/local/ole15/kuali/main/prd/olefs-webapp/work/staging/"; # Specific to james.lis.soas.ac.uk
my $NOTICES_ROOT = "/home/ole15/kuali/main/qa_william/olefs-webapp/work/staging/"; # Specific to william.lis.soas.ac.uk
#my $NOTICES_ROOT = "/usr/local/ole15/kuali/main/dev_lisbet/olefs-webapp/work/staging/"; # Specific to lisbet.lis.soas.ac.uk
my $LOG_DIR             = '/home/ole_B2017/logs';
my $program_id          = $0;
my $program_log         = "$LOG_DIR/notices_sent.log";
my $NOTICES_REPORT      = '/home/ole_B2017/notices_sent_report.html';

my $email_address       = $MODE eq 'TEST' ? 'ft9@soas.ac.uk' : 'library.systems@soas.ac.uk';

my @file_list;
my @find_dirs       = ($NOTICES_ROOT);        # directories to search
my $now             = time();                   # get current time
my $days            = 30;                       # how many days old
my $DAY             = 60*60*24;                 # seconds in a day
my $AGE             = 60*60*7;                  # age in seconds i.e. 7 hours

sub log_message {
	my $message = shift;
	my $timestamp = strftime("%Y%m%d%H%M%S", localtime);
	print program_log ("$timestamp\t$program_id\t$message\n") or die "Cannot print $program_log log file: $!";
	print "$timestamp\t$program_id\t$message\n" if ($MODE eq 'TEST');
}

sub exit_dir_not_exists {
	my $dir = shift;
	if (! -d $dir) {
		log_message( "Fatal error:\tDir '$dir' must exist! Program exiting.");
		exit 1;
	}
}

sub check_environment {
	exit_dir_not_exists($NOTICES_ROOT);
	exit_dir_not_exists($LOG_DIR);
}

#sub contains_pattern {
#    my ($file,$pattern) = @_;
#    open my $fh, "<", $file
#        or die "Couldn't read '$file': $!";
#    grep { /$pattern/ } <$fh>;
#};

sub contains {
	my ($file, $search) = @_;

	open my $fh, '<', $file or die $!;

	while (<$fh>) {
		return 1 if /$search/;
	}

	return;
}

sub report_notices_generated {
	my @notices = @_;
	my $filename = $NOTICES_REPORT;
	open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
	my @report;

	for my $notice (@notices) {
		#my ($file_date, $file, $notice_type, $barcode, $date) = $notice =~ m/^(.*) -> (.*\/([^\/]*)_(.{10})_(.{28})\.pdf)$/;
		my ($file_date, $file, $notice_type, $barcode, $date) = $notice =~ m/^(.*) -> ((.*)_(\d+.)_(.{28})\.pdf)$/;
		push @report, sprintf "%-35s %-35s %-35s %-40s %-s", "Notice: $notice_type","Date: $file_date","Barcode: $barcode","Date $date","File: $file";
		log_message("Notice: $notice_type\tDate: $file_date\tBarcode: $barcode\tDate $date\tFile: $file");
	}

	print $fh '<html><body><pre>' . join("<br>", sort(@report)) . '</pre></body></html>';
	close $fh;
	log_message("Info:\tSending email: echo 'Please see attached file for list of notices sent in last 24hrs' | mailx -a '$filename' -s 'Notices generated in the last 24hrs' $email_address");
	my $err = system("echo 'Please see attached file for list of notices sent in last 24hrs' | mailx -a '$filename' -s 'Notices generated in the last 24hrs' $email_address");
	log_message("Info:\tSending email Error = $!");
}

sub list_notices {
	log_message("Info:\tLooking for notices in @find_dirs");

	opendir(DIR, $NOTICES_ROOT) or die $!;
	while (my $file = readdir(DIR)) {
		my $filepath = "$NOTICES_ROOT$file";
		my @stats = stat($filepath);
		if ($now-$stats[9] <= $DAY) {
			log_message ("Info:\tThis file is from the last 24 hours: $file");
			if ($file =~ /\.pdf$/) {
				my $date = strftime("%Y/%m/%d %H:%M:%S",localtime($stats[9]));
				push (@file_list, "$date -> $file");
			}
		}
    }

	closedir(DIR);
	my $mesg = "Info:\tFound @{[$#file_list + 1]} notices";
	log_message($mesg);

	report_notices_generated (sort(@file_list));
}

sub main {
	open program_log, ">>$program_log" or die "Cannot open $program_id log: $!";
	log_message("Info: Looking for notices generated in the last 24hrs");
	check_environment();
	list_notices();
	log_message("Info: All done");
}

main();
