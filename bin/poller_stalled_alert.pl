#!/usr/bin/perl
# @name: poller_stalled_alert_v0-1.pl
# @version: 0.1
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
my $PATRON_ROOT         = '/usr/local/ole15/kuali/main/prd/olefs-webapp/patrons/pending/'; # Specific to james.lis.soas.ac.uk
#my $PATRON_ROOT = "/home/ole15/kuali/main/qa_william/olefs-webapp/patrons/pending/"; # Specific to william.lis.soas.ac.uk
#my $PATRON_ROOT = "/usr/local/ole15/kuali/main/dev_lisbet/olefs-webapp/patrons/pending/"; # Specific to lisbet.lis.soas.ac.uk
my $LOG_DIR             = '/home/ole_B2017/logs';
my $program_id          = $0;
my $program_log         = "$LOG_DIR/patron_poller_status.log";
my $POLLER_REPORT       = '/home/ole_B2017/patron_poller_status_report.html';
my $email_address       = 'library.systems@soas.ac.uk ap87@soas.ac.uk sb174@soas.ac.uk csbs@soas.ac.uk';
##my $email_address     = $MODE eq 'TEST' ? 'library.systems@soas.ac.uk';
##my $email_address     = $MODE eq 'TEST' ? 'tg3@soas.ac.uk' : 'library.systems@soas.ac.uk tg3@soas.ac.uk';

my @file_list;
my @find_dirs       = ($PATRON_ROOT);        # directories to search
my $now             = time();                   # get current time
my $days            = 30;                       # how many days old
my $DAY             = 60*60*24;                 # seconds in a day
my $AGE             = 60*15;                    # age in seconds i.e. 15 minutes poller checks every 5 minutes so if files older than 15 we have a problem huston

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
    exit_dir_not_exists($PATRON_ROOT);
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

sub report_patron_files_waiting {
    my @patrons = @_;
    if (@patrons) {
    my $filename = $POLLER_REPORT;
    open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
    my @report;

    for my $patron (@patrons) {
        #my ($file_date, $file, $notice_type, $barcode, $date) = $notice =~ m/^(.*) -> (.*\/([^\/]*)_(.{10})_(.{28})\.pdf)$/;
        my ($file_date, $file) = $patron =~ m/^(.*) -> (.*)$/;
        push @report, sprintf "%-35s %-35s %-s", "Date: $file_date","File: $file","Patron: $patron";
        log_message("Date: $file_date\tFile: $file\tPatron: $patron");
    }

    print $fh '<html><body><pre>' . join("<br>", sort(@report)) . '</pre></body></html>';
    close $fh;
    log_message("Info:\tSending email: echo 'Please see attached file for list of patron records older than 15 minutes in poller pending' | mailx -a '$filename' -s 'Patron records in pending for more than 15 minutes' $email_address");
    my $err = system("echo 'Please see attached file for list of patron records older than 15 minutes in poller pending' | mailx -a '$filename' -s 'Patron records in pending for more than 15 minutes' $email_address");
    log_message("Info:\tSending email Error = $!");
    } else {
        log_message("All OK: No patron files in pending for more than 15 mins");
    }
}

sub check_poller {
    log_message("Info:\tLooking for patron xml files in @find_dirs");

    opendir(DIR, $PATRON_ROOT) or die $!;
    while (my $file = readdir(DIR)) {
        my $filepath = "$PATRON_ROOT$file";
        my @stats = stat($filepath);
        if ($now-$stats[9] >= $AGE) {
            log_message ("Info:\tThis file is older than 15 minutes: $filepath");
            if ($file =~ /\.xml$/) {
                log_message("Info:\t$file stats = $stats[0] $stats[1] $stats[2] $stats[3] $stats[4] $stats[5] $stats[6] $stats[7] $stats[8] $stats[9]");
                my $date = strftime("%Y/%m/%d %H:%M:%S",localtime($stats[9]));
                push (@file_list, "$date -> $file");
            }
        }
    }

    closedir(DIR);
    my $mesg = "Info:\tFound @{[$#file_list + 1]} pending patron files older than 15 minutes";
    log_message($mesg);

    report_patron_files_waiting (sort(@file_list));
}

sub main {
    open program_log, ">>$program_log" or die "Cannot open $program_id log: $!";
    log_message("Info: Looking for patron files that have been in the pending dir for more than 15 minutes");
    check_environment();
    check_poller();
    log_message("Info: All done");
}

main();
