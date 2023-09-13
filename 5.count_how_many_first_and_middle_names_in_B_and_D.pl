# PURPOSE: how many different first names and middle names are there in the B and D datasets and how many are unique to either?

use strict;
use warnings;

# REQUIREMENTS
my $in_file1 = 'dataset_B/name_frequencies_summed_across_all_years.txt'; # from 3a.parse_birth_records.pl
my $in_file2 = 'dataset_D/name_frequencies_summed_across_all_years.txt'; # from 3b.parse_death_records.pl
if (!(-e($in_file1))) { print "ERROR: cannot find $in_file1\n"; exit 1; }
if (!(-e($in_file2))) { print "ERROR: cannot find $in_file2\n"; exit 1; }

# COUNT NUMBER OF NAMES IN THE B AND D DATASET
my %names = (); my %all_names = ();
for(my $x=0;$x<=1;$x++)
	{ my $in_file = ''; my $type = '';
	  if ($x == 0) { $in_file = $in_file1; $type = 'B'; } elsif ($x == 1) { $in_file = $in_file2; $type = 'D'; }
	  open(IN,$in_file) or die $!;
	  while(<IN>)
		{ next if ($. == 1);
		  my $line = $_; chomp($line);
		  my @line = split(/\t/,$line);
		  my $name = $line[0]; my $no_times_forename = $line[2]; my $no_times_middle_name = $line[3];
		  if ($no_times_forename > 0)
			{ $names{$type}{'first'}{$name}++; }
		  if ($no_times_middle_name > 0)
			{ $names{$type}{'middle'}{$name}++; }
		  
		  if (($no_times_forename > 0) or ($no_times_middle_name > 0))
			{ if ($no_times_forename    > 0) { $all_names{$name}{'first'}++;  }
			  if ($no_times_middle_name > 0) { $all_names{$name}{'middle'}++; }
			}
		}
	  close(IN) or die $!;
	}

my $no_first_names_B  = scalar keys %{$names{'B'}{'first'}};
my $no_first_names_D  = scalar keys %{$names{'D'}{'first'}};
my $no_middle_names_B = scalar keys %{$names{'B'}{'middle'}};
my $no_middle_names_D = scalar keys %{$names{'D'}{'middle'}};
my $no_names_in_total = scalar keys %all_names;
my $no_first_only_in_B = 0; my $no_first_only_in_D = 0;
while((my $name,my $irrel)=each(%all_names))
	{ if ( (exists($names{'B'}{'first'}{$name})) and (!(exists($names{'D'}{'first'}{$name}))) ) { $no_first_only_in_B++; }
	  if ( (exists($names{'D'}{'first'}{$name})) and (!(exists($names{'B'}{'first'}{$name}))) ) { $no_first_only_in_D++; print "$name\n"; }
	}
my $no_middle_only_in_B = 0; my $no_middle_only_in_D = 0;
while((my $name,my $irrel)=each(%all_names))
	{ if ( (exists($names{'B'}{'middle'}{$name})) and (!(exists($names{'D'}{'middle'}{$name}))) ) { $no_middle_only_in_B++; }
	  if ( (exists($names{'D'}{'middle'}{$name})) and (!(exists($names{'B'}{'middle'}{$name}))) ) { $no_middle_only_in_D++; }
	}

print "total no. names: $no_names_in_total\n";
print "no. first names: $no_first_names_B (B), $no_first_names_D (D)\n";
print "no. middle names: $no_middle_names_B (B), $no_middle_names_D (D)\n";
print "no. first names that are only found in B: $no_first_only_in_B\n";
print "no. first names that are only found in D: $no_first_only_in_D\n";
print "no. middle names that are only found in B: $no_middle_only_in_B\n";
print "no. middle names that are only found in D: $no_middle_only_in_D\n";

exit 1;