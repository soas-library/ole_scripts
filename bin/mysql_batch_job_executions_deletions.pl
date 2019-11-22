#!/usr/bin/perl -T
# @name: mysql_batch_job_executions_deletions.pl
# @version: 0.1
# @creation_date: 2019-11-22
# @license: GNU General Public License version 3 (GPLv3) <https://www.gnu.org/licenses/gpl-3.0.en.html>
# @author: Simon Bowie <sb174@soas.ac.uk>
#
# @purpose:
# This script deletes batch job executions from the OLE database

use strict;
use warnings;
use DBI;
use File::Basename;

my $data_source = q/DBI:mysql:ole/;
my $user = 'xxxxxxxxxxxx';
my $password = 'xxxxxxxxxxxx';
my $SQLFile = '/home/ole_B2017/sql/delete_batch_job_executions.sql';

# Connect to the data source and get a handle for that connection.
my $dbh = DBI->connect($data_source, $user, $password)
    or die "Can't connect to $data_source: $DBI::errstr";

# Obtain the SQL Statement
open(INPUT, "<" . $SQLFile) or die "Can't open $SQLFile for reading: $!"; 
my $SQLString;
{ local $/ = undef;     # Read entire file at once
$SQLString = <INPUT>;      # Return file as one single `line'
}                       # $/ regains its old value	
close(INPUT);

# Prepare the SQL statement.
my $sth = $dbh->prepare($SQLString)
    or die "Can't prepare statement: $DBI::errstr";

# Execute the statement.
$sth->execute();
$sth->finish();

# Disconnect the database from the database handle.
$dbh->disconnect;
