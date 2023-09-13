=head

PURPOSE: we wish to compare the total counts per name in the B dataset vs. the ONS dataset. This analysis is restricted to the years the two have a meaningful number of records in common, 1996-2007 (as dataset B has >10,000 records per year for each of these years).
It was not possible to compare the D with the ONS dataset as dataset D only contains 688 records in the period 1996-2009.

AFTER USAGE:

library(ggplot2)
library(scales)

# plot the % name use in the B vs. UK ONS dataset

df<-read.table('C:/Users/sbush/Desktop/bmd_as_resource/total_counts_per_year_for_names_in_B_and_ONS.txt',sep='\t',quote='',header=T)
fig3 <- ggplot() + geom_point(data = df, aes(x = Total.B, y = Total.ONS)) + xlab('Total count per name (birth records)') + ylab('Total count per name (UK ONS)') + theme_bw() + scale_x_continuous(labels = scientific) + scale_y_continuous(labels = scientific)
cor.test(df$Total.B,df$Total.ONS,method=c('pearson'))

=cut

use strict;
use warnings;

# REQUIREMENTS
my $in_file1 = 'uk_ons/1996-2016.txt'; # manually created using data accurate as of 14th June 2023. From https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/livebirths/bulletins/babynamesenglandandwales/2021/relateddata
my $in_file2 = 'uk_ons/2017-2021.txt'; # as above. Manually created using data accurate as of 14th June 2023 - but note a change in formatting conventions between these years and previous years
my $in_file3 = 'dataset_B/first_name_as_absolute_number_of_records_per_year.txt'; # from 3a.parse_birth_records.pl
if (!(-e($in_file1))) { print "ERROR: cannot find $in_file1\n"; exit 1; }
if (!(-e($in_file2))) { print "ERROR: cannot find $in_file2\n"; exit 1; }
if (!(-e($in_file3))) { print "ERROR: cannot find $in_file3\n"; exit 1; }

# OUTPUT
my $out_file = 'total_counts_per_year_for_names_in_B_and_ONS.txt';
open(OUT,'>',$out_file) or die $!;
print OUT "Name\tTotal B\tTotal ONS\n";

# PARSE THE ONS DATA TO COUNT THE TOTAL NUMBER OF TIMES EACH NAME IS USED
my %totals = (); my %headers = ();
open(IN,$in_file1) or die $!;
while(<IN>)
	{ my $line = $_; chomp($line);
	  my @line = split(/\t/,$line); $line =~ s/[\r\n]//g;
	  if ($. == 1)
		{ for(my $x=2;$x<@line;$x++)
			{ my $year = $line[$x];
			  $headers{$x} = $year;
			}
		}
	  next if ($. == 1);
	  my $name = $line[0];
	  $name =~ s/^\s+//; $name =~ s/\s+$//;
	  $name = uc($name);
	  for(my $x=2;$x<@line;$x++)
		{ my $year  = $headers{$x};
		  my $count = $line[$x];
		  next if (($year < 1996) or ($year > 2007));
		  $totals{$name}{'ONS'} += $count;
		}
	}
close(IN) or die $!;
open(IN,$in_file2) or die $!;
while(<IN>)
	{ next if ($. == 1);
	  my $line = $_; chomp($line); $line =~ s/[\r\n]//g;
	  my @line = split(/\t/,$line);
	  my $name = $line[0]; my $count = $line[2]; my $year = $line[3];
	  $name =~ s/^\s+//; $name =~ s/\s+$//;
	  $name = uc($name);
	  next if (($year < 1996) or ($year > 2007));
	  $totals{$name}{'ONS'} += $count;
	}
close(IN) or die $!;

# PARSE THE B DATASET TO COUNT THE TOTAL NUMBER OF TIMES EACH NAME IS USED
%headers = ();
open(IN,$in_file3) or die $!;
while(<IN>)
	{ my $line = $_; chomp($line);
	  my @line = split(/\t/,$line); $line =~ s/[\r\n]//g;
	  if ($. == 1)
		{ for(my $x=24;$x<@line;$x++)
			{ my $year = $line[$x];
			  $headers{$x} = $year;
			}
		}
	  next if ($. == 1);
	  my $name = $line[0];
	  $name =~ s/^\s+//; $name =~ s/\s+$//;
	  $name = uc($name);
	  for(my $x=24;$x<@line;$x++)
		{ my $year  = $headers{$x};
		  my $count = $line[$x];
		  next if (($year < 1996) or ($year > 2007));
		  $totals{$name}{'B'} += $count;
		}
	}
close(IN) or die $!;

my @names = ();
while((my $name,my $irrel)=each(%totals))
	{ push(@names,$name); }
my @sorted_names = sort {$a cmp $b} @names;
foreach my $name (@sorted_names)
	{ my $num_B   = 0; if (exists($totals{$name}{'B'}))   { $num_B   = $totals{$name}{'B'};   }
	  my $num_ONS = 0; if (exists($totals{$name}{'ONS'})) { $num_ONS = $totals{$name}{'ONS'}; }
	  print OUT "$name\t$num_B\t$num_ONS\n";
	}

close(OUT) or die $!;
exit 1;