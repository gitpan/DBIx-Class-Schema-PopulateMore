package DBIx::Class::Schema::PopulateMore;

use warnings;
use strict;

use DBIx::Class::Schema::PopulateMore::Command;

=head1 NAME

DBIx::Class::Schema::PopulateMore - An enhanced populate method

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

The following is example usage for this component.

	package Myapp::Schema;
	use base qw/DBIx::Class::Schema/;
	
	__PACKAGE__->load_components(qw/Schema::PopulateMore/);
	__PACKAGE__->load_namespaces();
	
	## All the rest of your setup

Then assuming you have ResultSources of Gender, Person and FriendList:

	my $setup_rows = [
	
		{Gender => {
			fields => 'label',
			data => {
				male => 'male',
				female => 'female',
			}}},
			
		{Person	=> {
			fields => ['name', 'age', 'gender'],
			data => {
				john => ['john', 38, "!Index:Gender.male"],
				jane => ['jane', 40, '!Index:Gender.female'],
			}}},
		
		{FriendList => {
			fields => ['person', 'friend', 'created_date'],
			data => {
				john_jane => [
					'!Index:Person.john',
					'!Index:Person.jane'
					'!Date: March 30, 1996',
				],
			}}},
	];
	
	$schema->populate_more($setup_rows);

Please see the test cases for more detailed examples.

=head1 DESCRIPTION

This is a L<DBIx::Class::Schema> component that provides an enhanced version
of the builtin method L<DBIx::Class::Schema/populate>.  What it does is make it 
easier when you are doing a first time setup and need to insert a bunch of 
rows, like the first time you deploy a new database, or after you update it.

It's not as full featured as L<DBIx::Class::Fixtures> but is targeted more 
directly at making it easier to just take a prewritten perl structure --or one 
loaded from a configuration file-- and setup your database.

Most of us using L<DBIx::CLass> have written a version of this at one time or
another.  What is special to this component is the fact that unlike the normal
populate method you can insert to multiple result_sources in one go.  While 
doing this, we index the created rows so as to make it easy to reference them
in relationships. I did this because I think it's very ugly to have to type in 
all the primary keys by hand, particularly if your PK is multi column, or is
using some lengthy format such as uuid.  Also, we can embed expansion commands
in the row values to do inflation for us.  For example, any value starting with
"!Index:" will substitute it's value for that of the relating fields in the 
named row.

This distribution supplies three expansion commands:

=over 4

=item Index

Use for creating relationships.  This is a string in the form of "Source.Label"
where the Source is the name of the result source that you are creating rows in 
and Label is a key name from from key part of the data hash.

=item Env

Get's it's value from %ENV.  Typically this will be setup in your shell or at
application runtime.

=item Date

converts it's value to a L<DateTime> object.  Will use a various methods to try
and coerce a string, like "today", or "January 6, 1974".  Makes it easier to
insert dates into your database without knowing or caring about the expected
format.  For this to work correctly, you need to use the class component
L<DBIx::Class::InflateColumn::DateTime> and mark your column data type as 
'datetime' or similar.

=item Find

Used for when you want the value of something that you expect already exists
in the database (but for which you didn't just populatemore for, use 'Index'
for that case.) Use cases for this include lookup style tables, like 'Status'
or 'Gender', 'State', etc. which you may already have installed.

It's trivial to write more; please feel free to post me your contributions.

=back

Please note the when inserting rows, we are actually calling "create_or_update"
on each data item, so this will not be as fast as using $schema->bulk_insert.


=head1 METHODS

This module defines the following methods.

=head2 populate_more ($ArrayRef||@Array)

Given an arrayref formatted as in the L</SYNOPSIS> example, populate a rows in
a database.  Confesses on errors.  

The $ArrayRef contains one or more elements in the following pattern;

	{Source => {
		fields => [qw/ column belongs_to has_many/],
		data => {
			key_1 => ['value', $row, \@rows ],
	}}}

'Source' is the name of a DBIC source (as in $schema->resultset($Source)->...)
while fields is an arrayref of either columns or named relationships and data
is a hashref of rows that you will insert into the Source.

See L</SYNOPSIS> for more.

=cut

sub populate_more {
	my ($self, $arg, @rest) = @_;

    $self->throw_exception("Argument is required.")
	  unless $arg;

	$arg = ref $arg eq 'ARRAY' ? $arg : [$arg, @rest];
	
	my $command;
	eval {
		$command = DBIx::Class::Schema::PopulateMore::Command->new(
			definitions=>$arg,
			schema=>$self,
		);
	}; if ($@) {
		$self->throw_exception("Can't create Command: $@");
	} else {
		$command->execute;
	}			
}


=head1 ARGUMENT NOTES

The perl structure used in L</populate_more> was designed to be reasonable
friendly to type in most of the popular configuration formats.  For example,
the above serialized to YAML would look like:

	- Gender:
		fields: label	
		data:
		  female: female
		  male: male
	- Person:
		fields:
		  - name
		  - age
		  - gender
		data:
		  jane:
			- jane
			- 40
			- '!Index:Gender.female'
		  john:
			- john
			- 38
			- !Index:Gender.male'
	- FriendList:
		fields:
		  - person
		  - friend	
		  - created_date
		data:
		  john_jane:
			- '!Index:Person.john'
			- '!Index:Person.jane'
			- '!Date: March 30, 1996'

Since the argument is an arrayref or an array, the same base result source can 
appear as many times as you like.  This could be useful when a second insert 
to a given source requires completion of other inserts.  The insert order 
follows the index of the arrayref you create.

=head1 AUTHOR

John Napiorkowski, C<< <jjnapiork@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to:

	C<bug-DBIx-Class-Schema-PopulateMore at rt.cpan.org>

or through the web interface at:

	L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-Schema-PopulateMore>

I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Schema::PopulateMore

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-Schema-PopulateMore>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-Schema-PopulateMore>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-Schema-PopulateMore>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-Schema-PopulateMore>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to the entire L<DBIx::Class> team for providing such a useful and 
extensible ORM.  Also thanks to the L<Moose> developers for making it fun and
easy to write beautiful Perl.

=head1 LICENSE & COPYRIGHT

Copyright 2008-2009, John Napiorkowski <jjnapiork@cpan.org>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
