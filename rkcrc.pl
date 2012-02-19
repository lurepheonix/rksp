#!/usr/bin/perl

sub copyright(){
  print STDERR << "EOF";
 * Copyright (C) 2012 ttz642t\@gmail.com (perl code)
 * Copyright (C) 2010, 2011 FUKAUMI Naoki (original algorithm)
All rights reserved. rkutils :: https://github.com/naobsd/rkutils

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
EOF
  exit;
}

use warnings;
use strict;
use vars qw/ %opt /;

my $progbar ="========"; $progbar.=$progbar; $progbar.=$progbar; $progbar.=$progbar;

sub usage(){
  print STDERR << "EOF";

    This program creates a rockchip compliant PARM or KRNL file

	  usage: $0 [-k|-p|-b] -i infile -o outfile

     -c           : Copyright banner
     -h           : this (help) message
     -b           : create a BOOT type file
     -k           : create a KRNL type file
     -p           : create a PARM type file
     -i infile    : file to calculate length, crc & prefix with type
     -o outfile   : resulting file

    example: $0 -p -i parameters -o parameters.img

EOF
  exit;
}

sub options(){
  use Getopt::Std;
  my $opt_string = 'hckpbi:o:';
  getopts( "$opt_string", \%opt ) or usage();
  if($opt{c}){copyright();}
  if(! $opt{o}){print "No output file specified\n";}
  if(! -f $opt{i}){print "No input file exists\n";usage();}
  usage() if $opt{h} || ($opt{p} && $opt{k}) ||! $opt{i} ||! $opt{o} ;
}

options();

my $blksize = 4096;
my $filename;
my $buffercnt;
my $crc;
my $bytesread;


my @t  = (	0x00000000, 0x04c10db7, 0x09821b6e, 0x0d4316d9,	0x130436dc, 0x17c53b6b, 0x1a862db2, 0x1e472005,
			0x26086db8, 0x22c9600f, 0x2f8a76d6, 0x2b4b7b61, 0x350c5b64, 0x31cd56d3, 0x3c8e400a, 0x384f4dbd,
			0x4c10db70, 0x48d1d6c7, 0x4592c01e, 0x4153cda9, 0x5f14edac, 0x5bd5e01b, 0x5696f6c2, 0x5257fb75,
			0x6a18b6c8, 0x6ed9bb7f, 0x639aada6, 0x675ba011, 0x791c8014, 0x7ddd8da3, 0x709e9b7a, 0x745f96cd,
			0x9821b6e0, 0x9ce0bb57, 0x91a3ad8e, 0x9562a039, 0x8b25803c, 0x8fe48d8b, 0x82a79b52, 0x866696e5,
			0xbe29db58, 0xbae8d6ef, 0xb7abc036, 0xb36acd81, 0xad2ded84, 0xa9ece033, 0xa4aff6ea, 0xa06efb5d,
			0xd4316d90, 0xd0f06027, 0xddb376fe, 0xd9727b49, 0xc7355b4c, 0xc3f456fb, 0xceb74022, 0xca764d95,
			0xf2390028, 0xf6f80d9f, 0xfbbb1b46, 0xff7a16f1, 0xe13d36f4, 0xe5fc3b43, 0xe8bf2d9a, 0xec7e202d,
			0x34826077, 0x30436dc0, 0x3d007b19, 0x39c176ae, 0x278656ab, 0x23475b1c, 0x2e044dc5, 0x2ac54072,
			0x128a0dcf, 0x164b0078, 0x1b0816a1, 0x1fc91b16, 0x018e3b13, 0x054f36a4, 0x080c207d, 0x0ccd2dca,
			0x7892bb07, 0x7c53b6b0, 0x7110a069, 0x75d1adde, 0x6b968ddb, 0x6f57806c, 0x621496b5, 0x66d59b02,
			0x5e9ad6bf, 0x5a5bdb08, 0x5718cdd1, 0x53d9c066, 0x4d9ee063, 0x495fedd4, 0x441cfb0d, 0x40ddf6ba,
			0xaca3d697, 0xa862db20, 0xa521cdf9, 0xa1e0c04e, 0xbfa7e04b, 0xbb66edfc, 0xb625fb25, 0xb2e4f692,
			0x8aabbb2f, 0x8e6ab698, 0x8329a041, 0x87e8adf6, 0x99af8df3, 0x9d6e8044, 0x902d969d, 0x94ec9b2a,
			0xe0b30de7, 0xe4720050, 0xe9311689, 0xedf01b3e, 0xf3b73b3b, 0xf776368c, 0xfa352055, 0xfef42de2,
			0xc6bb605f, 0xc27a6de8, 0xcf397b31, 0xcbf87686, 0xd5bf5683, 0xd17e5b34, 0xdc3d4ded, 0xd8fc405a,
			0x6904c0ee, 0x6dc5cd59, 0x6086db80, 0x6447d637, 0x7a00f632, 0x7ec1fb85, 0x7382ed5c, 0x7743e0eb,
			0x4f0cad56, 0x4bcda0e1, 0x468eb638, 0x424fbb8f, 0x5c089b8a, 0x58c9963d, 0x558a80e4, 0x514b8d53,
			0x25141b9e, 0x21d51629, 0x2c9600f0, 0x28570d47, 0x36102d42, 0x32d120f5, 0x3f92362c, 0x3b533b9b,
			0x031c7626, 0x07dd7b91, 0x0a9e6d48, 0x0e5f60ff, 0x101840fa, 0x14d94d4d, 0x199a5b94, 0x1d5b5623,
			0xf125760e, 0xf5e47bb9, 0xf8a76d60, 0xfc6660d7, 0xe22140d2, 0xe6e04d65, 0xeba35bbc, 0xef62560b,
			0xd72d1bb6, 0xd3ec1601, 0xdeaf00d8, 0xda6e0d6f, 0xc4292d6a, 0xc0e820dd, 0xcdab3604, 0xc96a3bb3,
			0xbd35ad7e, 0xb9f4a0c9, 0xb4b7b610, 0xb076bba7, 0xae319ba2, 0xaaf09615, 0xa7b380cc, 0xa3728d7b,
			0x9b3dc0c6, 0x9ffccd71, 0x92bfdba8, 0x967ed61f, 0x8839f61a, 0x8cf8fbad, 0x81bbed74, 0x857ae0c3,
			0x5d86a099, 0x5947ad2e, 0x5404bbf7, 0x50c5b640, 0x4e829645, 0x4a439bf2, 0x47008d2b, 0x43c1809c,
			0x7b8ecd21, 0x7f4fc096, 0x720cd64f, 0x76cddbf8, 0x688afbfd, 0x6c4bf64a, 0x6108e093, 0x65c9ed24,
			0x11967be9, 0x1557765e, 0x18146087, 0x1cd56d30, 0x02924d35, 0x06534082, 0x0b10565b, 0x0fd15bec,
			0x379e1651, 0x335f1be6, 0x3e1c0d3f, 0x3add0088, 0x249a208d, 0x205b2d3a, 0x2d183be3, 0x29d93654,
			0xc5a71679, 0xc1661bce, 0xcc250d17, 0xc8e400a0, 0xd6a320a5, 0xd2622d12, 0xdf213bcb, 0xdbe0367c,
			0xe3af7bc1, 0xe76e7676, 0xea2d60af, 0xeeec6d18, 0xf0ab4d1d, 0xf46a40aa, 0xf9295673, 0xfde85bc4,
			0x89b7cd09, 0x8d76c0be, 0x8035d667, 0x84f4dbd0, 0x9ab3fbd5, 0x9e72f662, 0x9331e0bb, 0x97f0ed0c,
			0xafbfa0b1, 0xab7ead06, 0xa63dbbdf, 0xa2fcb668, 0xbcbb966d, 0xb87a9bda, 0xb5398d03, 0xb1f880b4 
	);

open (IN, "<$opt{i}") or die "can't open $filename\n";
#binmode IN;

open (OUT, ">$opt{o}") or die "can't open $filename\n";
#binmode OUT;

#Output header
if($opt{p}){
  syswrite OUT, "PARM";
}elsif($opt{k}){
  syswrite OUT, "KRNL";
}elsif($opt{b}){
  syswrite OUT, "BOOT";
}else{
  usage();
  exit;
}

my $filesize = -s $opt{i};
print "File size: $filesize bytes,";

#Output file length
$b = ($filesize & 0xff);$filesize=$filesize>>8;syswrite OUT, chr($b);
$b = ($filesize & 0xff);$filesize=$filesize>>8;syswrite OUT, chr($b);
$b = ($filesize & 0xff);$filesize=$filesize>>8;syswrite OUT, chr($b);
$b = ($filesize & 0xff);syswrite OUT, chr($b);

$filesize = -s $opt{i};

$bytesread = 0;
$crc = 0;

print " progress :\n";
print chr(27).'[?25l';#Hide cursor
do {
  $buffercnt = sysread (IN, my $buffer, $blksize);
  $bytesread += $buffercnt;
  syswrite OUT, $buffer;
  for(my $i=0;$i<$buffercnt;$i++){
    $crc = ((($crc<<8)&0xffffff00) ^ $t[(($crc>>24)&0xffffff) ^ ord(substr($buffer,$i,1))] ) & 0xffffffff;
  }
  my $p = ($bytesread / $filesize) * 100;
  printf "%-66s %3d %%\r",substr($progbar,0,$p* length($progbar)/100).">>",$p;
}while ($bytesread <$filesize ); 
print chr(27).'[?25h';#Show cursor
print "\n";

#Output crc
$b = ($crc & 0xff);$crc=$crc>>8;syswrite OUT, chr($b);
$b = ($crc & 0xff);$crc=$crc>>8;syswrite OUT, chr($b);
$b = ($crc & 0xff);$crc=$crc>>8;syswrite OUT, chr($b);
$b = ($crc & 0xff);syswrite OUT, chr($b);

close IN;
close OUT;

exit;
