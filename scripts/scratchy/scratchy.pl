#!/usr/bin/perl -w

# ~/bin/contrived_perldb_demo         Fri Oct 20 19:02:56 2000

# Expected behavior: the variable "positive_guy" will
#   (1) increase all the time.
#   (2) will always be positive.
# (But there are bugs, and we'll use breakpoints and
# watchexpressions to track them down.)

use strict;
use vars qw($positive_guy $count $real_negative);

$positive_guy = 1; $count = 0;

while($count < 200) {
   $count++;
   $positive_guy++;
   dostuff();
   $positive_guy = jackitup($positive_guy);
   dostuff();
   $real_negative = evil_routine(\$positive_guy);
   dostuff();
}
print "Real negative should be down now: $real_negative\n";

sub dostuff {
   # doesn't really do much of anything
   print "The count is $count, and positive_guy is $positive_guy\n";
   1;
}

sub jackitup {
   my $n = shift;
   my $factor = 2;
   $n = $n/$factor;  # increase number by $factor
   return $n;
}

sub evil_routine {
   # sends $positive_guy negative, eventually
   my $pgr = shift;
   if ($count>100) {
      ${$pgr} = -100;
   }
   return ${$pgr};
}
