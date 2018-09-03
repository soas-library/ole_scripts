#!/usr/bin/perl
# @name: patron_feed_error_alert.pl
# @version: 1.1
# @creation_date: 2015-10-26
# @license: GNU General Public License version 3 (GPLv3) <https://www.gnu.org/licenses/gpl-3.0.en.html>
# @author: Tim Green <tg3@soas.ac.uk>
#
# @purpose:
# This program will scan the $OLE_PATRON/report directory looking for any patron import errors reported 
# by the OLE poller.  It will collate these and send a warning message by email to library.systems@soas.ac.uk 
#
# This program is called with no parameters.
#
# @edited_date: 2015-10-26 Work started
# @edited_date: 2015-11-15 Added Alex Shipman to list of alert recipients as he is in a possition to investigate and resolve sources of some of these errors.

require 5.10.1;

use strict;

use POSIX qw(strftime);
use Switch;
use File::Find;
#use File::Grep;

#my $MODE               = 'TEST';
my $MODE                = 'LIVE';
#my $PATRON_ROOT        = $ENV{'OLE_PATRON'};
my $PATRON_ROOT         = '/usr/local/ole15/kuali/main/prd/olefs-webapp/patrons'; # Specific to james.lis.soas.ac.uk
#my $PATRON_ROOT = "/home/ole15/kuali/main/qa_william/olefs-webapp/patrons"; # Specific to william.lis.soas.ac.uk
#my $PATRON_ROOT = "/usr/local/ole15/kuali/main/dev_lisbet/olefs-webapp/patrons"; # Specific to lisbet.lis.soas.ac.uk
my $PATRON_REPORT       = "$PATRON_ROOT/report";
my $PATRON_PROBLEM      = "$PATRON_ROOT/problem";
my $LOG_DIR             = '/home/ole_B2017/logs';
my $program_id          = "patron_feed_error_alert_V1-1.pl";
my $program_log         = "$LOG_DIR/patron_poller_import_errors.log";
my $ERROR_REPORT        = '/home/ole_B2017/patron_error_report.txt';

my $email_address       = $MODE eq 'TEST' ? 'ft9@soas.ac.uk' : 'library.systems@soas.ac.uk as126@soas.ac.uk ap87@soas.ac.uk sb174@soas.ac.uk md11@soas.ac.uk csbs@soas.ac.uk';


my @file_list;
my @find_dirs       = ($PATRON_REPORT);         # directories to search
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
    exit_dir_not_exists($PATRON_ROOT);
    exit_dir_not_exists($PATRON_REPORT);
    exit_dir_not_exists($PATRON_PROBLEM);
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

sub report_patron_errors {
    my @failures = @_;
    my $filename = $ERROR_REPORT;
    open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
    my $report   = '';

    for my $message (@failures) {
        chomp($message);
        my ($fail, $report_file, $patronId, $message) = split(', ',$message);
        log_message("Info:\treport_file: $report_file, message: $message");
        print $fh "Patron_XML_file: $report_file\tPatron Id: $patronId\t\tError: $message\n";
    }

    close $fh;
    log_message("Info:\tSending email: mailx -s 'OLE Patron poller failure report for the last 24hrs' $email_address < $filename");
    my $err = system("mailx -s 'OLE Patron poller failure report for the last 24hrs' $email_address < $filename");
    log_message("Info:\tSending email Error = $err:$!");
}

sub check_patron_import_errors {
    #log_message("Info:\tLooking for reports in @find_dirs");
    find ( sub {
        my $file = $File::Find::name;
        if ( -f $file ) {
            my @stats = stat($file);
            if ($now-$stats[9] <= $DAY) {
                log_message ("Info:\tThis file is from the last 24 hours: $file");
                push (@file_list, $file);
            }
        }
    }, @find_dirs);

    my @failures = grep { contains($_, 'Failure') } @file_list;
    my $mesg = "Info:\tFound @{[$#file_list + 1]} patron reports @{[$#failures +1]} are failure warnings";
    log_message($mesg);
    if (@failures) {
        report_patron_errors (@failures);
    }
}

sub main {
    open program_log, ">>$program_log" or die "Cannot open $program_id log: $!";
    log_message("Info: Looking for any error messages from OLE patron poller");
    check_environment();
    check_patron_import_errors();
    log_message("Info: All done");
}

main();
