#!/usr/local/bin/perl 

require 'getopts.pl';

undef($opt_t);
undef($opt_m);

Getopts("mt:");

if( !defined($ARGV[0]) ) {
	print "Usage: $0 [-t Threshold in MB] Directory Directory . . .\n";
	exit(1);
}

my $total = 0;

for $dir (@ARGV) {
	chomp($dir);
	if( ! -d "$dir" ) {
		print "WARNING: $dir not a directory. Skipping...\n";
		next;
	}
	@list = `ls -a -1 $dir`;
	for $file (@list) {
		chomp($file);
		#print "Finding size of $dir/$file: ";
		chomp($file);
		next if($file !~ /\S+/ );
		next if( $file eq ".." );
		next if( $file eq "." );
		next if( $file eq ".snapshot" );
		chomp($output = `du -sk $dir/$file 2>/dev/null`);
		next if($? != 0);
		($size) = split(/\s+/,$output);
		$size/=1024;
		printf("$dir/$file	%f MB\n",$size);
		$total += $size;
	}
	if( (defined($opt_t)) && ($total > $opt_t) ) {
		print "Quota Exeeded: ";
		$VIOLATED{$dir} = $total;
	}
	printf("Total size of directory %s excluding snapshots is: %f MB\n",$dir,$total);
}

if( defined($opt_t) ) {
	$str = "\n\nList of directories exceeding the quota of $opt_t MB\n";
	$str .= "----------------------------------------------------\n\n";
	for $dir (keys %VIOLATED) {
		chomp($dir);
		$str .= sprintf("%-25s %s MB\n",$dir,$VIOLATED{$dir});
	}
	print "$str\n";
}

if(defined($opt_m)) {
	print "----------------------------------------------------\n\n";
	print "Sending mail to $ENV{USER}...\n";
	`echo "$str" | /usr/bin/mailx -s "Quota report" $ENV{USER}`;
}
