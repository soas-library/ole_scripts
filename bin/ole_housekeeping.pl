#!/usr/bin/perl -w
# @name: ole_housekeeping.pl
# @version: 1.3
# @creation_date: 2014-12-03
# @license: GNU General Public License version 3 (GPLv3) <https://www.gnu.org/licenses/gpl-3.0.en.html>
# @author: Simon Barron <sb174@soas.ac.uk>
#
# @purpose:
# Perform housekeeping tasks on OLE servers: delete old files, etc.
#
# @edited_date: 2014-12-09
# @edited_date: 2015-04-15
# @edited_date: 2015-07-08
# @edited_date: 2017-08-25 Edited to clean up after the new batch export process.

use warnings;
use strict;
use POSIX qw(strftime);
use File::Path qw( make_path rmtree ); 

my $program_id = "ole_housekeeping";
my $LOGFILE = "/home/ole_B2017/logs/ole_housekeeping.log";

my $filecount = 0;
my $days;
my $file_prefix = "vufind_*";
my $directory = "";
my $xml_prefix = "201*";
my $source_server_name = "james";

# Note different directory locations for different OLE servers: comment out as appropriate

my $EXPORT_DIR = "/usr/local/ole15/kuali/main/prd/olefs-webapp/reports/"; # Specific to james.lis.soas.ac.uk
#my $EXPORT_DIR = "/usr/local/2ndhome/kuali/main/qa_$source_server_name/olefs-webapp/reports/"; # Specific to william.lis.soas.ac.uk
#my $EXPORT_DIR = "/usr/local/2ndhome/kuali/main/dev_$source_server_name/olefs-webapp/reports/"; # Specific to lisbet.lis.soas.ac.uk

my $IMPORT_DIR = "/usr/local/ole15/kuali/main/prd/olefs-webapp/patrons/problem/"; # Specific to james.lis.soas.ac.uk
#my $IMPORT_DIR = "/home/ole15/kuali/main/qa_william/olefs-webapp/patrons/problem/"; # Specific to william.lis.soas.ac.uk
#my $IMPORT_DIR = "/usr/local/ole15/kuali/main/dev_lisbet/olefs-webapp/patrons/problem/"; # Specific to lisbet.lis.soas.ac.uk

my $LOGS_DIR = "/usr/local/ole15/apache-tomcat-7.0.54/logs/"; # Specific to james.lis.soas.ac.uk
#my $LOGS_DIR = "/home/ole15/william_soas_tomcat/logs/"; # Specific to william.lis.soas.ac.uk
#my $LOGS_DIR = "/usr/local/ole15/apache-tomcat-7.0.54/logs/"; # Specific to lisbet.lis.soas.ac.uk

my $TODAY = time;
my $wktime = 604800; #(ie 86400*7)
my $ole_timestamp = strftime("%Y-%m-%d", localtime);
my $datestamp  = strftime("%Y%m%d%H%M", localtime);

##################################################################################
sub remove_bib_export_files
{
	opendir DIR, "$EXPORT_DIR" or die "Could not open directory $EXPORT_DIR: $!";
	#system('find $EXPORT_DIR -type d -mtime +days -exec rm -rf {} \;');
	while ($directory = readdir DIR)
	{
		#next if -d "$EXPORT_DIR/$file_prefix";
		next if ($directory =~ m/^\./);
		my $mtime = (stat "$EXPORT_DIR$directory")[9];
		if ($TODAY - $wktime > $mtime)
		{
			$filecount++;
			print LOGFILE "$datestamp - Removing $EXPORT_DIR$directory as older than $days days\n";
			rmtree("$EXPORT_DIR$directory");
		}
	}
	close DIR;
}
##################################################################################
sub remove_patron_import_files
{
	opendir DIR, "$IMPORT_DIR" or die "Could not open directory $IMPORT_DIR: $!";
	while ($xml_prefix = readdir DIR)
	{
		next if -d "$IMPORT_DIR/$xml_prefix";
		my $mtime = (stat "$IMPORT_DIR/$xml_prefix")[9];
		if ($TODAY - $wktime > $mtime)
		{
			$filecount++;
			print LOGFILE "$datestamp - Removing $IMPORT_DIR/$xml_prefix as older than $days days\n";
			unlink "$IMPORT_DIR/$xml_prefix";
		}
	}
	close DIR;
}
####################################################################################
sub remove_log_files
{
	opendir DIR, "$LOGS_DIR" or die "Could not open directory $LOGS_DIR: $!";
	while ($file_prefix = readdir DIR)
	{
		next if -d "$LOGS_DIR/$file_prefix";
		my $mtime = (stat "$LOGS_DIR/$file_prefix")[9];
		if ($TODAY - $wktime > $mtime)
		{
			$filecount++;
			print LOGFILE "$datestamp - Removing $LOGS_DIR$file_prefix as older than $days days\n";
			unlink "$LOGS_DIR/$file_prefix";
		}
	}
	close DIR;
}
##################################################################################
# Main program start

if (!$ARGV[0])
	{die "You must supply number of days to the program\n";}

$days = "$ARGV[0]";

$wktime = ($days*86400);
open LOGFILE, ">>$LOGFILE" or die "Cannot open $program_id log: $!";
print LOGFILE "$datestamp - $program_id Housekeeping started for $EXPORT_DIR\n";
if ($days < 3)
{
	print LOGFILE "$datestamp - $program_id  Housekeeping canceled for $EXPORT_DIR. Number of days must be > 2. Days input = $days\n";
	close LOGFILE;
	exit;
}
remove_bib_export_files;
remove_patron_import_files;
remove_log_files;
print LOGFILE "$datestamp - Housekeeping ended for $EXPORT_DIR with $filecount files removed\n";
close LOGFILE;
