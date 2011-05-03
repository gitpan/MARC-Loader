#!/usr/bin/perl
use Data::Compare;
use strict;
use warnings;
use lib qw( lib ../lib );
use YAML;
use Test::More 'no_plan';
BEGIN {
    use_ok( 'MARC::Loader' );
}
my $r={
          'ldr' => 'optionnal_leader',
          'ordersubfields' => 1,
          'cleannsb' => 1,
          'f005_' => 'controlfield_content',
          'f995' => [
                      {
                        'f995e' => 'Salle de lecture 1',
                        'f995b' => 'MP',
                        'f995k' => 'NT 0380/6/1',
                        'f995c' => 'MPc',
                        'f995f' => '8001-ex',
                        'f995r' => 'PRET',
                        'f995o' => '0'
                      },
                      {
						'i9951' => '1',
						'i9952' => '2',
                        'f995e' => 'Salle de lecture 2',
                        'f995b' => 'MP',
                        'f995k' => 'NT 0380/6/1',
                        'f995c' => 'MPc',
                        'f995f' => '8002-ex',
                        'f995r' => 'PRET',
                        'f995o' => '0'
                      },
                      {
                        'f995e' => 'Salle de lecture 3',
                        'f995b' => 'MPS',
                        'f995k' => 'MIS 0088',
                        'f995c' => 'MPS',
                        'f995f' => '8003-ex',
                        'f995r' => 'PRET',
                        'f995o' => '0'
                      }
                    ],
          'f215a' => [
                       '201'
                     ],
          'f615' => [
                      {
                        'f615a' => 'CATHEDRALE'
                      },
                      {
                        'f615a' => 'BATISSEUR'
                      }
                    ],
          'f210a' => [
                       'Paris'
                     ],
          'f300' => [
                      {
                        'f300a' => 'tabl. photos'
                      }
                    ],
          'f035a' => '8002',
          'i0992' => '4',
          'f702' => [
                      {
                        'f702f' => '1090?-1153',
                        'f7024' => '730',
                        'f702a' => 'Bernard de Clairvaux'
                      }
                    ],
          'f010d' => '45',
          'f200a' => "\x88Les \x89ouvriers des calanques",
          'i0991' => '3',
          'f210c' => [
                       'La Martiniere'
                     ],
          'f010a' => [
                       '111242417X'
                     ],
          'f461' => [
                      {
                        'f461v' => '48'
                      },
                      {
                        'f461v' => '61'
                      }
                    ],
          'f099c' => '2011-02-03',
          'f700' => [
                      {
                        'f700f' => '',
                        'f700a' => 'ICHERFrancois'
                      },
                      {
                        'f700f' => '1353? - 1435',
                        'f700a' => 'PAULUS',
                        'f700b' => [ 'jean','francois']
                      }
                    ],
          'f099d' => '',
          'f225' => [
                      {
                        'f225a' => 'Sources calanquaises',
                        'f225v' => '48'
                      },
                      {
                        'f225a' => 'Calanquaises Kommentar',
                        'f225v' => '61'
                      }
                    ],
          'f210d' => '1998',
          'f200g' => [
                       'ITHER, fred',
                       'Facundus,hector (05..?-0571?)',
                       'Bernard de Clairvaux (saint ; 1090?-1153)'
                     ],
          'f101a' => [
                       'lat',
                       'fre',
                       'ger',
                       'gem',
                       'por',
                       'spa'
                     ],
          'f099t' => 'LIVRE',
          'f200f' => 'ICHERFrancois, PAULUS, MARIA 1353? - 1435',
          'f330' => [],
          'f701' => [
                      {
                        'f701f' => '',
                        'f701a' => 'ITHER',
                        'f701b' => 'fred'
                      },
                      {
                        'f701f' => '05..?-0571?',
                        'f701a' => 'Facundus',
                        'f701b' => 'hector'
                      }
                    ],
          'f215c' => 'ill. coul.'
        };
my $record = MARC::Loader->new($r);

my $v1=YAML::Dump $record->as_formatted;
my $v2=YAML::Dump ("LDR optionnal_leader
005     controlfield_content
010    _a111242417X
       _d45
035    _a8002
099 34 _c2011-02-03
       _tLIVRE
101    _alat
       _afre
       _ager
       _agem
       _apor
       _aspa
200    _aLes ouvriers des calanques
       _fICHERFrancois, PAULUS, MARIA 1353? - 1435
       _gITHER, fred
       _gFacundus,hector (05..?-0571?)
       _gBernard de Clairvaux (saint ; 1090?-1153)
210    _aParis
       _cLa Martiniere
       _d1998
215    _a201
       _cill. coul.
225    _aCalanquaises Kommentar
       _v61
225    _aSources calanquaises
       _v48
300    _atabl. photos
461    _v48
461    _v61
615    _aCATHEDRALE
615    _aBATISSEUR
700    _aPAULUS
       _bjean
       _bfrancois
       _f1353? - 1435
700    _aICHERFrancois
701    _aFacundus
       _bhector
       _f05..?-0571?
701    _aITHER
       _bfred
702    _4730
       _aBernard de Clairvaux
       _f1090?-1153
995    _bMPS
       _cMPS
       _eSalle de lecture 3
       _f8003-ex
       _kMIS 0088
       _o0
       _rPRET
995    _bMP
       _cMPc
       _eSalle de lecture 1
       _f8001-ex
       _kNT 0380/6/1
       _o0
       _rPRET
995 12 _bMP
       _cMPc
       _eSalle de lecture 2
       _f8002-ex
       _kNT 0380/6/1
       _o0
       _rPRET");
ok(Compare($v1,$v2))
    or diag(Dump $v1);
#print $record->as_formatted;
