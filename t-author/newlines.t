use strict;
use warnings;

BEGIN {

	use Test::More;
	use File::Find;
}


=head1 NAME

t/newlines.t - test to make sure all text files are in unix linefeed format

=head1 DESCRIPTION

Descends through the distribution directory and verifies that all text files 
(files with an extention matching a pattern, such as *.txt) are in unix
linefeed format.

=head1 TESTS

This module defines the following tests.

=head2 Descend Distribution

Starting at the Distribution root, look at all files in all subdirections and
if the file matches a text type (according to a particular regex for it's
extension) add it to a files of files to test.

=cut

my @files;

	find({
		wanted => \&process, 
		follow => 0 
	}, '.');
    
sub process
{
	my $file = $_;
	
	return if $File::Find::dir =~m/\.svn/;
	return if $File::Find::dir =~m/archive/;
	
	push @files, $File::Find::name
	 if $file =~m/\.yml$|\.pm$|\.pod$|\.tt$|\.txt$|\.js$|\.css$|\.sql$|\.html$/;
}


=head2 Test Linefeedtype

Check if the generated files are correctly unix linefeeds

=cut

my $CR   = "\015";      # Apple II family, Mac OS thru version 9
my $CRLF = "\015\012";  # CP/M, MP/M, DOS, Microsoft Windows
my $FF   = "\014";      # printer form feed
my $LF   = "\012";      # Unix, Linux, Xenix, Mac OS X, BeOS, Amiga

my $test_builder = Test::More->builder;

if( $#files )
{
	$test_builder->plan(tests => ($#files+1)*2);

	foreach my $file (@files)
	{
		## Get a good filehandle
		open( my $fh, '<', $file)
		 or fail "Can't open $file, can't finish testing";
		 
		## Only need to test the first line.
		my ($first, $second) = <$fh>; 
		
		## Don't need this anymore
		close($fh);
		
		SKIP: {
			
			skip "$file is Empty!", 2 unless $first;
	
			## Are we DOS or MACOS/APPLE?
			ok $first!~m/$CRLF$|$CR$|$FF$/, "$file isn't in a forbidden format";
			
			## If there is more than one line, we HAVE to be UNIX
			
			SKIP: {
			
				skip "$file only has a single line", 1 unless $second;
				ok $first=~m/$LF$/, "$file Is unix linefeed";
			}
		}
	}
}
else
{
	$test_builder->plan(skip_all => 'No Text Files Found! (This is probably BIG Trouble...');
}

=head1 AUTHOR

John Napiorkowski, C<< <jjn1056 at yahoo.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 John Napiorkowski.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


1;