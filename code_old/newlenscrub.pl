#!/usr/bin/perl

$| = 1;   # enforce flushing

# -------------------------------------
# Newlenscrub (Alpha testing version)
# -------------------------------------
# Purpose: Remove unwanted 'ftnlen' and 'rc_len' from clapack translated by f2c. 
#          This is the second phase of generating clapack, following the convert.pl, which does the f2c converting.
# -------------------------------------
# Usage: ./newlenscrub [full lapack path], for example:  
#              ./newlenscrub /home/du/f2cwork/final_test/gcc/result/3.1.1  
# -------------------------------------
# Known issue:
# (1) ilaenv.c and lsamen.c in the SRC make direct access to the ftnlen paramters, so extra conversion is added to support this. 
#     After running newlenscrub, please copy the provided ilaenv.c and lsamen.c into the SRC direcotry.
# (2) Note that this script could take some time to finish, hopefully less than 1 hour, depending on the machine. 
# -------------------------------------
#
# Author: Peng Du (du@cs.utk.edu)
# Innovative Computing Laboratory, University of Tennessee, Knoxivlle
# December 06, 2007


sub unonion;
sub wraponion;
sub trim($);
sub lenscrub;
sub engagetarget;

use Cwd;

#---- get lapack directory ----#
$topdir = $ARGV[0];

$targetdir[0] = $topdir."/BLAS/SRC";
$targetdir[1] = $topdir."/INSTALL";
$targetdir[2] = $topdir."/SRC";
$targetdir[3] = $topdir."/BLAS/TESTING";
$targetdir[4] = $topdir."/TESTING/LIN";
$targetdir[5] = $topdir."/TESTING/EIG";
$targetdir[6] = $topdir."/TESTING/MATGEN";
$targetdir[7] = $topdir."/SRC/VARIANTS/cholesky/RL";
$targetdir[8] = $topdir."/SRC/VARIANTS/cholesky/TOP";
$targetdir[9] = $topdir."/SRC/VARIANTS/lu/CR";
$targetdir[10] = $topdir."/SRC/VARIANTS/lu/LL";
$targetdir[11] = $topdir."/SRC/VARIANTS/lu/REC";
$targetdir[12] = $topdir."/SRC/VARIANTS/qr/LL";

#$targetdir[0] = $topdir."/BLAS/SRC";
#$targetdir[1] = $topdir."/BLAS/TESTING";
#$targetdir[2] = $topdir."/INSTALL";
#$targetdir[3] = $topdir."/SRC";
#$targetdir[4] = $topdir."/TESTING/LIN";
#$targetdir[5] = $topdir."/TESTING/EIG";
#$targetdir[6] = $topdir."/TESTING/MATGEN";

#---- build the name zoo of lapack/blas routines ----#
$name_zoo = "";

foreach $diri (@targetdir)
{
     @files = ();
     opendir(DIRHANDLE, $diri) or die "!! ERROR in opendir $diri";
     @files=grep(!/^\.\.?$/, readdir(DIRHANDLE));
     closedir(DIRHANDLE);

     foreach $file (@files) 
     {
          if ($file =~ /\.c/)
          {
               $name_zoo = $name_zoo.$file."_ ";
          }
     }
}

$name_zoo =~ s/\.c//g;

@name_park = split (/\s/, $name_zoo);

#---- remove redundency from the name_park ----#
for ($i = 0; $i < scalar @name_park; $i++)
{
     for ($j = $i+1; $j < scalar @name_park; $j++)
     {
          if ($name_park[$i] eq $name_park[$j])
          {
               splice (@name_park, $j--, 1);
          }
     }
}

#---- scrub off the ftnlen ----#
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
          if ($file =~ /\.c/)
          {
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

               @pick = engagetarget ($safari, \@name_park);

               $found = 0;
               foreach $i (@pick)
               {
                    $beforereplace = $i;
                    $beforereplace =~ s/(\W)/\\$1/g;

                    if ($safari =~ /$beforereplace/g)
                    {
                         $afterreplace = lenscrub($i, "ftnlen", $name_zoo);

                         #----- In TESTING/EIG, it's called 'rc_len' instead of 'ftnlen' -----#
                         if ($diri =~ /EIG/)
                         {
                              $afterreplace = lenscrub($afterreplace, "rc_len", $name_zoo);
                         }

                         $found += () = $safari =~ s/($beforereplace)/$afterreplace/g;
                    }
               }
               if ($found != scalar @pick)
               {
                    print "warning...$found out of ".scalar @pick."\n";
               }
               else
               {
                    print "ok\n";
               }
               #print "done: removed ".$found." ftnlen out of ".scalar @pick." target.\n";


               @filecont = split (/_2007lenscrub_/, $safari);
               open FH, ">$diri/$file";
               foreach $i (@filecont)
               {
                    print FH $i."\n";
               }
               close FH;
          }
          else
          {
               print "$file skipped\n";
          }
     }
}

#xxxxxxxxxxxxxxxxxxxxxxxxxx SUBROUTINE SECTIONxxxxxxxxxxxxxxxxxxxxxxxxx#

#-------------------------- SUBROUTINE -------------------------#
# engagetarget                                                  #
# Purpose: Find the lapack/blas routine from the input text     #
# Input:                                                        #
#    1. The text to search, namely $safari                      #
#    2. The lapack/blas routine list, namely $name_park         #
# Output:                                                       #
#    An array of the lapack/blas routine occurance in the text  #
#---------------------------------------------------------------#
sub engagetarget 
{
     my $safari = shift;
     my $name_park = shift;
     my (@sen_pieces, $i, $j, $k, @pick, @sentence, $sen, $name, $basenum, $compstr, $cursen, $done, $hit); 

     @sentence = split (/;/, $safari);

     $k = 0;
     @pick = ();
     foreach $sen (@sentence)
     {
          $cursen = $sen;

          while ((length $cursen) > 0)
          {
               $hit = 0;
               foreach $name (@name_park)
               {
                    if ($cursen =~ /($name\()/g)
                    {
                         $hit = 1;
                         $pick[$k] = $1;
                         $basenum = 1;
                         $done = 0;

                         for ($j = pos $cursen; $j < (length $cursen); $j++)
                         {
                              $compstr = substr($cursen, $j, 1);
                              if ($compstr eq '(')
                              {
                                   $basenum++;
                              }
                              elsif ($compstr eq ')')
                              {
                                   $basenum--;
                              }
                              $pick[$k] .= $compstr;

                              if ($basenum == 0)
                              {
                                   $done = 1;
                                   last;
                              }
                         }

                         if ($done == 1)
                         {
                              $cursen = substr($cursen, 0, (pos $cursen)-1).substr($cursen, $j);
                              $k++;
                              last;
                         }
                    }
               }
               if ($hit == 0)
               {
                    last;
               }
          }
     }

     for ($j = 0; $j < scalar @pick; $j++)
     {
          $pick[$j] =~ /(\w+\(.*\))/;
          $pick[$j] = $1;
          #print "$1\n";
     }

     #---- remove redundency from the pick ----#
     for ($i = 0; $i < scalar @pick; $i++)
     {
          for ($j = $i+1; $j < scalar @pick; $j++)
          {
               if ($pick[$i] eq $pick[$j])
               {
                    splice (@pick, $j--, 1);
               }
          }
     }

     return @pick;
}


#-------------------------- SUBROUTINE -------------------------#
# lenscrub                                                      #
# Purpose: Remove keyword from the calling sequece of the input #
#          function                                             #
# Input:                                                        #
#    1. The function call text, namely $function                #
#    2. The keyword to remove, namely $key                      #
#    3. The range in which the function name must fall in so    #
#       that the removal of keyword could proceed, namely $dict #
# Output:                                                       #
#    The processed function text                                #
#---------------------------------------------------------------#
sub lenscrub 
{
     my $function = shift;
     my $key = shift;
     my $dict = shift;

     @pstack = ();

     unonion ($function, $pstack, 0);

     removekey (\@pstack, 0, $key, $dict);

     return wraponion (@pstack);
}

#-------------------------- SUBROUTINE -------------------------#
# removekey                                                     #
# Purpose: Remove keyword from the input Parameter Stack        #
#          Structure                                            # 
# Input:                                                        #
#    1. The Parameter Stack Structure, namely $pstack           #
#    2. The starting offset, namely $start (internal use)       #
#    3. The keyword to remove, namely $key                      # 
#    4. The range in which the function name must fall in so    #
#       that the removal of keyword could proceed, namely $dict #
# Output:                                                       #
#    The processed Parameter Stack Structure                    #
#---------------------------------------------------------------#
sub removekey
{
     my $i;
     my $pstack = shift;
     my $start = shift;
     my $key = shift;
     my $dict = shift;
     my $shrink = 0;
     my $tmp;

     for ($i = $start+2; $i < $start+$pstack->[$start+1];)
     {
          if ($pstack->[$i] == 1)
          {
               if ($pstack->[$i+1] =~ $key and $dict =~ $pstack->[$start])
               {
                    splice (@pstack, $i, 2);
                    $shrink += 2;
                    $pstack->[$start+1] -= 2;
               }
               else
               {
                    $i += 2;
               }
          }
          else
          {
               $shrink += removekey ($pstack, $i+1, $key, $dict);
               $pstack->[$start+1] -= $shrink; 
               $i += $pstack->[$i+2]+1;
          }
     }
     return $shrink;
}

#-------------------------- SUBROUTINE -------------------------#
# wraponion                                                     #
# Purpose: Wrap the input Parameter Stack Structure back into   # 
#          a function call                                      #
# Input:                                                        #
#    1. The Parameter Parameter Structure, namely $pstack       #
# Output:                                                       #
#    The function call form of the input structure              # 
#---------------------------------------------------------------#
sub wraponion
{
     my $i;
     my $output = "";

     $output = $_[0].'(';

     for ($i = 2; $i < $_[1]-2;)
     {

          if ($_[$i] == 1)
          {
               if ($i != 2)
               {
                    $output .= ", ";
               }
               $output .= $_[$i+1];
               $i += 2;
          }
          else
          {
               if ($i != 2)
               {
                    $output .= ", ";
               }
               $output = $output.wraponion(@_[($i+1)..$#_]);
               $i += $_[$i+2]+1;
          }
     }
     return $output.')'.$_[$_[1]-1];
}

#-------------------------- SUBROUTINE -------------------------#
# unonion                                                       #
# Purpose: Break the input function call string into a          #
#          parameter stack structure                            # 
# Input:                                                        #
#    1. The function call string, namely $string                #
#    2. The stacking pointer, namely $spointer (internal use)   # 
# Output:                                                       #
#    The parameter stack structure form of the input fuction    # 
#    call string                                                #
#                                                               #
# Ok, about the Parameter Stack Structure(PSS). It is a         #
# structure to describe the parenting relationship of a         #
# function and its parameters. It is used by removekey, unonion #
# and wraponion.                                                #
#                                                               #
# The structure is recursive, and depicted as follow:           #
# slot 0: Name of the function                                  #
# slot 1: Length of the current call                            #
# slot 2:      1 (The next slot is a string of parameter)       #
#         or                                                    #
#              2 (The next slot starts a nested PSS recursively #
# slot 3: a string parameter or the start of another PSS        #
#   .                                   .                       #
#   .                                   .                       #
#   .                                   .                       #
#---------------------------------------------------------------#
sub unonion
{
     my $string = shift;
     my $stack = shift;
     my $spointer = shift;

     my $basenum = 0;
     my $childnum = 0;
     my $i, $base;
     my $tmpstr;
     my @para;
     my $parai;
     my $func;
     my $ppara;
     my $ending;

     if ($string =~ /(.*?)(\w+)\((.*)\)(.*)/)
     {
          $ending = $4;
          $func = $1.$2;
          @para = split (/,/, $3);

          #--- tighten nested function ---#
          for ($base = 0; $base <= (scalar @para)-1;)
          {
               while ($para[$base] =~ m/\(/g) {     $basenum++;          }
               while ($para[$base] =~ m/\)/g) {     $basenum--;         }

               if ($basenum == 0)  
               {
                    $base++;
                    next;     
               }

               for ($i = $base+1; $i <= (scalar @para)-1; $i++)
               {
                    $childnum = 0;
                    while ($para[$i] =~ m/\(/g) {     $childnum--;          }
                    while ($para[$i] =~ m/\)/g) {     $childnum++;         }

                    if ($basenum >= $childnum and $basenum != 0)
                    {
                         $para[$base] = $para[$base].', '.$para[$i];
                         splice (@para, $i, 1);
                         $i--;
                         $basenum -= $childnum;
                         if ($basenum == 0)
                         {
                              last;
                         }
                    }
               }
               $base = $i + 1;
               $basenum = 0;
          }

          @para[$#para+1] = $ending;

          #---- store parameter into a structure ----#
          $pstack[$spointer] = $func;
          $ppara = $spointer+2;

          foreach $parai (@para)
          {
               if ($parai !~ /\w+\(.*\)/)
               {
                    $pstack[$ppara++] = 1;
                    $pstack[$ppara++] = trim($parai);
               }
               else
               {
                    $pstack[$ppara++] = 2;
                    unonion (trim($parai), \@pstack, $ppara);
               }
               $ppara += $pstack[$ppara+1];
          }
          $pstack[$spointer+1] = $ppara - $spointer;
     }
}


#---- SUBROUTINE ----#
sub trim($)
{
     my $string = shift;
     $string =~ s/^\s+//;
     $string =~ s/\s+$//;
     return $string;
}


