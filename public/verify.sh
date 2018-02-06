#!/usr/bin/env perl

use strict;
my $gopsize = shift(@ARGV);
my $file = shift(@ARGV);
print "GOPSIZE = $gopsize\n";
my $linenum = 0;
my $expected = 0;
open my $pipe, "ffprobe -i $file -select_streams v -show_frames -of csv -show_entries frame=pict_type |"
        or die "Blah";
while (<$pipe>) {
  if ($linenum > $expected) {
    # Won't catch all the misses. But even one is good enough to fail.
    print "Missed IFrame at $expected\n";
    $expected = (int($linenum/$gopsize) + 1)*$gopsize;
  }
  if (m/,I\s*$/) {
    if ($linenum < $expected) {
      # Don't care term, just an extra I frame. Snore.
      #print "Free IFrame at $linenum\n";
    } else {
      #print "IFrame HIT at $expected\n";
      $expected += $gopsize;
    }
  }
  $linenum += 1;
}