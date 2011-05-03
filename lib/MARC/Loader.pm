# vim: sw=4
package MARC::Loader;
use 5.10.0;
use warnings;
use strict;
use Carp;
use MARC::Record;
use YAML;
use Scalar::Util qw< reftype >;
our $VERSION = '0.002001';
our $DEBUG = 0;
sub debug { $DEBUG and say STDERR @_ }

sub new {
	my ($self,$data) = @_;
	my $r = MARC::Record->new();
	my $orderfields = 0;
	my $ordersubfields = 0;
	my $cleannsb = 0;
	my $lc={};#the controlfield's list
	my $lf={};#the field's list
	my $cf={};#counter where multiple fields with same name
	my $bf={};#bool ok if field have one subfield at least
	foreach my $k (keys(%$data)) {
		if (($k eq "ldr") or ($k eq "orderfields") or ($k eq "ordersubfields") or ($k eq "cleannsb")) {
			next;
		}
		if ( ref( $$data{$k} ) eq "ARRAY" ) {
			foreach my $v(@{$$data{$k}}) {
				createfield($k,$lc,$lf,$bf,$cf,$v);
			}
		} else {
			createfield($k,$lc,$lf,$bf,$cf,$$data{$k});
		}
	}
	if (defined($$data{"ldr"}) and $$data{"ldr"} ne "") {
		$r->leader($$data{"ldr"});
	}
	if ($$data{"orderfields"}) {
		$orderfields=1;
	}
	if ($$data{"ordersubfields"}) {
		$ordersubfields=1;
	}
	if ($$data{"cleannsb"}) {
		$cleannsb=1;
	}
	foreach my $contk (keys(%$lc)) {
		$r->insert_fields_ordered( $$lc{$contk} );
	}
	foreach my $k (keys(%$lf)) {
		if ($$bf{$k}==1) {
			$$lf{$k}->delete_subfield(pos => 0);
			$r->insert_fields_ordered( $$lf{$k} );
		}
	}
	$r=order_cleanrecord($orderfields, $ordersubfields, $cleannsb, $r);
	$r;
}

sub createfield {
	my ($k,$lc,$lf,$bf,$cf,$v) = @_;
	#$k = the hash key that defines the field or subfield name
	#$v = the field or subfield value
	#$lc= the controlfield's list
	#$lf= the field's list
	#$cf= counter where multiple fields with same name
	#$bf= bool ok if field have one subfield at least
	if ($k=~/^(\D)(\d{3})(\w)$/) {
		if (!exists($$lf{$2})) {
			if($2<10 and defined($v) and $v ne "") {
				$$lc{$2} = MARC::Field->new( "$2", $v );
			} else {
				$$lf{$2} = MARC::Field->new( "$2", "", "", 0 => "temp" );
				#$fnoauth = MARC::Field->new( '009', $noauth );
				$$bf{$2}=0;
				if (defined($v) and $v ne "") {
					createsubfield($$lf{$2},$3,$v,$k);
					$$bf{$2}=1;
				}
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
		if($2<10){warn "controlfields can't be hash : $2";return;}
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

sub order_cleanrecord {
	my ($orderfields, $ordersubfields, $cleannsb, $in_record) = @_;
	#$orderfields : bool to defined if we want to order fields
	#$ordersubfields : bool to defined if we want to order subfields
	#$cleannsb : bool to defined if we want to clean Non Sorting Block for each fields and subfields
	#$in_record : the Marc reacord paramater
	my $out_record=MARC::Record->new;
	$out_record->leader($in_record->leader);
	my @order = qw/0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z/;
	my %tag_names;
	if($orderfields)
	{
		%tag_names = map( { $$_{_tag} => 1 } $in_record->fields); #eq. my @ordre;foreach my $field ( $in_record->fields ) { push (@ordre, $$field{"_tag"}) } \nmy %tag_names;foreach(@ordre){$tag_names{$_} = 1;}
	}
	else
	{
		%tag_names = (1=>1);
	}
	foreach my $tag(sort({ $a <=> $b } keys(%tag_names)))
	{
		my @fields;
		if($orderfields)
		{
			@fields=$in_record->field($tag);
		}
		else
		{
			@fields=$in_record->fields();
		}
		foreach my $field(@fields)
		{
			my $newfield;
			if ($field->is_control_field())
			{
				$field->update(nsbclean($field->data())) if $cleannsb;
				$out_record->append_fields($field);
			}
			else
			{
				my @subfields;
				if($ordersubfields)
				{
					foreach my $key (@order)
					{
						foreach my $subfield ($field->subfield($key))
						{
							$subfield=nsbclean($subfield) if $cleannsb;
							push @subfields, $key, $subfield;
						}
					}
				}
				else
				{
					foreach my $subfield ($field->subfields())
					{
						$subfield->[1]=nsbclean($subfield->[1]) if $cleannsb;
						push @subfields, $subfield->[0], $subfield->[1];
					}
				}
				if (scalar(@subfields) > 0)
				{
					eval { $newfield = MARC::Field->new($field->tag(), $field->indicator(1), $field->indicator(2), @subfields); };
					if ($@)
					{
						warn "error : $@";
					}
					else
					{
						$out_record->append_fields($newfield);
					}
				}
			}
		}
	}
	return $out_record;
}

sub nsbclean {
    my ($string) = @_ ;
    $_ = $string ;
    s/\x88//g ;# NSB : begin Non Sorting Block
    s/\x89//g ;# NSE : Non Sorting Block end
    s/\x98//g ;# NSB : begin Non Sorting Block
    s/\x9C//g ;# NSE : Non Sorting Block end
    s/\xC2//g ;# What is this char ? It is sometimes left by the regexp after removing NSB / NSE 
    $string = $_ ;
    return($string) ;
}
1;
__END__

=head1 NAME

MARC::Loader - Perl extension for creating MARC record from a hash

=head1 VERSION

Version 0.002001

=head1 SYNOPSIS

	use MARC::Loader;
	my $foo={
		'ldr' => 'optionnal_leader',
		'ordersubfields' => 1,
		'cleannsb' => 1,
		'f005_' => 'controlfield_content',
		'f010d' => '45',
		'f099c' => '2011-02-03',
		'f099t' => 'LIVRE',
		'i0991' => '3',
		'i0992' => '4',
		'f200a' => "\x88le \x89titre",
		'f101a' => [ 'lat','fre','spa'],
		'f215a' => [ 'test' ],
		'f700'  => [{'f700f' => '1900-1950','f700a' => 'ICHER','f700b' => [ 'jean','francois']},
			{'f700f' => '1353? - 1435','f700a' => 'PAULUS','f700b' => 'MARIA'}]	};
	my $record = MARC::Loader->new($foo);

	# Here, the command "print $record->as_formatted;" will return :
	# LDR optionnal_leader
	# 005     controlfield_content
	# 010    _d45
	# 099 34 _c2011-02-03
	#        _tLIVRE
	# 101    _alat
	#        _afre
	#        _aspa
	# 200    _ale titre
	# 215    _atest
	# 700    _aICHER
	#        _bjean
	#        _bfrancois
	#        _f1900-1950
	# 700    _aPAULUS
	#        _bMARIA
	#        _f1353? - 1435

=head1 DESCRIPTION

This is a Perl extension for creating MARC records from a hash variable. 
MARC::Loader use MARC::Record.

The names of hash keys are very important.

They must begin with one letter ( e.g. C<f>) followed by the 3-digit field ( e.g. C<099>) optionally followed by the letter or digit of the subfield.
Repeatable fields are arrays of hash ( e.g., 'f700'  => [{'f700f' => '1900','f700a' => 'ICHER'},{'f700f' => '1353','f700a' => 'PAULUS'}] ).
Repeatable subfields are arrays ( e.g., 'f101a' => [ 'lat','fre','spa'] ).
Control fields can't be repeatable and are automatically detected when the hash key begin with one letter followed by 3-digit lower than 10 followed by one letter or digit or underscore ( e.g. C<f005_>).
Indicators must begin with the letter i followed by the 3-digit field followed by the indicator's position (1 or 2) :  e.g. C<i0991>.

Record's leader can be defined with an hash key named 'ldr' ( e.g., 'ldr' => 1 ).
You can reorder the fields in alphabetical order with an hash key named 'orderfields' ( e.g., 'orderfields' => 1 ).
You can reorder the subfields of each field in alphabetical order with an hash key named 'ordersubfields' ( e.g., 'ordersubfields' => 1 ).
You can remove non-sorting characters with an hash key named 'cleannsb' ( e.g., 'cleannsb' => 1 ).

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
