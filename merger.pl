#!/usr/bin/perl

# merger.pl input1.bib input2.bib output.bib -dupcheck 0/1

#---- forward declaration ----#
sub RemoveDuplicates;
sub AssembleDict;
use Data::Dumper;
our $anoycount=0;
 

#---- global setting ----#
open(OLDERR, ">&STDERR");
open(OLDOUT, ">&STDOUT");
$dupcheck = 0;	# duplication is NOT checked by default
$| = 1;   # enforce flushing

#---- read input files ----#
if (scalar @ARGV < 2)
{
	print "ERROR: insufficient arguments\n"; 
	print "USAGE: merger.pl input1.bib input2.bib output.bib -dupcheck 0/1\n";
	exit;
}

open FH, $ARGV[0];
@input1 = <FH>;
close FH;

open FH, $ARGV[1];
@input2 = <FH>;
close FH;

#---- remove duplicates if asked ----#


#---- parse input1 and input2 into dictionaries ----#
%dict1=();
%dict2=();
AssembleDict(\@input1, \%dict1);
AssembleDict(\@input2, \%dict2);

while ( ($k, $v) = each %dict1) 
{
	print "$k => \n$v\n";
}

print "----------------------------------\n";

while ( ($k, $v) = each %dict2) 
{
	print "$k => \n$v\n";
}

#---- subroutines ----#
sub RemoveDuplicates
{
# NOT IMPLEMENTED YET
}

sub AssembleDict
{

	$arg = $_[0];
	my $filelines = join "", @{$arg};
	$dict = $_[1];

	$filelines =~ s/\r//g;


	my @items = split(/@/, $filelines);

	@items = grep { $_ !~ /^$/ } @items;

	my $size = scalar @items;
	for ($i=0; $i<$size; $i++)
	{
		$items[$i] = '@'.$items[$i];
	}

	$i=0;
	foreach $item (@items)
	{
		if ($item =~ /title\s*?=\s*?{{1,2}(.+?)}{1,2}/)
		{
			$title = uc $1;
		}
		else
		{
			$title = 'NO_TITLE'.$anoycount;
			$anoycount++;
		}

		$dict->{$title} = $item;
	}

}


