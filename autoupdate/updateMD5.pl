#!/usr/bin/perl
#
# update MD5 fingerprint
# usage: put a title="MD5:" entry in any html.
#
# Author: Hung-Te Lin <piaip@csie.ntu.edu.tw>
#

my $chkroot = 'dls';

foreach(@ARGV) {
  print "MD5 update: $_\n";
  open INF, "<$_";
  my @src = <INF>;
  close INF;

  open OUTF, ">$_";
  foreach (@src) {
    if ($_ =~ /MD5:\s*([^'"]*)['"].*href=['"]\/?($chkroot[^'"]*)['"]/i) {
      if (-r $2) {
        open EMD5, "/usr/bin/md5sum '$2'|";
        my @md5 = <EMD5>;
        close EMD5;
        my $md5 = join('', @md5);
        $md5 =~ s/\s//g;
        $_ =~ s/MD5:\s*([^'"]*)(['"])/MD5: $md5$2/;
      } else {
        print "No such file: $2 \n";
      }
    }
    print OUTF $_;
  }
  close OUTF;
}
print "\nDone MD5 update\n";
