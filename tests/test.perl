#!/home/ben/software/install/bin/perl -w

# Copyright (C) 1998,2003  Ben K. Bullock
 
# Cfunctions is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
 
# Cfunctions is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
 
# You should have received a copy of the GNU General Public License
# along with Cfunctions; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 
# This (test.perl.in) is an input file for the script `configure' in
# the top level directory.

# The output is a test script for Cfunctions written in Perl.
 
$cfunctions = "../src/cfunctions";

# Make sure that the executable Cfunctions does exist.

if ( ! -e $cfunctions || ! -x $cfunctions )
{
    print STDERR 
        "$0: `$cfunctions' cannot be found or is not executable.\n";
    exit ( 1 );
}

$cc         = "gcc";
$GNU_c      = "yes"; # are we using GNU C?

$n_test = 0;
$n_failed = 0;
$n_succeed = 0;
$n_bad_tests = 0;

sub err_test ()
{
    my $c_file = $_[0];
    my $message_type = $_[1];
    my $failed = 0;
    my $options = "";

    $n_test++;
    $test = "FAILED";

# Get the error message from the C file.  Every `bad-' and `warn-'
# file should have exactly one error message in it, which is a
# substring of the error message it is supposed to trigger in
# Cfunctions.  This is marked by `$message_type'.

    open ( C_FILE, $c_file ) || die;

    $msg = "";

    while ( <C_FILE> )
    {
        if ( /\/\/\s*options:\s*(.*)/ )
        {
            $options = $1;
        }
        if ( /\/\/\s*$message_type:\s*(.*)/ )
        {
            if ( $msg )
            {
                print "bad test: too many `$message_type' statements.\n";
                close C_FILE;
                $n_bad_tests++;
                $failed = 1;
                next;
            }
            $msg = $1;
        }
    }

    print "Test $n_test: cfunctions $options $c_file: "; 

    if ( ! $msg )
    { 
        $n_bad_tests++;
        $failed = 1;
        print "bad test: no `$message_type' statements.\n"; 
    }

    close C_FILE;

    if ( $failed ) 
    { 
        return;
    }

# Try running Cfunctions on the C file and see if it generates an
# error message containing the right substrings.

    open ( TEST_OUT, "$cfunctions $options $c_file 2>&1 |" );

    while ( <TEST_OUT> )
    {
        if ( /$message_type/ && /$msg/ )
        {
            $test = "PASSED";
        }
    }
    close TEST_OUT;
    if ( $test =~ /FAILED/ )
    {
        $n_failed++;
        print "FAILED\n";
        print "Cfunctions failed to produce $message_type ";
        print "containing\n`$msg'\n";
        print "while processing `$c_file'.\n";
    }
    else
    {
        $n_succeed++;
        print "PASSED\n";
    }
    return;
}

# Remove header files, backup header files and other generated files
# from the current directory.

sub rm_h_files()
{
    opendir(THISDIR, ".");

    @h_files = grep ( /^.*\.h~*$/, readdir THISDIR);

    foreach $h_file (@h_files)
    {
        unlink ( $h_file );
    }
    unlink ( "CFTAGS" );
    closedir THISDIR;
}

# Run Cfunctions on the PASSED files.  If Cfunctions gives an error
# message, then fail the test.

sub try_ok ()
{
    my $c_file = $_[0];
    my $failed = 0;
    my $options = "";
    my $error_msg = "";
    $n_test++;
    $test = "PASSED";

# Get the options from the C file, if there are any.

    open ( C_FILE, $c_file ) || die;

    while ( <C_FILE> )
    {
        if ( /\/\/\s*options:\s*(.*)/ )
        {
            $options = $1;
        }
    }

    close C_FILE;

    print "Test $n_test: cfunctions $options $c_file: "; 

# Try running Cfunctions on the C file and see if it generates an
# error message containing the right substrings.

    open ( TEST_OUT, "$cfunctions --individual $options $c_file 2>&1 |" );

    while ( <TEST_OUT> )
    {
        if ( /error/ || /warning/ || /illegal option/ )
        {
            $error_msg .= $_;
            $test = "FAILED";
        }
    }
    close TEST_OUT;
    if ( $test =~ /FAILED/ )
    {
        $n_failed++;
        print "FAILED\n";
        print "Cfunctions produced error or warning message\n";
        print "$error_msg";
        print "while processing `$c_file'.\n";
    }
    else
    {
        $n_succeed++;
        print "PASSED\n";
    }

# Now for the real test: try to compile and link without warnings
# using the generated header file.

    $test = "PASSED";
    $n_test++;

    my $link_file = $c_file;
    $link_file =~ s/^ok-/link-/;
    my $cc_op = "";
    if ( ! $GNU_c )
    {
        $gcc_op = "";
    }
    else
    {
        $gcc_op = "-Wall ";
    }
    open ( LINK_FILE, $link_file ) || die "no link file for $c_file";

    while ( <LINK_FILE> )
    {
        if ( /\/\/\s*options:\s*(.*)/ )
        {
            $cc_op .= $1;
        }
        if ( $GNU_c )
        {
            if ( /\/\/\s*gcc_opt:\s*(.*)/ )
            {
                $gcc_op .= $1;
            }
        }
    }

    close LINK_FILE;

    print "Test $n_test: $cc $cc_op $gcc_op $c_file $link_file: "; 

# The following `2>&1' directs `stderr' to Perl and `stdout' to
# `/dev/null' (according to the Bash manual).

    $error_msg = "";

    open ( CC_OUTPUT, 
           "$cc $cc_op $gcc_op $c_file $link_file 2>&1 >/dev/null |" );

    while ( <CC_OUTPUT> )
    {
        if ( /.+/ )
        {
            $error_msg .= $_;
            $test = "FAILED";
        }
    }

    close CC_OUTPUT;

    if ( $test =~ /FAILED/ )
    {
        $n_failed++;
        print "FAILED\n";
        print "C compiler produced error or warning messages:\n";
        print "$error_msg\n";
    }
    else
    {
        $n_succeed++;
        print "PASSED\n";
    }

    return;
}

# See if Cfunctions is making backups properly.

sub backup_test ()
{
}

# Test the advertising stuff in Cfunctions

sub advert_test ()
{
    open (C_FILE, "> jub.c");
    print C_FILE "int x;\n";
    close (C_FILE);

    $n_test++;
    $test = "PASSED";

    print ( "test $n_test: cfunctions -aoff: " );

    open (JUB, "$cfunctions -w moo -aoff jub.c |");
    while (<JUB>)
    {
        if ( /Cfunctions/ && /generated header file/ )
        {
            $test = "FAILED";
        }
    }
    close JUB;

    if ( $test =~ /FAILED/ )
    {
        $n_failed++;
        print "FAILED\nAdvert didn't turn off as expected.\n";
    }
    else
    {
        $n_succeed++;
        print "PASSED\n";
    }

    $n_test++;
    $test = "FAILED";

    print ( "test $n_test: cfunctions --advert XXX: " );

    open (XXX, "> XXX");
    print XXX "Crispy crunchies are the best,\n";
    print XXX "They look great upon your vest.\n";
    print XXX "Serve them to unwanted guests,\n";
    print XXX "Stuff your mattress with the rest.\n";
    close XXX;

    open (JUB, "$cfunctions -w moo --advert XXX jub.c |");
    while (<JUB>)
    {
        if ( /Crispy crunchies/ )
        {
            $test = "PASSED";
        }
    }
    close JUB;

    if ( $test =~ /FAILED/ )
    {
        $n_failed++;
        print "FAILED\nAdvert was not included.\n";
    }
    else
    {
        $n_succeed++;
        print "PASSED\n";
    }
    unlink ( "jub.c" );
    unlink ( "XXX" );
}

sub local_global_test()
{
    my $error_msg = "";
    $n_test++;
    $test = "PASSED";

    print ( "test $n_test: cfunctions -l mop -g top: " );

    opendir(THISDIR, ".");
    @ok_files = grep ( /^ok-.*\.c$/, readdir THISDIR);
    closedir THISDIR;

    open (JUB, "$cfunctions -l mop -g top @ok_files 2>&1 |");
    while (<JUB>)
    {
        if ( /error/ || /warning/ )
        {
            $error_msg .= $_;
            $test = "FAILED";
        }
    }
    close JUB;

    if ( $test =~ /FAILED/ )
    {
        $n_failed++;
        print "FAILED\nError or warning message:\n";
        print $error_msg;
    }
    else
    {
        $n_succeed++;
        print "PASSED\n";
    }
}

# Exercise miscellaneous options.  These tests are not very adequate.

sub options_test()
{
    @options = ( '--help', '-h', '--version', '-V'); 

    my $error_msg;

    foreach $option (@options)
    {
        $n_test++;
        $test = "PASSED";
        $error_msg = "";

        print ( "test $n_test: cfunctions $option: " );
        
        open (JUB, "$cfunctions $option 2>&1 |") 
            || die $!;
        
        while (<JUB>)
        {
            if ( /unrecognized option/ )
            {
                $test = "FAILED";
            }
        }
        close JUB;

        if ( $test =~ /FAILED/ )
        {
            $n_failed++;
            print "FAILED\noption not recognised.\n";
        }
        else
        {
            $n_succeed++;
            print "PASSED\n";
        }
    }
    $n_test++;
    $test = "FAILED";
    $error_msg = "";
    my $bad_option = '--heebygeeby';

    print ( "test $n_test: cfunctions $bad_option: " );
        
    open (JUB, "$cfunctions $bad_option 2>&1 |") 
        || die $!;
        
    while (<JUB>)
    {
        if ( /unrecognized option/ )
        {
            $test = "PASSED";
        }
    }
    close JUB;

    if ( $test =~ /FAILED/ )
    {
        $n_failed++;
        print "FAILED\noption `$bad_option' recognised.\n";
    }
    else
    {
        $n_succeed++;
        print "PASSED\n";
    }
}

sub tags_test ()
{
    opendir(THISDIR, ".");

    @ok_files = grep ( /^ok-.*\.c$/, readdir THISDIR);
    @tags = ();

    foreach $ok_file (@ok_files)
    {
        $has_tags = 0;
        unlink ("TAGS");

        open ( PASSED_FILE, $ok_file ) || die $!;

        while ( <PASSED_FILE> )
        {
            if ( /\/\/\s*tags:\s*(.*)/ )
            {
                @tags = split (' ', $1);
                $has_tags = 1;
            }
        }

        # Ignore any files which don't have tags lists in them.

        if ( ! $has_tags )
        {
            next;
        }

        $n_test++;
        $test = "PASSED";
        
        print ( "test $n_test: cfunctions --tags $ok_file: " );
        
        open (JUB, "$cfunctions --tags $ok_file 2>&1 > /dev/null |") 
            || die $!;
        
        while (<JUB>)
        {
            if ( /error/ || /warning/ )
            {
                $error_msg .= $_;
                $test = "FAILED";
            }
        }
        close JUB;

        if ( $test =~ /FAILED/ )
        {
            $n_failed++;
            print "FAILED\nerrors or warnings while making TAGS:\n";
            print $error_msg;
            next;
        }


        $saw_file = 0;
        $unrecorded_tags = "";
        foreach $tag ( @tags )
        {
            $saw_tag{$tag} = 1;
        }

        if ( ! open ( TAGS, "CFTAGS"))
        {
            $n_failed++;
            print "FAILED\nfile `TAGS' was not created\n";
            next;
        }

        while ( <TAGS> )
        {
            $saw_file = 1 if ( /$ok_file/ );
            if ( m/([0-9]+):([a-zA-Z_]+),([0-9]+)/ )
            {
                if ( ! $saw_tag{$2} )
                {
                    $unrecorded_tags .= " " if ( $unrecorded_tags );
                    $unrecorded_tags .= $2;
                }
                $saw_tag{$2} = 2;
            }
        }

        close (TAGS);

        if ( $unrecorded_tags )
        {
            $n_failed++;
            print "FAILED\nunrecorded tags `$unrecorded_tags'.\n";
            next;
        }

        $missed_tags = "";

        foreach $tag ( @tags )
        {
            if ( $saw_tag{$tag} == 1)
            {
                $missed_tags .= " " if ( $missed_tags );
                $missed_tags .= $tag;
            }
        }

        if ( $missed_tags )
        {
            $n_failed++;
            print "FAILED\nmissed tags `$missed_tags'.\n";
            next;
        }

        # This is not good enough: we need to actually check the
        # generated tags against the list in the file.
        $n_succeed++;
        print "PASSED\n";
    }
}

# Test running Cfunctions from standard input.

sub stdin_test ()
{
    $n_test++;
    $test = "FAILED";
    
    open (X_FILE, "> x-file") || die $!;
    print X_FILE "int x;\nint mulder;\nint scully;\n";
    close X_FILE;

    print ( "test $n_test: cfunctions --individual < x-file: " );
        
    open (JUB, "$cfunctions < x-file 2>&1 > /dev/null |") 
        || die $!;
    while (<JUB>)
    {
        ;
    }
    close JUB;

    open (JUB, "$cfunctions --individual < x-file 2>&1 > /dev/null |") 
        || die $!;
    while (<JUB>)
    {
        if ( /bad option -i/ )
        {
            $error_msg .= $_;
            $test = "PASSED";
        }
    }
    close JUB;
    unlink ( "x-file" );

    if ( $test =~ /FAILED/ )
    {
        $n_failed++;
        print "FAILED\nShould have produced an error message.\n";
        print $error_msg;
    }
    else
    {
        $n_succeed++;
        print "PASSED\n";
    }
}

# Main program starts here

& rm_h_files();

opendir(THISDIR, ".");

@bad_files = grep ( /^bad-.*\.c$/, readdir THISDIR);

closedir THISDIR;

foreach $bad_file (@bad_files)
{
    &err_test ( $bad_file, "error" );
}

# Try running Cfunctions on each `warn-' file and see if it generates
# a warning message.

opendir(THISDIR, ".");

@warn_files = grep ( /^warn-.*\.c$/, readdir THISDIR);

foreach $warn_file (@warn_files)
{
    &err_test ( $warn_file, "warning" );
}

opendir(THISDIR, ".");

@ok_files = grep ( /^ok-.*\.c$/, readdir THISDIR);

foreach $ok_file (@ok_files)
{
    &try_ok ( $ok_file );
}

& backup_test();

& advert_test();

& local_global_test();

& options_test();

& tags_test();

& stdin_test();

# Now print a report on the tests.

if ( $n_test != $n_failed + $n_succeed + $n_bad_tests )
{
    die "internal counting error";
}

$n_test -= $n_bad_tests;

print "\nTotal tests = $n_test, success rate = $n_succeed / $n_test\n";

if ( $n_failed )
{
    print "WARNING: $n_bad_tests of the tests didn't work.\n";
}
else
{
    print "Cfunctions is functioning normally.\n";
}

# This message has become annoying.

# if ( $n_succeed == $n_test )
# {
#     print "We see Cfunctions functions and sees C functions.\n";
# }
# else
# {
#     print "We do not see Cfunctions function or see C functions.\n";
# }

# The generated `.h' files are deleted.

& rm_h_files();

unlink ( "a.out" ) || die;

# Need to make the coverage file here.

exit
