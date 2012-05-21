#!/usr/bin/perl

# merger.pl input1.bib input2.bib output.bib 

#---- forward declaration ----#
sub AssembleDict;
use Data::Dumper;
use Term::ANSIColor;
our $anoycount=0;

#---- global setting ----#
open(OLDERR, ">&STDERR");
open(OLDOUT, ">&STDOUT");
$dupcheck = 0;	# duplication is NOT checked by default
$| = 1;   # enforce flushing

#---- read input files ----#
if (scalar @ARGV < 3)
{
	print "ERROR: insufficient arguments\n"; 
	print "USAGE: merger.pl input1.bib input2.bib output.bib\n";
	exit;
}

open FH, $ARGV[0];
@input1 = <FH>;
close FH;

open FH, $ARGV[1];
@input2 = <FH>;
close FH;

#---- parse input1 and input2 into dictionaries ----#
%dict1=();
%dict2=();
AssembleDict(\@input1, \%dict1, $ARGV[0]);
AssembleDict(\@input2, \%dict2, $ARGV[1]);

#---- try to add items in dict2 into dict1 ----#
print "\n";
while ( ($k, $v) = each %dict2) 
{
#	print "$k => \n$v\n";

	if (exists $dict1{$k})
	{
		print color 'bold yellow';
		print "1: In host file ".$ARGV[0].":"; 
		print $dict1{$k};
		print color 'reset';
		print ">----------------------------------<\n\n";
		print color 'bold green';
		print "2: In file ".$ARGV[1].":"; 
		print $v;
		print color 'reset';
		print "collision detected!! select one to keep[1/2]: ";
	
		$userinput =  <STDIN>;
		while ($userinput != 1 && $userinput != 2)
		{
			print "either 1 or 2, trying again: ";
			$userinput =  <STDIN>;
		}

		if ($userinput==2)
		{
			delete $dict1{$k};
			$dict1{$k} = $v;
			print "\npayload in";
			print color 'bold red';
			print " 2 ";
			print color 'reset';
			print "is loaded\n\n";
		}
		else
		{
			print "\npayload in";
			print color 'bold red';
			print " 1 ";
			print color 'reset';
			print "is loaded\n\n";
		}
	}
	else
	{
		$dict1{$k} = $v;
	}
}


#while ( ($k, $v) = each %dict1) 
#{
#	print "$k => \n$v\n";
#}


#---- output result ----#
open FH, ">$ARGV[2]" or die $!;

$outp = "";
foreach $k (sort (keys %dict1)) 
{
	$outp = $outp.$dict1{$k};
}

print FH $outp;

close FH;

print "Result has been written to $ARGV[2]\n";


sub AssembleDict
{

	$arg = $_[0];
	my $filelines = join "", @{$arg};
	$dict = $_[1];
	$filename = $_[2];

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
			$title = lc $1;
		}
		else
		{
			$title = '0NO_TITLE'.$anoycount;
			$anoycount++;
		}

		if (exists $dict->{$title})
		{
			print "In file $filename\n\n"; 
			print color 'bold yellow';
			print "version 1: \n\n"; 
			print $dict->{$title};
			print color 'reset';
			print ">----------------------------------<\n\n";
			print color 'bold green';
			print "version 2: \n\n"; 
			print $item;
			print color 'reset';
			print "collision detected!! select one to keep[1/2]: ";

			$userinput =  <STDIN>;
			while ($userinput != 1 && $userinput != 2)
			{
				print "either 1 or 2, trying again: ";
				$userinput =  <STDIN>;
			}

			if ($userinput==2)
			{
				delete $dict->{$title};
				$dict->{$title} = $item;
				print "\npayload in";
				print color 'bold red';
				print " 2 ";
				print color 'reset';
				print "is loaded\n\n";
			}
			else
			{
				print "\npayload in";
				print color 'bold red';
				print " 1 ";
				print color 'reset';
				print "is loaded\n\n";
			}
		}
		else
		{
			$dict->{$title} = $item;
		}
	}
}


