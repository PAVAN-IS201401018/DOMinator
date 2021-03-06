#!/usr/bin/perl
$ID = "mkjpconv.pl @ARGV (Time-stamp: <2001-08-08 18:54:54 shom>)";

# ***** BEGIN LICENSE BLOCK *****
# Version: MPL 1.1/GPL 2.0/LGPL 2.1
#
# The contents of this file are subject to the Mozilla Public License Version
# 1.1 (the "License"); you may not use this file except in compliance with
# the License. You may obtain a copy of the License at
# http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS IS" basis,
# WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
# for the specific language governing rights and limitations under the
# License.
#
# The Original Code is mozilla.org code.
#
# The Initial Developer of the Original Code is
# Netscape Communications Corporation.
# Portions created by the Initial Developer are Copyright (C) 1998
# the Initial Developer. All Rights Reserved.
#
# Contributor(s):
#   Shoji Matsumoto <shom@vinelinux.org>
#
# Alternatively, the contents of this file may be used under the terms of
# either the GNU General Public License Version 2 or later (the "GPL"), or
# the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
# in which case the provisions of the GPL or the LGPL are applicable instead
# of those above. If you wish to allow use of your version of this file only
# under the terms of either the GPL or the LGPL, and not to allow others to
# use your version of this file under the terms of the MPL, indicate your
# decision by deleting the provisions above and replace them with the notice
# and other provisions required by the GPL or the LGPL. If you do not delete
# the provisions above, a recipient may use your version of this file under
# the terms of any one of the MPL, the GPL or the LGPL.
#
# ***** END LICENSE BLOCK *****

#
# based on CP932.TXT from unicode.org
# additional information from SHIFTJIS.TXT from unicode.org
#
# mapping policy:
#   jis0208 to unicode : based on CP932
#   unicode to jis0208 : based on CP932
#                        the lowest code is used for dual mapping to jis0208
#   ascii region       : based on ISO8859-1 ( same as CP932 ) IGNORE?
#   kana region        : based on CP932
#   IBM Ext(0xFxxx>)   : premap to NEC region ( mappable to JIS )

if ($ARGV[0] eq "") {
    print STDERR "usage: mkjpconv.pl SHIFTJIS.TXT <INFILE(ex:CP932.TXT)> [Another check]\n";
    exit 1;
}

open (SI, "SHIFTJIS.TXT") || die;
while(<SI>) {
    ($hi,$lo) = /^0x(..)?(..)\s/;
    if ($lo eq "") { next; }
    if ($hi eq "") { $hi="  " }
    $defined{"0x$hi$lo"} = 1;
}
close (SI);

shift(@ARGV);

$src = $ARGV[0];

$gendir = "$src.d";
mkdir("$src.d");

$sufile = "sjis2ucs-$src.map";
$usfile = "ucs2sjis-$src.map";
$jufile = "jis2ucs-$src.map";
$jeufile = "jisext2ucs-$src.map";
$jaufile = "jisasc2ucs-$src.map";
$jrkufile = "jiskana2ucs-$src.map";
$ujfile = "ucs2jis-$src.map";
$ujefile = "ucs2jisext-$src.map";
$ujafile = "ucs2jisasc-$src.map";
$ujrkfile = "ucs2jiskana-$src.map";
$ibmnecfile = "$gendir/IBMNEC.map";
$jdxfile = "$gendir/jis0208.ump";
$jdxextfile = "jis0208ext.ump";
$commentfile = "comment-$src.txt";

open (IN, "NPL.header") || die;
while(<IN>) {
    $NPL .= $_;
}
close (IN);

foreach $infile ( @ARGV ) {

    open (IN, "$infile") || die;

    while(<IN>) {
	($from, $to, $seq, $dum, $comment) =
	    /^\s*(0x[0-9a-fA-F]+)\s+(0x[0-9a-fA-F]+)(\+0x\S+)?(\s+\#\s*(\S.*))?$/;
	if ( $seq ne "" ) {
	    print "Warning: Unicode Seq:\t$from\t$to$seq\t# $comment\n";
	}

	if ( $from eq "" ) { next; }
	
	if ( $from =~ /0x(..)$/ ) {
	    $from = "  0x$1";
	}
	
	if ( $fromto{$from} eq "" ) {
	    push(@fromlist, $from);
	    $fromto{$from} = $to;
	    $commentbody{$from} = $comment;
	    $commentseq{$from} = $seq
	} elsif ( $fromto{$from} ne $to ) {
	    # another mappint SJIS:UCS2 = 1:N
	    print "Another map in $infile\t$from\t$fromto{$from},$to\n";
	}

	if ($checkanother==1) {
	    next;
	}

	if ( $tofrom{$to} eq "" ) {
	    $tofrom{$to} = $from;
	} else {
	    if ( $from !~ /$tofrom{$to}/ ){
	    $tofrom{$to} = "$tofrom{$to},$from";
	}
	}
    
	# print "$from $to\n";
    }

    close (IN);

    $checkanother == 1;
}

open (COMMENT, ">$commentfile") || die;
foreach $from (sort(@fromlist)) {
    print COMMENT "$from\t$fromto{$from}$commentseq{$from}\t$commentbody{$from}\n";
}
close (COMMENT);


open(SU, ">$sufile") || die;
open(US, ">$usfile") || die;
open(JU, ">$jufile") || die;
open(JEU, ">$jeufile") || die;
open(JAU, ">$jaufile") || die;
open(JRKU, ">$jrkufile") || die;
open(UJ, ">$ujfile") || die;
open(UJE, ">$ujefile") || die;
open(UJA, ">$ujafile") || die;
open(UJRK, ">$ujrkfile") || die;
open(IBMNEC, ">$ibmnecfile") || die;

# print SU "/* generated from $src : SJIS UCS2 */\n";
# print US "/* generated from $src : UCS2 SJIS */\n";
print "Generated from $src\n";
print "Command: mkjpconv.pl @ARGV\n";
print "SJIS(JIS)\tUCS2\tSJIS\tS:U:S\tSJIS lower\n";

foreach $i (sort(@fromlist)) {

    $ucs = "";

    $sjis = $i;
    $sjis =~ s/\s+//;
    $jis = sjistojis($sjis);

    print "$i($jis)\t$fromto{$i}\t$tofrom{$fromto{$i}}";
    $ucs = $fromto{$i};

    if ( $i eq $tofrom{$fromto{$i}} ) {
	print "\t1:1:1";
	print "\t$i";
    } else {
	print "\t1:1:N";
	@tolist = split(/,/,$tofrom{$fromto{$i}});
	print "\t$tolist[0]";
	#$ucs = $tolist[0];
	if ( $sjis =~ /0xF[A-D]../ ) {
	    $ibmnec{$sjis} = $tolist[0];
	    #print IBMNEC "$sjis\t$tolist[0]\n";
	}

    }
    print SU "$sjis\t$ucs\n";
    push(@uslist, "$ucs\t$sjis\n");

    #print US "$ucs\t$sjis\n";
    if ( $jis ne "") {
	#if ($sjis =~ /^0x87../ || $sjis =~ /^0xED../ ) {
	    # cp932 ext
	if ($sjis =~ /0x..../ && $defined{$sjis} != 1) {
	    # jis not define
	    print JEU "$jis\t$ucs\n";
	    push(@ujelist, "$ucs\t$jis\n");
	    $jisextucs{$jis} = $ucs;
	} else {
	    print JU "$jis\t$ucs\n";
	    push(@ujlist, "$ucs\t$jis\n");
	    $jisucs{$jis} = $ucs;
	}

	#print UJ "$ucs\t$jis\n";
    } elsif ( $sjis =~ /\s*0x([8-9A-D].)/ ) {
	$code = $1;
	print JRKU "0x00$code\t$ucs\n";
	push(@ujrklist, "$ucs\t0x00$code\n");
    } elsif ( $sjis =~ /\s*0x([0-7].)/ ) {
	$code = $1;
	print JAU "0x00$code\t$ucs\n";
	push(@ujalist, "$ucs\t0x00$code\n");
    }
    #print "\t# $comment{$i}\n";
    print "\n";
}

print US sort(@uslist);
print UJ sort(@ujlist);
print UJE sort(@ujelist);
print UJA sort(@ujalist);
print UJRK sort(@ujrklist);

# make ibmnec mapping

print IBMNEC $NPL;
print IBMNEC "/* generated by $ID */\n";
print IBMNEC "/* IBM ext codes to NEC sel (in CP932) */\n\n";

foreach $i (0xFA, 0xFB, 0xFC) {
    for ($j=( ($i==0xFA) ? 0x40 : 0x00 ); $j<=0xFF; $j++) {
	$ibm = sprintf("0x%02X%02X", $i, $j);
	$raw = substr($ibm, 2,6);
	if ("" == $ibmnec{$ibm}) {
	    print IBMNEC "/* $raw:UNDEF */ 0, \n";
	} else {
	    print IBMNEC "/* $raw */ $ibmnec{$ibm}, \n";
	}
    }
}

close(IBMNEC);

# make jdx

open (JDX, ">$jdxfile") || die;
    
print JDX $NPL;
print JDX "/* generated by $ID */\n";
print JDX "/* JIS X 0208 (with CP932 ext) to Unicode mapping */\n";

for ($i=0; $i<94; $i++) {
    printf JDX "/* 0x%2XXX */\n", ($i+0x21);
    printf JDX "       ";
    for ($j=0; $j<94; $j++) {
	$jis = sprintf("0x%02X%02X", ($i+0x21), $j+0x21);
	# get JIS
	$ucs = $jisucs{$jis};
	if ("" == $ucs) {
	    # try CP932 ext
	    # try jis ext
	    $ucs = $jisextucs{$jis}
	}
	if ("" == $ucs) {
	    # undefined
	    print JDX "0xFFFD,";
	} else {
	    print JDX "$ucs,";
	}
	if (7 == ( ($j+1) % 8 )) {
	    printf JDX "/* 0x%2X%1X%1X*/\n", $i+0x21, 2+($j/16), (6==($j%16))?0:8;
	}
    }
    printf JDX "       /* 0x%2X%1X%1X*/\n", $i+0x21, 2+($j/16), (6==($j%16))?0:8;
}

close (JDX);


close(SU);
close(US);
close(JU);
close(JEU);
close(JAU);
close(JRKU);
close(UJ);
close(UJE);
close(UJA);
close(UJRK);

# generate uf files

sub genuf {
    my ($infile, $outfile) = @_;
    my $com = "cat $infile | ./umaptable -uf > $gendir/$outfile";
    print "Executing $com\n";
    system($com);
}

genuf($sufile, "sjis.uf");
genuf($jufile, "jis0208.uf");
if ( $#ujelist > 0 ) {
    genuf($jeufile, "jis0208ext.uf");
} else {
    print "Extension is not found. jis0208ext.uf is not generated.\n";
}
genuf("$jaufile $jrkufile", "jis0201.uf");
# genuf($jaufile, "jis0201.uf");
# genuf($jrkufile, "jis0201gl.uf");


# generate test page


exit;

sub sjistojis {
   my($sjis) = (@_);
   my($first,$second,$h, $l, $j0208);

   if ( $sjis !~ /^0x....$/ ) {
       return "";
   }

   $first = hex(substr($sjis,2,2));
   $second = hex(substr($sjis,4,2));
   $jnum=0;

   if($first < 0xE0)
   {
       $jnum = ($first - 0x81) * ((0xfd - 0x80)+(0x7f - 0x40));
   } else {
       $jnum = ($first - 0xe0 + (0xa0-0x81)) * ((0xfd - 0x80)+(0x7f - 0x40));
   }
   if($second >= 0x80)
   {
       $jnum += $second - 0x80 + (0x7f-0x40);
   }
   else
   {
       $jnum += $second - 0x40;
   }
   if(($jnum / 94 ) < 94) {
       return sprintf "0x%02X%02X", (($jnum / 94) + 0x21), (($jnum % 94)+0x21);
   } else {
       #return sprintf "# 0x%02X%02X", (($jnum / 94) + 0x21), (($jnum % 94)+0x21);
       return "";
   }
}

