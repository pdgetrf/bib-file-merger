#!/usr/bin/perl

$| = 1;   # enforce flushing

#
# Generate header files for clapack
# Author: Peng Du (du@cs.utk.edu)
# Innovative Computing Laboratory, University of Tennessee, Knoxivlle
# June 02, 2009
#

use Cwd;

#---- get lapack directory ----#
$topdir = $ARGV[0];

$targetdir[0] = $topdir."/BLAS/SRC";
$targetdir[1] = $topdir."/SRC";
$targetdir[2] = $topdir."/INSTALL";


#---- create header file ----#
open FFH, ">clapack.h";

print FFH "\n\n/* header file for clapack 3.2 */\n\n#ifndef __CLAPACK_H\n#define __CLAPACK_H\n\n";
#print FFH "#include \"f2c.h\"\n\n";


#---- suck in headers ----#
foreach $diri (@targetdir)
{
	print "---------------------- In $diri ------------------------\n";

	@files = ();
	opendir(DIRHANDLE, $diri) or die "!! ERROR in opendir $dir";
	@files=sort grep(!/^\.\.?$/, readdir(DIRHANDLE));
	closedir(DIRHANDLE);

	foreach $file (@files) 
	{
		#--- get the file content ---#
		if ($file =~ /(.*?)\.c/)
		{

			$filename = $1;
			print "processing $file............";
			@filecont = ();
			open FH, "$diri/$file";
			@filecont = <FH>;
			close FH;

			for ($i = 0; $i < (scalar @filecont); $i++)
			{
				$filecont[$i] =~ s/\n//g;
			}
			$safari = join("_2007lenscrub_", @filecont);

			if ($safari =~ /_2007lenscrub_(\/\* Subroutine \*\/.*?)\{/)
			{
				$result = $1;
				$result =~ s/_2007lenscrub_/\n/g;
				$result =~ s/\)/\);/g;

				print FFH "$result\n";
				print "checked\n"
			}
			elsif ($safari =~ /_2007lenscrub_((\/\* Character \*\/)?(\/\* Complex \*\/)?(\/\* Double Complex \*\/)?\s*(logic|doublereal|real|integer|VOID)\s*.*?_\s*\(.*?\)\s*_2007lenscrub_)\s*\{/)
			{
				$result = $1;
				$result =~ s/_2007lenscrub_/\n/g;
				$result =~ s/\)/\);/g;

				print FFH "$result\n";
				print "checked\n"
			}
			else
			{
				print "nop\n"
			}
		}
		else
		{
			print "$file skipped\n";
		}
	}
}

print FFH "\n\n#endif /* __CLAPACK_H */\n";
close FFH;


