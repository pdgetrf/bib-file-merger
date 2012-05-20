#!/usr/bin/perl
#
# Conversion of LAPACK to C using f2c and test 
# Peng Du du@cs.utk.edu
# Jan 14th, 2009
# Removed support for TIMING

use Cwd;

sub trim($);

#---- setup for output redirect ----#
open(OLDERR, ">&STDERR");
open(OLDOUT, ">&STDOUT");

#---- get locations ----#
open FH, "configure.in";
@lpk = <FH>;
close FH;

@srcdir = ();
$i = -1;
$if_test_blas = 0;

print "\nInitialiing...";

#rename_blas = 1;

foreach $line (@lpk)
{
     if ($line =~ /^$/ or $line !~ /(\w)+/ or $line =~ /^#/)	{	next;	}	# skip empty line(s)

     $line =~ s/\n//g;
     if ($line =~ /LAPACKDIR(\s*)=(\s*)([\w\W]+)/)
     {
          $lapackdir = trim ($3);
     }
     if ($line =~ /RENAME_BLAS(\s*)=(\s*)([\w\W]+)/)
     {
		 if ($3 =~ /yes/i)
		 {	 $rename_blas = 1;	 }
		 else
		 {	 $rename_blas = 0;	 }	
     }
     elsif ($line =~ /C_COMPILER(\s*)=(\s*)([\w\W]+)/)
     {
          $c_compiler = trim ($3);
		  $c_compiler =~ s/\//\\\//g;
     }
     elsif ($line =~ /LENSCRUB(\s*)=(\s*)([\w\W]+)/)
     {
          $lenscrubdir = trim ($3);
     }
     elsif ($line =~ /C_LINK_OPT(\s*)=(\s*)([\w\W]+)/)
     {
          $c_link_opt = trim ($3);
     }
     elsif ($line =~ /F2CEXEDIR(\s*)=(\s*)([\w\W]+)/)
     {
          $f2cexedir = trim ($3);
     }
     elsif ($line =~ /F2CLIB(\s*)=(\s*)([\w\W]+)/)
     {
          $f2clib = trim ($3);
     }
     elsif ($line =~ /TODO(\s*)=(\s*)([\w\W]+)/)
     {
          $todo = trim ($3);
     }	
     elsif ($line =~ /TESTINGDIR(\s*)=(\s*)([\w\W]+)/)
     {
          $tmp = $3;
          $tmp =~ s/\$\(LAPACKDIR\)/$lapackdir/g;

          $testsrcdir = trim ($tmp);
          $tmp =~ s/$lapackdir/$outputdir/g;
          $testdsndir = $tmp;
     }
     elsif ($line =~ /OUTPUTDIR(\s*)=(\s*)([\w\W]+)/)
     {
          $tmp = $3;
          $tmp =~ s/\\//g;
          $tmp =~ s/\$\(LAPACKDIR\)/$lapackdir/g;
          $outputdir = $tmp;
     }
     elsif ($line =~ /SRC(\s*)=(\s*)([\w\W]+)/)
     {
          $i = 0;
          $tmp = $3;
          $tmp =~ s/\\//g;
          $tmp =~ s/\$\(LAPACKDIR\)/$lapackdir/g;
          $srcdir[$i] = trim ($tmp);
     }
     elsif ($i != -1)
     {
          $i++;
          $line =~ s/\\//g;
          $line =~ s/\$\(LAPACKDIR\)/$lapackdir/g;
          if ($line =~ /(\s*)([\w\W]+)(\s*)/)
          {
               $srcdir[$i] = trim ($2);
          }
     }
}

print "done.\n";

print "\n--------Setup directories for output--------\n";
#---- setup output path ----#
if ((-d $outputdir) == 0) # root output directory not exists
{
     print "mkdir $outputdir\n";
     system (("mkdir", "-p", $outputdir)) == 0 || die "!! ERROR: Cannot mkdir $outputdir: $!";
}

@dsndir = (); $i = 0;
foreach $dir (@srcdir)
{
     $tmp = $dir;
     $tmp =~ s/$lapackdir/$outputdir/g;
     if ((-d $tmp) == 0) # directory not exists
     {
          print "mkdir $tmp\n";
          system (("mkdir", "-p", "$tmp")) == 0 || die "!! ERROR: Cannot mkdir $outputdir: $!";
     }
     $dsndir[$i++] = $tmp;
}

print "\n--------Copy original source files into output directory--------\n";
#---- copy fortran source files to destination ----#
for ($i = 0; $i < scalar @srcdir; $i++)
{
     @files = ();
     opendir(DIRHANDLE, $srcdir[$i]) or die "!! ERROR in opendir $srcdir[$i]";
     @files = sort readdir (DIRHANDLE);
     closedir(DIRHANDLE);

     print "copying fortran sources in $srcdir[$i] to $dsndir[$i] ...";
     foreach $file (@files) 
     {

          $tmp = $srcdir[$i].'/'.$file;
          if ($file !~ /^(\.){1,2}/ and (-d $tmp) == 0)
          {
               system (("cp", "$srcdir[$i]/$file", "$dsndir[$i]/")) == 0 
                    or die "!! ERROR: Unable to duplicate source files: $srcdir[$i]/$file";
          }
     }
     print "done.\n";

     # copy BLAS testing input files 
     if ($srcdir[$i] =~ /(.*BLAS)\/TESTING/)
     {
          $blaststin = $1;
          $tmp = $blaststin;
          $tmp =~ s/$lapackdir/$outputdir/g;
          $blaststout = $tmp;

          @files = ();
          opendir(DIRHANDLE, $blaststin) or die "!! ERROR in opendir $blaststin";
          @files = sort readdir (DIRHANDLE);
          closedir(DIRHANDLE);

          print "copying BLAS testing input files in $blaststin to $blaststout ...";
          foreach $file (@files) 
          {
               $tmp = $blaststin.'/'.$file;
               if ($file !~ /^(\.){1,2}/ and (-d $tmp) == 0) 
               {
                    system (("cp", "$blaststin/$file", "$blaststout/")) == 0 
                         or die "!! ERROR: Unable to duplicate source files: $blaststin/$file";
               }
          }
          print "done.\n";
     }

}

#---- copy make.inc & root Makefile----#
print "copying make.inc in $lapackdir to $outputdir...";
system (("cp", "$lapackdir/make.inc", "$outputdir")) == 0 
or die "!! ERROR: Unable to duplicate source files: $lapackdir/make.inc";
print "copying Makefile in $lapackdir to $outputdir...";
system (("cp", "$lapackdir/Makefile", "$outputdir")) == 0 
or die "!! ERROR: Unable to duplicate source files: $lapackdir/Makefile";
print "done.\n";

print "\n--------Copy original testing files into output directory--------\n";
#---- copy testing suite ----#
@files = ();
opendir(DIRHANDLE, $testsrcdir) or die "!! ERROR in opendir $testsrcdir";
@files = sort readdir (DIRHANDLE);
closedir(DIRHANDLE);
print "copying testing suite in $testsrcdir to $testdsndir ......";
foreach $file (@files) 
{
     $tmp = $testsrcdir."/".$file;
     if (-f $tmp)
     {
          system (("cp", "$testsrcdir/$file", "$testdsndir")) == 0 
               or die "!! ERROR: Unable to duplicate testing files: $testsrcdir/$file"; 
     }
}

print "done.\n";

print "\n--------Convert fortran to C using f2c--------\n";

#---- f2c conversion ----#
if ($todo =~ /f2c|all/)
{
	#---- make a list of the names of blas routines ----#
	$blas_zoo = "";
	foreach $dir (@dsndir)
	{
		opendir(DIRHANDLE, $dir) || die "!! ERROR in opendir $dir";
		@files = sort readdir (DIRHANDLE);
		closedir(DIRHANDLE);

		if ($dir =~ /BLAS/ and $dir !~ /TESTING/)
		{
			foreach $file (@files) 
			{
				if ($file =~ /\.f/)
				{
					$blas_zoo = $blas_zoo.$file." ";
				}
			}
		}
	}

	#---- make a list of the names of lapack routines ----#
	$lapack_zoo = "";
	foreach $dir (@dsndir)
	{
		opendir(DIRHANDLE, $dir) || die "!! ERROR in opendir $dir";
		@files = sort readdir (DIRHANDLE);
		closedir(DIRHANDLE);

		if ($dir !~ /BLAS/ or $dir =~ /TESTING/ or $dir =~ /TIMING/)
		{
			foreach $file (@files) 
			{
				if ($file =~ /\.f/ and $blas_zoo !~ /$file/)
				{
					$lapack_zoo = $lapack_zoo.$file." ";
				}
			}
		}
	}

	#---- do f2c conversion ----#
	foreach $dir (@dsndir)
	{
		opendir(DIRHANDLE, $dir) || die "!! ERROR in opendir $dir";
		@files = sort readdir (DIRHANDLE);
		closedir(DIRHANDLE);

		chdir($dir) || die "!! ERROR in chdir to $dir";
		print "doing f2c conversion in $dir...";

		# converting using f2c
		open(STDOUT, ">>$outputdir/f2c.log");
		open(STDERR, ">&STDOUT") || die "Can't dup stdout";

		$f2cexe = $f2cexedir.'/f2c';

          system (("cp $lapackdir/blaswrap.h $dir")); 

		foreach $file (@files) 
		{
			if ($file !~ /\.f$/) {	print "passing $file in $dir\n"; next;	}

			if ($rename_blas == 0 and $blas_zoo =~ /$file/)
			{
                    @args = ($f2cexe, "-a", "-A", $file);
                    #@args = ($f2cexe, $file);
				print "$f2cexe -a -A $dir".'/'."$file\n";
			}
			else
			{
                    @args = ($f2cexe, "-P", "-a", "-A", $file);
                    #@args = ($f2cexe, "-P", $file);
				print "$f2cexe -P -a -A $dir".'/'."$file\n";
			}
			
			system(@args) == 0 or print "!! ERROR in f2c $file in $dir !!\n";		

			print "deleting $dir/$file\n";
			system(("\\rm $dir/$file"));

               #---- adding 'blaswrap.h' ----#
               $tmp2 = $file;
               $tmp2 =~ s/\.f$/\.c/;
               $tmp2 = "$dir/$tmp2";
               $tmp = q{'s/(\#include \"f2c\.h\")/\1\n\#include \"blaswrap\.h\"/'};
			system (("perl -pi -e $tmp $tmp2"));
               print "perl -pi -e $tmp $tmp2\n";

			#---- renaming -----#
			if ($rename_blas == 0 and $blas_zoo =~ /$file/)
			{	next;	}

			# get .P file name #
			@vic = ();
			$file =~ /(\w+)\.f/;
			$vic[0] = $1;   # the hosting subroutine
			$dpfile = $1.".P";
			$csrc = $1.".c";

			# find reference #
			open FH, $dpfile or print "!! ERROR: Can not open $dpfile\n";
			@ref = <FH>;
			close FH;

			system (("\\rm $dir/$dpfile"));

			$i = 1;
			foreach $line (@ref)
			{
				if ($line =~ /^\/\*:ref: (\w+)_/)
				{
					$vic[$i] = $1;
					$i++;
				}
			}

			# rename #
			open FH, $csrc or print "!! ERROR: Can not open $csrc\n";
			@src = <FH>;
			close FH;

			system (("\\rm $dir/$csrc"));

			open(FH, ">$csrc") or print "!! ERROR: Can not creat $csrc\n";
			foreach $line (@src)
			{
				foreach $key (@vic)
				{
					if ($rename_blas == 0 and ($blas_zoo =~ /$key.f/ or $lapack_zoo !~ /$key.f/))
					{	next;	}

					if ($rename_blas == 1 and $blas_zoo !~ /$key.f/ and $lapack_zoo !~ /$key.f/)
					{	next;	}

                         #$line =~ s/\b($key)_\b/$1_f2c/g;
				}
				print FH $line;
			}

			close FH;
		}

		close (STDOUT);
		close(STDERR);
		open(STDOUT, ">&OLDOUT");
		open(STDERR, ">&OLDERR");


		print "done.\n";

		# setup Makefile
		if ($dir =~ /BLAS\/TESTING/)
		{
			$maketype = 3;
			$if_test_blas = 1;
			$Maketarget = "Makeblat";
		}
		else 
		{
			$maketype = 1;
			$Maketarget = "Makefile";
		}

		for ($i = 1; $i <= $maketype; $i++)
		{
			if ($maketype == 3)
			{    $Maketarget = "Makeblat$i";     }
			else
			{    $Maketarget = "Makefile";     }

			system (("perl -pi -e 's/\.f\.o:/\.c\.o:/g' $Maketarget"));

			# replace $(FORTRAN) $(OPTS) ... to  gcc -I/f2c -c $<
			$tmp = $f2cexedir;
			$tmp =~ s/\//\\\//g;
			$tmp = q{'s/\$\(FORTRAN\).*\$\(OPTS\).*/}."$c_compiler \\\$\\\(OPTS\\\) -I$tmp -c ".'\$<'."/g'"; 
			system (("perl -pi -e $tmp $Maketarget"));

			system ((q{perl -pi -e "s/\.f/\.c/g" }.$Maketarget));
			$tmp = q{'s/\$\(FORTRAN\)/}."$c_compiler/g'";
			system (("perl -pi -e $tmp $Maketarget"));
			$tmp = $f2cexedir;
			$tmp =~ s/\//\\\//g;
			$tmp = q{'s/\$\(DRVOPTS\)/\$\(DRVOPTS\) }."-I$tmp/g'";
			system (("perl -pi -e $tmp $Maketarget"));
			$tmp = $f2cexedir;
			$tmp =~ s/\//\\\//g;
			$tmp = q{'s/\$\(NOOPT\)/\$\(NOOPT\) }."-I$tmp/g'";
			system (("perl -pi -e $tmp $Maketarget"));

			$tmp = q{'s/\$\(LOADER\)/}."$c_compiler/g'";
			system (("perl -pi -e $tmp $Maketarget"));

			if ($dir !~ /INSTALL/)
			{
				$tmp = q{'s/(\$\(LOADOPTS\))(.*)/\1}." $c_link_opt ".q{\2/g'};
			}
			else
			{
				$tmp = $f2clib;
				$tmp =~ s/\//\\\//g;
				$tmp = q{'s/(\$\(LOADOPTS\))(.*)/\1}." $c_link_opt ".q{\2 }."$tmp -lm".q{/g'};
			}
			system (("perl -pi -e $tmp $Maketarget"));

			if ($dir =~ /TESTING/)
			{
				$tmp = $f2clib;
				$tmp =~ s/\//\\\//g;
				$tmp = q{'s/\$\(BLASLIB\)/\$\(BLASLIB\) }."$tmp -lm/g'";
				system (("perl -pi -e $tmp $Maketarget"));

			}
			print "$Maketarget updated in $dir\n";
		}
	}
	print "f2c conversion completed. More details in f2c.log\n";
}

#---- generate library----#
if ($todo =~ /library|all/)
{
     print "\n--------Generate CLAPACK library--------\n";
     print "Now making the library:\n";

     foreach $dir (@dsndir)
     {
          if ($dir =~ /(BLAS)\/SRC/ or $dir =~ /(INSTALL)/ or $dir =~ /(MATGEN)/)
          {
               print "Generating library in $dir...";

               open(STDOUT, ">>$outputdir/$1.log");
               open(STDERR, ">&STDOUT") || die "Can't dup stdout";

               chdir ($dir);
               system (("make"));

               close (STDOUT);
               close(STDERR);
               open(STDOUT, ">&OLDOUT");
               open(STDERR, ">&OLDERR");
               print "done. More details in $1.log.\n";
          }
     }

     print "Generating library in $outputdir/SRC...";

     open(STDOUT, ">>$outputdir/SRC.log");
     open(STDERR, ">&STDOUT") || die "Can't dup stdout";

     chdir ($outputdir."/SRC");
     system (("make"));

     close (STDOUT);
     close(STDERR);
     open(STDOUT, ">&OLDOUT");
     open(STDERR, ">&OLDERR");

     print "done. More details in SRC.log.\n";
}

#---- blas_testing run ----#
if ($if_test_blas == 1 and $todo =~ /blas_testing_run|all/)
{
     print "\n--------Run testing suite of BLAS--------\n";
     print "Running the test using the Makefile in $outputdir......";

     open(STDOUT, ">>$outputdir/blas_testing.log");
     open(STDERR, ">&STDOUT") || die "Can't dup stdout";

     chdir ($outputdir);
     system (("make blas_testing"));

     close (STDOUT);
     close(STDERR);
     open(STDOUT, ">&OLDOUT");
     open(STDERR, ">&OLDERR");

     print "done. More details in blas_testing.log.\n";
}

if ($if_test_blas == 0 and $todo =~ /all/)
{
     print "\nblas_testing skipped because no testing routine provided\n";
}

#---- lapack_testing compile ----#
if ($todo =~ /lapack_testing_compile|all/)
{
     print "\n--------Compile & link testing suite of CLAPACK--------\n";
     foreach $dir (@dsndir)
     {
          if ($dir =~ /(EIG|LIN)/) 
          {
               print "Compiling testing in $dir...";

               open(STDOUT, ">>$outputdir/$1.log");
               open(STDERR, ">&STDOUT") || die "Can't dup stdout";

               chdir ($dir);
               system (("make"));

               close (STDOUT);
               close(STDERR);
               open(STDOUT, ">&OLDOUT");
               open(STDERR, ">&OLDERR");

               print "done. More details in $1.log.\n";
          }

     }
}

#---- lapack_testing run ----#
if ($todo =~ /lapack_testing_run|all/)
{
     print "\n--------Run testing suite of CLAPACK--------\n";
     print "Running the test in $testdsndir......";

     open(STDOUT, ">>$outputdir/lapack_testing.log");
     open(STDERR, ">&STDOUT") || die "Can't dup stdout";

     chdir ($testdsndir);
     system (("make"));

     close (STDOUT);
     close(STDERR);
     open(STDOUT, ">&OLDOUT");
     open(STDERR, ">&OLDERR");

     print "done. More details in lapack_testing.log.\n";
}

#---- group .log files ----#
print "\n--------Group .log files--------\n";
print "Grouping all .log files into $outputdir\/LOG/......";
chdir ($outputdir);
system (("mkdir LOG"));
system (('mv *.log '."$outputdir\/LOG"));
print "done.\n";

print "\n--------End--------\n";



#---- SUBROUTINE ----#
sub trim($)
{
     my $string = shift;
     $string =~ s/^\s+//;
     $string =~ s/\s+$//;
     return $string;
}
