# predict the gender of a name by combining datasets from multiple countries (in this case, the UK ONS, the UK NRS, the US SSA, and Alberta)

use strict;
use warnings;

# REQUIREMENTS
my $in_file1 = 'gender_breakdown_per_year_of_names_in_US_SSA.txt'; # from 1a.predict_gender_of_name_using_USA_SSA.pl
my $in_file2 = 'gender_breakdown_per_year_of_names_in_UK_ONS.txt'; # from 1b.predict_gender_of_name_using_UK_ONS.pl
my $in_file3 = 'gender_breakdown_per_year_of_names_in_UK_NRS.txt'; # from 1c.predict_gender_of_name_using_UK_NRS.pl
my $in_file4 = 'gender_breakdown_per_year_of_names_in_Canada_Alberta.txt'; # from 1d.predict_gender_of_name_using_Canada_Alberta.pl
if (!(-e($in_file1))) { print "ERROR: unable to find $in_file1\n"; exit 1; }
if (!(-e($in_file2))) { print "ERROR: unable to find $in_file2\n"; exit 1; }
if (!(-e($in_file3))) { print "ERROR: unable to find $in_file3\n"; exit 1; }
if (!(-e($in_file4))) { print "ERROR: unable to find $in_file4\n"; exit 1; }

# OUTPUT
my $out_file1 = 'gender_breakdown_per_year_of_names_using_merged_dataset.txt';
my $out_file2 = 'gender_prediction_of_names_using_merged_dataset.txt';
open(OUT1,'>',$out_file1) or die $!; open(OUT2,'>',$out_file2) or die $!;
print OUT1 "name\tyear\ttotal\tnum_female\tnum_male\tproportion_female\tproportion_male\tpredicted_gender\n";
print OUT2 "name\tgender\ttotal\tproportion_of_total_female\tproportion_of_total_male\n";

# STORE THE NUMBER OF GENDERED INSTANCES OF EACH NAME
my %names = (); my %years = ();
my %female = (); my %male = ();
for(my $x=0;$x<=3;$x++)
	{ #next if ($x == 2); # NOTE: we are only going to combine data from USA and UK ONS for now
	  my $in_file = '';
	  if 	($x == 0) { $in_file = $in_file1; }
	  elsif ($x == 1) { $in_file = $in_file2; }
	  elsif ($x == 2) { $in_file = $in_file3; }
	  elsif ($x == 3) { $in_file = $in_file4; }
	  open(IN,$in_file) or die $!;
	  while(<IN>)
		{ next if ($. == 1);
		  my $line = $_; chomp($line);
		  my @line = split(/\t/,$line);
		  my $name = $line[0]; my $year = $line[1]; my $num_female = $line[3]; my $num_male = $line[4];
		  next if ($year =~ /total/);
	      $name = uc($name);
		  $names{$name}++;
		  $years{$year}++;
		  $male{$name}{$year}   += $num_male;
		  $female{$name}{$year} += $num_female;
		}
	  close(IN) or die $!;
	}

# PRINT THE GENDER BREAKDOWN, PER YEAR, OF EACH NAME, ALONG WITH A SUMMARY ACROSS ALL YEARS
my @names = ();
while((my $name,my $irrel)=each(%names))
	{ push(@names,$name); }
my @sorted_names = sort {$a cmp $b} @names;
my @years = ();
while((my $year,my $irrel)=each(%years))
	{ push(@years,$year); }
my @sorted_years = sort {$a <=> $b} @years;
my %predictions_per_year = (); my %genders_based_on_grand_total = ();
foreach my $name (@sorted_names)
	{ my $all_years_f = 0; my $all_years_m = 0;
	  
	  # print a summary of the gender breakdown of this name for each year
	  foreach my $year (@sorted_years)
		{ my $no_f = 0; my $no_m = 0;
		  if (exists($female{$name}{$year})) { $no_f = $female{$name}{$year}; }
		  if (exists($male{$name}{$year}))   { $no_m = $male{$name}{$year};   }
		  my $total  = $no_f+$no_m;
		  next if ($total == 0); # CHECKPOINT: this name does not feature in this year
		  my $frac_f = sprintf("%.3f",($no_f/$total));
		  my $frac_m = sprintf("%.3f",($no_m/$total));
		  my $gender = 'undetermined';
		  if 	($frac_f > $frac_m) { $gender = 'female'; }
		  elsif ($frac_m > $frac_f) { $gender = 'male';   }
		  print OUT1 "$name\t$year\t$total\t$no_f\t$no_m\t$frac_f\t$frac_m\t$gender\n";
		  $all_years_f += $no_f; $all_years_m += $no_m;
		  $predictions_per_year{$name}{$gender}++;
		}
	  
	  # print a summary of the gender breakdown of this name over all years
	  my $grand_total = $all_years_f+$all_years_m;
	  next if ($grand_total == 0); # CHECKPOINT: this name does not feature at all (this checkpoint is a sanity test and should never be triggered)
	  my $all_years_frac_f = sprintf("%.3f",($all_years_f/($all_years_f+$all_years_m)));
	  my $all_years_frac_m = sprintf("%.3f",($all_years_m/($all_years_f+$all_years_m)));
	  my $gender = 'undetermined';
	  if 	($all_years_frac_f > $all_years_frac_m) { $gender = 'female'; }
	  elsif ($all_years_frac_m > $all_years_frac_f) { $gender = 'male';   }
	  print OUT1 "$name\ttotal\t$grand_total\t$all_years_f\t$all_years_m\t$all_years_frac_f\t$all_years_frac_m\t$gender\n";
	  $genders_based_on_grand_total{$name}{gender} 	  = $gender;
	  $genders_based_on_grand_total{$name}{total} 	  = $grand_total;
	  $genders_based_on_grand_total{$name}{proporp_f} = $all_years_frac_f;
	  $genders_based_on_grand_total{$name}{proporp_m} = $all_years_frac_m;
	}
close(OUT1) or die $!;

# SUMMARISE THE DATA: FOR EACH NAME, IS IT GENDERED AS MALE, FEMALE, MOSTLY MALE, MOSTLY FEMALE, OR UNDETERMINED?
# "MALE" AND "FEMALE" NAMES ARE THOSE WHERE FOR EVERY YEAR IN WHICH THAT NAME IS RECORDED, THE MAJORITY OF RECORDS ARE THAT GENDER. IN THIS RESPECT, THE GENDER IDENTITY OF THAT NAME IS "TIMELESS".
# "MOSTLY X" NAMES, SUCH AS MADISON AND LESLIE, ARE THOSE WHERE THERE IS NO CONSISTENT MAJORITY GENDER: ACROSS THE COURSE OF THEIR HISTORY, THEY'VE FLIPPED THEIR ASSOCIATED GENDER. THE "MOSTLY" REFERS TO WHAT GENDER ASSOCIATION THEY ARE MORE LIKELY TO HAVE TODAY (BECAUSE THE NUMBER OF RECORDS INCREASES EACH YEAR).
# NOTE THAT THIS IS A POPULATION-LEVEL CLASSIFICATION OF THE GENDER OF EACH NAME AND THAT INDIVIDUAL USAGE MAY DIFFER.
foreach my $name (@sorted_names)
	{ my $gender = '';
	  if ( (exists($predictions_per_year{$name}{'male'})) and (!(exists($predictions_per_year{$name}{'female'}))) ) { $gender = 'male';   }
	  if ( (exists($predictions_per_year{$name}{'female'})) and (!(exists($predictions_per_year{$name}{'male'}))) ) { $gender = 'female'; }
	  if ( (exists($predictions_per_year{$name}{'male'})) and (exists($predictions_per_year{$name}{'female'})) )
		{ my $gender_based_on_grand_total = $genders_based_on_grand_total{$name}{gender};
		  if (($gender_based_on_grand_total eq 'male') or ($gender_based_on_grand_total eq 'female'))
			{ $gender = "mostly $gender_based_on_grand_total"; }
		}
	  if ($gender eq '') { $gender = 'undetermined'; }
	  print OUT2 "$name\t$gender\t$genders_based_on_grand_total{$name}{total}\t$genders_based_on_grand_total{$name}{proporp_f}\t$genders_based_on_grand_total{$name}{proporp_m}\n";
	}
close(OUT2) or die $!;
exit 1;