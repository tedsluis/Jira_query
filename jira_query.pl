#!/bin/perl
# Query Jira using REST API
use strict;
use warnings;
use Getopt::Long;
use JSON;
use Data::Dumper;

# GetOptions
my $assignee;
my $created;
my $creator;
my $description;
my $help;
my $labels;
my $project="foobar";
my $reporter;
my $resolutiondate;
my $status;
my $subtasks;
my $summary;
my $updated;
# Jira Credentieels
my $username="foo";
my $password="bar"

GetOptions(
        "help!"             => \$help,
        "assignee=s"        => \$assignee,
        "created=s"         => \$created,
        "creator=s"         => \$creator,
        "description=s"     => \$description,
        "labels=s"          => \$labels,
        "project=s"         => \$project,
        "reporter=s"        => \$reporter,
        "resolutiondate=s"  => \$resolutiondate,
        "status=s"          => \$status,
        "subtasks=s"        => \$subtasks,
        "summary=s"         => \$summary,
        "updated=s"         => \$updated,
) or exit(1);

my @query;
push(@query,"assignee = $assignee")             if ($assignee);
push(@query,"created = $created")               if ($created);
push(@query,"creator = $creator")               if ($creator);
push(@query,"description = $description")       if ($description);
push(@query,"labels = $labels")                 if ($labels);
push(@query,"project = $project")               if ($project);
push(@query,"reporter = $reporter")             if ($reporter);
push(@query,"resolutiondate = $resolutiondate") if ($resolutiondate);
push(@query,"status = $status")                 if ($status);
push(@query,"subtasks = $subtasks")             if ($subtasks);
push(@query,"summary = $summary")               if ($summary);
push(@query,"updated = $updated")               if ($updated);
my $query = join("&",@query);
print "jql=$query\n";

my @restapicall=`curl -D- -u $username:$password -X POST -H "Content-Type: application/json" --data '{"jql":"$query","startAt":0,"maxResults":2,"fields":["id","key","labels","description","assignee","status","created","updated","project","summery"]}' "http://jira.rabobank.nl/rest/api/2/search"`;

my $json_text;
for my $line (@restapicall) {
        chomp($line);
        next if ($line =~ /^\s*$/);
        if ($line =~ /^HTTP\/1.1\s\d+/) {
                if ($line =~ /200\sOK/) {
                        print "$line\n";
                        next;
                }
                print "Error: ".join("",@restapicall)."\n";
                exit;
        }
        next unless ($line =~ /^{/);
        print $line."\n";
        $json_text=$line;
}

my $json = JSON->new;
my $data = $json->decode($json_text);
print Dumper($data)."\n";

sub PARSE_JSON (@) {
        #
        my $key=shift;
        my $value=shift;
        print "    KEY=$key" if ($key);
        print "    VALUE=$value" if ($value);
        print "\n";
        if ((defined $value)&&($value =~ /^HASH\(0x/i)) {
                my %hash = %$value;
                foreach my $key (keys %hash){
                        my $hashvalue = $hash{$key};
                        print "    hash:$key,$hashvalue\n";
                        PARSE_JSON($value,$hashvalue);
                }
        } elsif ((defined $value)&&($value =~ /^ARRAY\(0x/)) {
                my @array = @$value;
                foreach my $arrayvalue (@array){
                        print "    array:$arrayvalue\n";
                        PARSE_JSON($value,$arrayvalue);
                }
        } elsif (defined $value) {
                print "  -->\n";
                PARSE_JSON($value);
        } else {
                print "  <--";
        }
}

foreach my $key (keys %{ $data }) {
        my $value=${ $data }{ $key };
        print "key=$key,value=$value\n";
        PARSE_JSON($key,$value);
}
