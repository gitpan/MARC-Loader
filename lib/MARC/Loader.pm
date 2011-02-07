# vim: sw=4
package MARC::Loader;
use 5.10.0;
use warnings;
use strict;
use Carp;
use MARC::Record;
use YAML;
use Scalar::Util qw< reftype >;
our $VERSION = '0.001001';
our $DEBUG = 0;
sub debug { $DEBUG and say STDERR @_ }

sub new {
	my ($self,$data) = @_;
	my $r = MARC::Record->new();
	my $lf={};#the field's list
	my $cf={};#counter where multiple fields with same name
	my $bf={};#bool ok if field have one subfield at least
	foreach my $k (keys(%$data)) {
		if ( ref( $$data{$k} ) eq "ARRAY" ) {
			foreach my $v(@{$$data{$k}}) {
				createfield($k,$lf,$bf,$cf,$v);
			}
		} else {
			createfield($k,$lf,$bf,$cf,$$data{$k});
		}
	}
	foreach my $k (keys(%$lf)) {
		if ($$bf{$k}==1) {
			$$lf{$k}->delete_subfield(pos => 0);
			$r->insert_fields_ordered( $$lf{$k} );
		}
	}
	$r;
}

sub createfield {
	my ($k,$lf,$bf,$cf,$v) = @_;
	#$k = the hash key that defines the field or subfield name
	#$v = the field or subfield value
	#$lf= the field's list
	#$cf= counter where multiple fields with same name
	#$bf= bool ok if field have one subfield at least
	if ($k=~/^(\D)(\d{3})(\w)$/) {
		if (!exists($$lf{$2})) {
			$$lf{$2} = MARC::Field->new( "$2", "", "", 0 => "temp" );
			$$bf{$2}=0;
			if (defined($v) and $v ne "") {
				createsubfield($$lf{$2},$3,$v,$k);
				$$bf{$2}=1;
			}
		} else {
			if (defined($v) and $v ne "") {
				createsubfield($$lf{$2},$3,$v,$k);
				$$bf{$2}=1;
			}
		}
	} elsif (($k=~/^(\D)(\d{3})$/) and ( ref( $v ) eq "HASH" )) {
		if (!exists($$cf{$2})) {
			$$cf{$2}=0;
		}
		$$cf{$2}++;
		$$lf{$2.$$cf{$2}} = MARC::Field->new( "$2", "", "", 0 => "temp" );
		$$bf{$2.$$cf{$2}}=0;
		foreach my $k (keys(%$v)) {
			if (defined($$v{$k}) and $$v{$k} ne "" and ref($$v{$k}) eq "ARRAY" ) {
				foreach my $v(@{$$v{$k}}) {
					if ($k=~/^(\D)(\d{3})(\w)$/) {
						createsubfield($$lf{$2.$$cf{$2}},$3,$v,$k);
						$$bf{$2.$$cf{$2}}=1;
					} else {
						warn "wrong field name : $k";return;
					}
				}
			} elsif (defined($$v{$k}) and $$v{$k} ne "") {
				if ($k=~/^(\D)(\d{3})(\w)$/) {
					createsubfield($$lf{$2.$$cf{$2}},$3,$$v{$k},$k);
					$$bf{$2.$$cf{$2}}=1;
				} else {
					warn "wrong field name : $k";return;
				}
			}
		}
	} else {
		warn "wrong field name : $k";return;
	}
}

sub createsubfield {
	my (($f,$s,$v,$k))=@_;
	#$f = the field
	#$s = the subfield name
	#$k = the hash key that defines the subfield name
	#$v = the subfield value
	if ($k=~/^(i)(\d{3})(\w)$/) {
		my $ind=$3;
		if ( ($3=~/1|2/) and ($v=~/\d|\|/) ) {
			$f->update( "ind$ind" => $v);
		} else {
			warn "wrong ind values : $k=$v";return;
		}
	} else {
		$f->add_subfields( "$s" => $v );
	}
}
1;
__END__

=head1 NAME

MARC::Loader - Perl extension for creating MARC record from a hash

=head1 VERSION

Version 0.001001

=head1 SYNOPSIS

	use MARC::Loader;
	my $foo={
		'f010d' => '45',
		'f099c' => '2011-02-03',
		'f099t' => 'LIVRE',
		'i0991' => '3',
		'i0992' => '4',
		'f101a' => [ 'lat','fre','spa'],
		'f215a' => [ 'test' ],
		'f700'  => [{'f700f' => '1900-1950','f700a' => 'ICHER','f700b' => [ 'jean','francois']},
					{'f700f' => '1353? - 1435','f700a' => 'PAULUS','f700b' => 'MARIA'}]	};
	my $record = MARC::Loader->new($foo);

	# Here, the command "print $record->as_formatted;" will return :
	# LDR                         
	# 010    _d45
	# 099 34 _tLIVRE
	#        _c2011-02-03
	# 101    _alat
	#        _afre
	#        _aspa
	# 215    _atest
	# 700    _f1900-1950
	#        _aICHER
	#        _bjean
	#        _bfrancois
	# 700    _f1353? - 1435
	#        _aPAULUS
	#        _bMARIA

=head1 DESCRIPTION

This is a Perl extension for creating MARC records from a hash variable. 
MARC::Loader use MARC::Record.

The names of hash keys are very important.
They must begin with one letter (C<f> eg) followed the 3-digit field (C<099> eg) optionally followed the letter or digit of the subfield.
Repeatable fields are arrays of hash ( C<'f700'  => [{'f700f' => '1900','f700a' => 'ICHER'},{'f700f' => '1353','f700a' => 'PAULUS'}]> eg ).
Repeatable subfields are arrays ( C<'f101a' => [ 'lat','fre','spa']> eg ).
Indicators must begin with the letter i followed the 3-digit field followed by the indicator's position (1 or 2) : C<i0991> eg.

=head1 METHOD

=head2 new()

=over 4

=item * $record = MARC::Loader->new($foo);

it's the only function you'll use.

=back

=head1 AUTHOR

Stephane Delaune, (delaune.stephane at gmail.com)

=head1 COPYRIGHT

Copyright 2011 Stephane Delaune for Biblibre.com, all rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item * MARC::Record (L<http://search.cpan.org/~gmcharlt/MARC-Record/lib/MARC/Record.pm>)

=item * MARC::Field (L<http://search.cpan.org/~gmcharlt/MARC-Record/lib/MARC/Field.pm>)

=item * Library Of Congress MARC pages (L<http://www.loc.gov/marc/>)

The definitive source for all things MARC.

=cut
