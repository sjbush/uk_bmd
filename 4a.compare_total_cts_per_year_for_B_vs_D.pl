=head

AFTER USAGE:

library(ggplot2)
library(scales)

# plot the % name use in the B vs. D dataset

df<-read.table('C:/Users/User/Desktop/bmd_as_resource/total_counts_per_year_for_names_in_B_and_D.txt',sep='\t',quote='',header=T)
fig2 <- ggplot() + geom_point(data = df, aes(x = Total.B, y = Total.D), size = 0.7) + xlab('Total count per name (birth records)') + ylab('Total count per name (death records)') + theme_bw() + scale_x_log10(limits=c(1,1000000),breaks=c(1,10,100,1000,10000,100000,1000000),labels=c(1,10,100,1000,"10,000","100,000","1,000,000")) + scale_y_log10(limits=c(1,1000000),breaks=c(1,10,100,1000,10000,100000,1000000),labels=c(1,10,100,1000,"10,000","100,000","1,000,000"))
ggsave(file = 'C:/Users/User/Desktop/bmd_as_resource/Documents/Figure2.jpeg', plot = fig2, width = 7, height = 7)

cor.test(df$Total.B,df$Total.D,method=c('pearson'))

=cut

use strict;
use warnings;

# REQUIREMENTS
my $in_file1 = 'dataset_B/name_frequencies_summed_across_all_years.txt'; # from 3a.parse_birth_records.pl
my $in_file2 = 'dataset_D/name_frequencies_summed_across_all_years.txt'; # from 3b.parse_death_records.pl
if (!(-e($in_file1))) { print "ERROR: cannot find $in_file1\n"; exit 1; }
if (!(-e($in_file2))) { print "ERROR: cannot find $in_file2\n"; exit 1; }

# OUTPUT
my $out_file = 'total_counts_per_year_for_names_in_B_and_D.txt';
open(OUT,'>',$out_file) or die $!;
print OUT "Name\tTotal B\t% B\tTotal D\t% D\n";

my %totals = (); my %grand_total = ();
for(my $x=0;$x<=1;$x++)
	{ my $in_file = ''; my $type = '';
	  if ($x == 0) { $in_file = $in_file1; $type = 'B'; } elsif ($x == 1) { $in_file = $in_file2; $type = 'D'; }
	  open(IN,$in_file) or die $!;
	  while(<IN>)
		{ next if ($. == 1);
		  my $line = $_; chomp($line);
		  my @line = split(/\t/,$line);
		  my $name = $line[0]; my $total = $line[2]; # note that this is the total number of times the name is used as a forename
		  next if ($total == 0);
		  $totals{$name}{$type} += $total;
		  $grand_total{$type} += $total;
		}
	  close(IN) or die $!;
	}

my @names = ();
while((my $name,my $irrel)=each(%totals))
	{ push(@names,$name); }
my @sorted_names = sort {$a cmp $b} @names;
foreach my $name (@sorted_names)
	{ my $num_B = 0; if (exists($totals{$name}{'B'})) { $num_B = $totals{$name}{'B'}; }
	  my $num_D = 0; if (exists($totals{$name}{'D'})) { $num_D = $totals{$name}{'D'}; }
	  my $pct_B = ($num_B/$grand_total{'B'})*100;
	  my $pct_D = ($num_D/$grand_total{'D'})*100;
	  print OUT "$name\t$num_B\t$pct_B\t$num_D\t$pct_D\n";
	}

close(OUT) or die $!;
exit 1;
