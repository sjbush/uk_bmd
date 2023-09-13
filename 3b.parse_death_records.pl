=head

AFTER USAGE:

library(ggplot2)

# plot the total number of B and D records per year

df_b<-read.table('C:/Users/sbush/Desktop/bmd_as_resource/dataset_B/summary_of_records_per_year.txt',sep='\t',quote='',header=T)
df_d<-read.table('C:/Users/sbush/Desktop/bmd_as_resource/dataset_D/summary_of_records_per_year.txt',sep='\t',quote='',header=T)
fig1 <- ggplot() + geom_line(data = df_b, aes(x = Year, y = No..of.records.with.a.forename), size = 0.8, linetype = 'solid') + geom_line(data = df_d, aes(x = Year, y = No..of.records.with.a.forename), size = 0.8, linetype = 'dashed') + xlab('Year') + ylab('No. of records') + scale_x_continuous(limits=c(1730,2020)) + theme_bw()

# plot the gender ratio of death records per year

df<-read.table('C:/Users/sbush/Desktop/bmd_as_resource/dataset_D/summary_of_records_per_year.txt',sep='\t',quote='',header=T)
df.sub<-subset(df,df$No..of.records.with.a.forename > 1000)
df<-df.sub
fig4b <- ggplot() + geom_line(data = df, aes(x = Year, y = Gender.ratio.of..male.mostly.male...female...mostly.female..forename.records), size = 0.8) + xlab('Year') + ylab('Ratio of male to female death records') + scale_x_continuous(limits=c(1730,2020)) + scale_y_continuous(limits=c(0.7,1.7)) + theme_bw()

# plot the % of death records with a forename of undetermined gender

df<-read.table('C:/Users/sbush/Desktop/bmd_as_resource/dataset_D/summary_of_records_per_year.txt',sep='\t',quote='',header=T)
fig5b <- ggplot() + geom_line(data = df, aes(x = Year, y = X..of.records.with.a.gender.undetermined.forename), size = 0.8) + xlab('Year') + ylab('% of death records with a gender-undetermined forename') + scale_x_continuous(limits=c(1830,2020)) + theme_bw()

=cut

use strict;
use warnings;
use Acme::Tools qw(avg median sum);
use Unicode::Normalize;

# REQUIREMENTS
my $in_dir = 'BMD-08.06.23/D'; # manually downloaded
my $gender = 'gender_prediction_of_names_using_merged_dataset.txt'; # from 2.predict_gender_of_name_by_combining_datasets.pl
if (!(-d($in_dir))) { print "ERROR: cannot find $in_dir\n"; exit 1; }
if (!(-e($gender))) { print "ERROR: cannot find $gender\n"; exit 1; }

# PARAMETERS
my $min_records = 1000;
my $min_consecutive_years = 50;
my $abandon_frac = 0.1;  my $abandon_pc = $abandon_frac*100;
my $revival_frac = 0.25; my $revival_pc = $revival_frac*100;
my $years_between_abandonment_and_revival = 5;

# OUTPUT
my $out_dir = 'dataset_D';
if (!(-d($out_dir))) { mkdir $out_dir or die $!; }
my $out_summary			= "$out_dir/summary_of_records_per_region.txt";
my $out_per_year		= "$out_dir/summary_of_records_per_year.txt";
my $out_all_first		= "$out_dir/all_first_names.txt";
my $out_all_middle		= "$out_dir/all_middle_names.txt";
my $out_all_first_midl  = "$out_dir/all_first_and_middle_names.txt";
my $out_all_full 		= "$out_dir/all_full_names.txt";
my $out_pct_first	 	= "$out_dir/first_name_as_percentage_of_records_per_year.txt";
my $out_abs_first	    = "$out_dir/first_name_as_absolute_number_of_records_per_year.txt";
my $out_pct_middle	    = "$out_dir/middle_name_as_percentage_of_records_per_year.txt";
my $out_abs_middle		= "$out_dir/middle_name_as_absolute_number_of_records_per_year.txt";
my $out_total_name_freq = "$out_dir/name_frequencies_summed_across_all_years.txt";
open(SUMMARY,'>',$out_summary) or die $!; open(SUMMARY_PER_YEAR,'>',$out_per_year) or die $!;
open(OUT_ALL_FIRST,'>',$out_all_first) or die $!; open(OUT_ALL_MIDDLE,'>',$out_all_middle) or die $!; open(OUT_ALL_FIRST_MIDL,'>',$out_all_first_midl) or die $!; open(OUT_ALL_FULL,'>',$out_all_full) or die $!;
open(OUT_TOTAL_NAME_FREQ,'>',$out_total_name_freq) or die $!;
open(OUT_PCT_FIRST,'>',$out_pct_first) or die $!; open(OUT_ABS_FIRST,'>',$out_abs_first) or die $!;
open(OUT_PCT_MIDDLE,'>',$out_pct_middle) or die $!; open(OUT_ABS_MIDDLE,'>',$out_abs_middle) or die $!;
print SUMMARY_PER_YEAR 	  "Year\tNo. of records with a forename\tNo. of male/mostly male forename records\tNo. of female/mostly female forename records\tNo. of gender-undetermined forename records\t% of records with a male/mostly male forename\t% of records with a female/mostly female forename\t% of records with a gender-undetermined forename\tGender ratio of (male+mostly male)/(female + mostly female) forename records\tNo. of records with a middle name\tAvg. no. of middle names per record (for records with >=1 middle name)\t";
print SUMMARY_PER_YEAR 	  "No. of different forenames seen\tForename diversity (i.e., ratio of the no. of different forenames to the total no. of records per year)\t% of this year's forenames not used in the previous year\t";
print SUMMARY_PER_YEAR 	  "Most popular forename (% of records)\tSecond most popular forename (% of records)\tThird most popular forename (% of records)\tFourth most popular forename (% of records)\tFifth most popular forename (% of records)\t";
print SUMMARY_PER_YEAR 	  "Most popular middle name (% of records)\tSecond most popular middle name (% of records)\tThird most popular middle name (% of records)\tFourth most popular middle name (% of records)\tFifth most popular middle name (% of records)\n";
print SUMMARY 		   	  "Region\tURL\tDate that the local BMD records obtained for this study were last updated\tNo. of subdistricts in region\tSubdistricts in region\tNo. of records\tNo. of records with 1 or more middle names\tYears covered\n";
print OUT_ALL_FIRST    	  "First name\tGender\tTotal no. of records with this first name\t% of total\n";
print OUT_ALL_MIDDLE   	  "Middle name\tGender\tTotal no. of records with this middle name\t% of total\n";
print OUT_ALL_FIRST_MIDL  "First name and middle name(s)\tNo. of middle names\tTotal no. of records with this first and middle name(s)\t% of total\tGender of first name\tGender of middle name(s)\n";
print OUT_ALL_FULL 		  "Full name\tYear\tTotal no. of records with this full name in this year\n";
print OUT_TOTAL_NAME_FREQ "Name\tGender\tNo. of occurrences as a forename\tNo. of occurrences as a middle name\tNo. of occurrences as a surname\tRatio of number of times this occurs as a surname to the number of times this occurs as a forename\tNo. of years in which this is used either as a forename or middle name\tYears in which this is used either as a forename or middle name\n";

# STORE THE GENDER ASSOCIATED WITH EACH NAME
my %genders = ();
open(IN,$gender) or die $!;
while(<IN>)
	{ my $line = $_; chomp($line); $line =~ s/[\r\n]//g;
	  my @line = split(/\t/,$line);
	  my $name = $line[0]; my $gender = $line[1];
	  $genders{$name} = $gender;
	}
close(IN) or die $!;

# STORE FREQUENCY OF NAMES PER YEAR, IN BOTH ABSOLUTE AND RELATIVE TERMS, FROM THE DEATH RECORDS
my %records_per_year = ();
my %forenames = (); my %f_forenames = (); my %m_forenames = ();
my %middle_names = (); my %f_middle_names = (); my %m_middle_names = ();
my %first_and_middle_names = (); my %surnames = (); my %full_names = ();
my %forenames_data = (); my %middle_names_data = ();
my %years_in_which_forename_used = (); my %years_in_which_middle_name_used = ();
my %number_of_records_with_a_middle_name_per_year = ();
my %average_number_of_middle_names_per_record = ();
my %records_per_region = (); my %subdistricts_in_region = ();
opendir(DIR,$in_dir) or die $!;
my @regions = readdir(DIR);
closedir(DIR) or die $!;
my @sorted_regions = sort {$a cmp $b} @regions;
foreach my $region (@sorted_regions)
	{ next if (($region eq '.') or ($region eq '..'));
#	  next if ($region ne 'Bath');
	  print "deaths: $region...\n";
	  my $url; my $date_of_last_update; # this is the date of the last update of the DEATH records, specifically
	  if    ($region eq 'Bath') 	  	 { $url = 'www.bathbmd.org.uk'; 	     $date_of_last_update = '22nd August 2007';    }
	  elsif ($region eq 'Berkshire')  	 { $url = 'www.berkshirebmd.org.uk';     $date_of_last_update = '7th April 2011';      }
	  elsif ($region eq 'Cheshire')   	 { $url = 'www.cheshirebmd.org.uk';      $date_of_last_update = '24th April 2017';     }	  
	  elsif ($region eq 'Cumbria') 	  	 { $url = 'www.cumbriabmd.org.uk';       $date_of_last_update = '5th February 2011';   }
	  elsif ($region eq 'Kingston') 	 { $url = 'www.kingstonbmd.org.uk/'; 	 $date_of_last_update = '29th December 2022';  }	  
	  elsif ($region eq 'Lancashire') 	 { $url = 'www.lancashirebmd.org.uk'; 	 $date_of_last_update = '8th June 2023';       }
	  elsif ($region eq 'North_Wales') 	 { $url = 'www.northwalesbmd.org.uk'; 	 $date_of_last_update = '22th July 2012'; 	   }
	  elsif ($region eq 'Shropshire') 	 { $url = 'www.shropshirebmd.info'; 	 $date_of_last_update = '25th September 2020'; }
	  elsif ($region eq 'Staffordshire') { $url = 'www.staffordshirebmd.org.uk'; $date_of_last_update = '7th October 2022';    }
	  elsif ($region eq 'West_Midlands') { $url = 'www.westmidlandsbmd.org.uk';  $date_of_last_update = '16th May 2016'; 	   }
	  elsif ($region eq 'Wiltshire') 	 { $url = 'www.wiltshirebmd.org.uk'; 	 $date_of_last_update = '20th April 2018';     }
	  elsif ($region eq 'Yorkshire') 	 { $url = 'www.yorkshirebmd.org.uk'; 	 $date_of_last_update = '4th June 2015';       }
	  next if (!(-d("$in_dir/$region")));
	  opendir(DIR,"$in_dir/$region") or die $!;
	  my @years = readdir(DIR);
	  closedir(DIR) or die $!;
	  
	  # let's first count how many records there are per reference number
	  # WARNING: for some regions (Bath, Cumbria, Shropshire, West Midlands, Wiltshire, Yorkshire), records have a unique reference number but for other regions (Berkshire, Cheshire, Kingston, Lancashire, North Wales, Staffordshire) multiple different records can share the same reference. In this case, the reference number refers to a batch of records, often (but not always) around five at a time.
	  # to avoid overcounting, we'll later require that there is only one reference number per record
	  # duplicates reflect variants of the same name, e.g. in Shropshire in 1997, there are five records with the reference B-SHR-SHR/C73A/2: Tyler V D KAMP, Tyler V Der KAMP, Tyler Van D KAMP, Tyler Van Der KAMP, Tyler VANDERKAMP
	  # if we counted all of them equally, we would falsely inflate the popularity of Tyler
	  my %ref_nums = ();
	  foreach my $year (@years)
		{ next if (($year eq '.') or ($year eq '..'));
		  opendir(DIR,"$in_dir/$region/$year") or die $!;
		  my @files = readdir(DIR);
		  closedir(DIR) or die $!;
		  foreach my $file (@files)
			{ next if (($file eq '.') or ($file eq '..'));	  
			  open(IN,"$in_dir/$region/$year/$file") or die $!;
			  while(<IN>)
				{ next if ($. == 1);
				  my $line = $_; chomp($line); $line =~ s/[\r\n]//g;
				  next if ($line !~ /\"/);
				  my @line = split(/\,/,$line);
				  my $reference = $line[$#line]; $reference =~ s/\"//g;
				  $ref_nums{$region}{$reference}{$line}++;
				}
			  close(IN) or die $!;
			}
		}
	  
	  # to see how many records share the same reference number, dump this hash
#	  use Data::Dumper;
#	  open(DUMP,'>','records_per_ref_num.pl') or die $!;
#	  print DUMP Dumper (\%ref_nums);
#	  close(DUMP) or die $!;
		
	  foreach my $year (@years)
		{ next if (($year eq '.') or ($year eq '..'));
		  opendir(DIR,"$in_dir/$region/$year") or die $!;
		  my @files = readdir(DIR);
		  closedir(DIR) or die $!;
		  foreach my $file (@files)
			{ next if (($file eq '.') or ($file eq '..'));	  
			  open(IN,"$in_dir/$region/$year/$file") or die $!;
			  while(<IN>)
				{ next if ($. == 1);
				  my $line = $_; chomp($line); $line =~ s/[\r\n]//g;
				  next if ($line !~ /\"/);
				  $line =~ s/\x00//; # remove null characters
				  my @line = split(/\,/,$line);
				  my $surname = $line[1]; my $forenames = $line[2]; my $age = $line[3]; my $death_year = $line[5]; my $subdistrict = $line[6]; my $reference = $line[$#line];
				  $surname =~ s/\"//g; $age =~ s/\"//g; $subdistrict =~ s/\"//g; $death_year =~ s/\"//g; $reference =~ s/\"//g;
				  if ($death_year =~ /(\d+)\-.*?$/) { $death_year  = $1; }
				  if ($death_year =~ /^.+\/(\d+)$/) { $death_year  = $1; } # in Cheshire, the full date of death can be given instead of just the year, i.e. this variable takes the form "02/Aug/1906"; we wish to remove the day and month
				  if ($subdistrict =~ /^\s+(.*?)$/) { $subdistrict = $1; }
				  
				  my $num_records = scalar keys %{$ref_nums{$region}{$reference}};
				  
				  # CHECKPOINT: exclude multiple copies of the same record, but only for certain regions where there is a one-to-one correspondence between record and reference number (see above)
#				  if ( ($num_records != 1) and (($region eq 'Bath') or ($region eq 'Cumbria') or ($region eq 'Shropshire') or ($region eq 'West_Midlands') or ($region eq 'Wiltshire') or ($region eq 'Yorkshire')) )
#					{ while((my $excl,my $irrel)=each(%{$ref_nums{$region}{$reference}}))
#						{ print "$reference has $num_records records --> $excl\n";
#						}
#					}
				  next if ( ($num_records != 1) and (($region eq 'Bath') or ($region eq 'Cumbria') or ($region eq 'Shropshire') or ($region eq 'West_Midlands') or ($region eq 'Wiltshire') or ($region eq 'Yorkshire')) );
				  
				  next if ($death_year !~ /^\d{4}$/); # CHECKPOINT: year of death has to be a recognisable 4 digit number. If it isn't, it's more likely that age and year have been swapped around by mistake
				  my $year;
				  if ($age =~ /^\d+$/) # we impute year of birth only if we have a recognisable age
					{ $year = $death_year-$age; }
				  elsif ($age =~ /^.+\/(\d+)$/) # in Cheshire, the date of birth can be given instead of the age
					{ my $birth_year = $1;
					  $year = $birth_year;
					}
				  next if (!(defined($year)));
				  next if ($year !~ /^\d{4}$/); # CHECKPOINT: the year of birth must have 4 digits
				  $subdistricts_in_region{$region}{$subdistrict}++;
				  if ($forenames =~ /\"/)
					{ $forenames =~ s/\"//g;
					  $forenames = NFD($forenames); # normalise all characters in order to remove diacritics (these may not be parsed correctly)
					  next if ($forenames =~ /\d+/); # CHECKPOINT: this is not a name but a number
					  next if ($forenames =~ /\?/); # CHECKPOINT: name contains an ambiguity character
					  next if ($forenames =~ /\&/); # CHECKPOINT: the record typically specifies more than one name (usually both parents)
					  next if (($forenames =~ /\(/) or ($forenames =~ /\[/) or ($forenames =~ /\)/) or ($forenames =~ /\]/)); # CHECKPOINT: records in brackets, e.g. "(boy)", are either not bona fide names or reflect lack of confidence in the transcription, e.g. "(kenneth)"
					  next if (($forenames =~ / Of /) or ($forenames =~ /Unchristened/) or ($forenames =~ /Deceased/) or ($forenames =~ / Name /) or ($forenames =~ /Newborn/) or ($forenames =~ /Not Named/) or ($forenames =~ /Un\-named/) or ($forenames =~ /No First Name/) or ($forenames =~ /Name Not Given/) or ($forenames =~ /Unnamed/) or ($forenames =~ /Unknown/) or ($forenames =~ /Undetermined/) or ($forenames =~ /No Name/) or ($forenames =~ /Registered/) or ($forenames =~ /Re\-registered/) or ($forenames =~ /Child Of/) or ($forenames =~ /Male Infant/) or ($forenames =~ /Infant Of/) or ($forenames =~ /Son Of/) or ($forenames =~ /D Of/) or ($forenames =~ /Dau Of/) or ($forenames =~ /Daur Of/) or ($forenames =~ /Daughter Of/) or ($forenames =~ /Daughterr Of/) or ($forenames =~ /Infant Girl/) or ($forenames =~ /Infant Boy/) or ($forenames =~ /Female Infant/) or ($forenames =~ /Femal Infant/) or ($forenames =~ /Infant Child/) or ($forenames =~ /Infant Female/) or ($forenames =~ /Infant Male/) or ($forenames =~ /Baby Female/) or ($forenames =~ /Baby Male/) or ($forenames =~ /Infant Son/) or ($forenames =~ /Infant Daur/) or ($forenames =~ /^Female$/) or ($forenames =~ /^Male$/) or ($forenames =~ /^Infant$/) or ($forenames =~ /^Baby$/) or ($forenames =~ /^Baby /)); # CHECKPOINT: records of this kind are not distinct names
					  
					  # determine which are the first and middle names

					  # a unique complication with death records is that sometimes they contain titles which must first be omitted; otherwise, they may mistakenly be interpreted as names
					  # note that the regex does not require a space between the title and the forename. This is so that we catch entries like "Sergeant LINGUARD", who died in 1879: he has no forename in his record
					  if (($forenames =~ /^Colonel(.*?)$/) or ($forenames =~ /^Corporal(.*?)$/) or ($forenames =~ /^Doctor(.*?)$/) or ($forenames =~ /^General(.*?)$/) or ($forenames =~ /^Lady(.*?)$/) or ($forenames =~ /^Lord(.*?)$/) or ($forenames =~ /^Major(.*?)$/) or ($forenames =~ /^Reverend(.*?)$/) or ($forenames =~ /^Sergeant(.*?)$/))
						{ $forenames = $1;
						  if ($forenames =~ /^\s+(.*?)$/) { $forenames = $1; }
						}
					  next if (($forenames =~ /Countess Of/) or ($forenames =~ /Prince Of/) or ($forenames =~ /Late Of/));
					  
					  # note that when determining which are the first and middle names that there are occasional records where the middle name is "Van De/Der/Den" - this is a common Dutch prefix and should actually be part of the surname
					  my $first_name; my $middle_names;
					  if ($forenames =~ /^(.*?) (.*?)$/)
						{ $first_name = $1; $middle_names = $2;
						  if (($middle_names =~ /^Van De$/) or ($middle_names =~ /^Van Der$/) or ($middle_names =~ /^Van Den$/)) # if there are only two "middle names", "Van" and "De/Der/Den", then prefix the latter to the surname and empty the variable $middle_name
							{ $surname = "$middle_names $surname"; $surname = uc($surname);
							  $forenames = $first_name;
							  $middle_names = '';
							}
						}
					  else
						{ $first_name = $forenames; }
					  
					  next if (!(defined($first_name)));
#					  next if ($first_name =~ /^\w{1}$/); # CHECKPOINT: this is not a name but an initial
#					  next if (($first_name =~ /^\-/) or ($first_name =~ /\-$/)); # CHECKPOINT: records that begin or end with a hyphen are likely to be compound first names (such as Anna-Marie) with an erroneous space between them
					  next if ($first_name !~ /[a-z]/i); # CHECKPOINT: name does not contain at least one alphabetical character
					  next if ($first_name =~ /^\s+$/);
					  next if ($first_name eq '');
					
					  $full_names{"$forenames $surname"}{$year}++;
					  $surnames{$surname}++;
					  $forenames{$first_name}++;
					  my $first_name_gender = 'undetermined';
					  my $first_name_uc = uc($first_name);
					  if ((exists($genders{$first_name_uc})) and ($first_name_uc !~ /^\w{1}$/)) { $first_name_gender = $genders{$first_name_uc}; }
					  if 	(($first_name_gender eq 'female') or ($first_name_gender eq 'mostly female')) { $f_forenames{$first_name}++; }
					  elsif (($first_name_gender eq 'male')   or ($first_name_gender eq 'mostly male'))   { $m_forenames{$first_name}++; }
					  $forenames_data{$year}{$first_name}++;
					  $years_in_which_forename_used{$first_name}{$year}++;
					  $records_per_year{$year}++;
					  $records_per_region{$region}{no_of_birth_records}++;
					  $records_per_region{$region}{url} = $url;
					  $records_per_region{$region}{date_of_last_update} = $date_of_last_update;
					  $records_per_region{$region}{years_covered}{$year}++;
					  if (defined($middle_names))
						{ my $acceptable_middle_name_records = '';
						  my $number_of_middle_names_for_this_record = 0;
						  my @middle_names = split(/ /,$middle_names);
						  foreach my $middle_name (@middle_names)
							{ next if ($middle_name =~ /\d+/); # CHECKPOINT: this is not a name but a number
							  #next if ($middle_name =~ /^\w{1}$/); # CHECKPOINT: this is not a name but an initial
							  next if (($middle_name =~ /\(/) or ($middle_name =~ /\[/) or ($middle_name =~ /\)/) or ($middle_name =~ /\]/)); # CHECKPOINT: records in brackets, e.g. "(boy)", are either not bona fide names or reflect lack of confidence in the transcription, e.g. "(kenneth)"
#							  next if (($middle_name =~ /^\-/) or ($middle_name =~ /\-$/)); # CHECKPOINT: records that begin or end with a hyphen are likely to be compound first names (such as Anna-Marie), mistranscribed by being split into 'first name' and 'middle name' categories. In the case of middle names, records that end with a hyphen are usually the start of a double-barrelled surname, the first part of which is recorded in the 'middle name' box
							  next if ($middle_name !~ /[a-z]/i); # CHECKPOINT: name does not contain at least one alphabetical character
							  next if ($middle_name =~ /^\s+$/);
							  next if ($middle_name eq '');
							  
							  $middle_names{$middle_name}++;
							  $middle_names_data{$year}{$middle_name}++;
							  my $middle_name_gender = 'undetermined';
							  my $middle_name_uc = uc($middle_name);
							  if ((exists($genders{$middle_name_uc})) and ($middle_name_uc !~ /^\w{1}$/)) { $middle_name_gender = $genders{$middle_name_uc}; }
							  if 	(($middle_name_gender eq 'female') or ($middle_name_gender eq 'mostly female')) { $f_middle_names{$middle_name}++; }
							  elsif (($middle_name_gender eq 'male')   or ($middle_name_gender eq 'mostly male'))   { $m_middle_names{$middle_name}++; }
							  $years_in_which_middle_name_used{$middle_name}{$year}++;
							  
							  $acceptable_middle_name_records .= "$middle_name ";
							  $number_of_middle_names_for_this_record++;
							}
						  $acceptable_middle_name_records =~ s/\s+$//;
						  if ($acceptable_middle_name_records ne '')
							{ $first_and_middle_names{"$first_name $acceptable_middle_name_records"}++;
							  $records_per_region{$region}{no_of_birth_records_with_middle_names}++;
							  
							  # note that the "number of records containing a middle name per year" will differ from the total number of times all middle names have been seen - because records can have more than one middle name
							  # the purpose of this variable is to later ensure that when you sum the columns "No. of records with a middle name" in SUMMARY_PER_YEAR and "No. of occurrences as a middle name" in OUT_TOTAL_NAME_FREQ you get the same answer
							  $number_of_records_with_a_middle_name_per_year{$year}++;
							}
						  if ($number_of_middle_names_for_this_record >= 1)
							{ push(@{$average_number_of_middle_names_per_record{$year}},$number_of_middle_names_for_this_record); }
						}
					  else
						{ $middle_names_data{$year}{'(none)'}++;
						  $middle_names{'(none)'}++;
						}
					}
				}
			  close(IN) or die $!;
			}
		}
	}

# OUTPUT FREQUENCY OF NAMES PER YEAR, IN BOTH ABSOLUTE AND RELATIVE TERMS
my @years = (); my %usable_years = ();
while((my $year,my $irrel)=each(%records_per_year))
	{ my $total_num_of_records_this_year = $records_per_year{$year};
	  push(@years,$year);
	  $usable_years{$year}++;
	}
my @sorted_years = sort {$a <=> $b} @years;
my $years = join("\t",@sorted_years);

print OUT_PCT_FIRST "Name\tGender\tRank (overall)\tRank (for female/mostly female names)\tRank (for male/mostly male names)\t";
print OUT_PCT_FIRST "No. of years in which this name is registered\tMax. no. of consecutive years in which this name is registered\t";
print OUT_PCT_FIRST "Total no. of records with this name\tTotal no. of uses of this name as a forename\tTotal no. of uses of this name as a middle name\tRatio of forename to middle name use\t";
print OUT_PCT_FIRST "Min. no. of records registered with this name in a given year\tMax. no. of records registered with this name in a given year\t";
print OUT_PCT_FIRST "Year of first recorded registration\tYear of greatest popularity (as % of records registered that year)\tEarliest year of greatest popularity\tYear of last recorded registration\t";
print OUT_PCT_FIRST "Debut year (year in which the name is first used, assuming 1 or more years of no use prior to this - i.e. this is not the same as year of first recorded registration, which may simply be the start of the dataset)\t";
print OUT_PCT_FIRST "Year of abandonment (year in which the proportion of records with that name first drops below $abandon_pc% of its past maximum; given only if applicable and for names used (a) a total of > $min_records times, and (b) in consecutive use for >= $min_consecutive_years years, with (c) their peak usage within the longest consecutive use period)\t";
print OUT_PCT_FIRST "Year of revival (after abandonment, year in which the proportion of records with that name reaches $revival_pc% of its past maximum; given only if applicable and for names used (a) a total of > $min_records times, and (b) in consecutive use for >= $min_consecutive_years years, with (c) their peak usage, year of abandonment and year of revival within the longest consecutive use period, and (d) at least $years_between_abandonment_and_revival years between abandonment and revival)\t";
print OUT_PCT_FIRST "No. of years from debut to peak (if applicable)\tNo. of years from peak to abandonment (if applicable)\tNo. of years from debut to abandonment (if applicable)\tNo. of years from abandonment to revival (if applicable)\t";
print OUT_PCT_FIRST "$years\n";

print OUT_ABS_FIRST "Name\tGender\tRank (overall)\tRank (for female/mostly female names)\tRank (for male/mostly male names)\t";
print OUT_ABS_FIRST "No. of years in which this name is registered\tMax. no. of consecutive years in which this name is registered\t";
print OUT_ABS_FIRST "Total no. of records with this name\tTotal no. of uses of this name as a forename\tTotal no. of uses of this name as a middle name\tRatio of forename to middle name use\t";
print OUT_ABS_FIRST "Min. no. of records registered with this name in a given year\tMax. no. of records registered with this name in a given year\t";
print OUT_ABS_FIRST "Year of first recorded registration\tYear of greatest popularity (as % of records registered that year)\tEarliest year of greatest popularity\tYear of last recorded registration\t";
print OUT_ABS_FIRST "Debut year (year in which the name is first used, assuming 1 or more years of no use prior to this - i.e. this is not the same as year of first recorded registration, which may simply be the start of the dataset)\t";
print OUT_ABS_FIRST "Year of abandonment (year in which the proportion of records with that name first drops below $abandon_pc% of its past maximum; given only if applicable and for names used (a) a total of > $min_records times, and (b) in consecutive use for >= $min_consecutive_years years, with (c) their peak usage within the longest consecutive use period)\t";
print OUT_ABS_FIRST "Year of revival (after abandonment, year in which the proportion of records with that name reaches $revival_pc% of its past maximum; given only if applicable and for names used (a) a total of > $min_records times, and (b) in consecutive use for >= $min_consecutive_years years, with (c) their peak usage, year of abandonment and year of revival within the longest consecutive use period, and (d) at least $years_between_abandonment_and_revival years between abandonment and revival)\t";
print OUT_ABS_FIRST "No. of years from debut to peak (if applicable)\tNo. of years from peak to abandonment (if applicable)\tNo. of years from debut to abandonment (if applicable)\tNo. of years from abandonment to revival (if applicable)\t";
print OUT_ABS_FIRST "$years\n";

print OUT_PCT_MIDDLE "Name\tGender\tRank (overall)\tRank (for female/mostly female names)\tRank (for male/mostly male names)\t";
print OUT_PCT_MIDDLE "No. of years in which this name is registered\tMax. no. of consecutive years in which this name is registered\t";
print OUT_PCT_MIDDLE "Total no. of records with this name\tTotal no. of uses of this name as a forename\tTotal no. of uses of this name as a middle name\tRatio of forename to middle name use\t";
print OUT_PCT_MIDDLE "Min. no. of records registered with this name in a given year\tMax. no. of records registered with this name in a given year\t";
print OUT_PCT_MIDDLE "Year of first recorded registration\tYear of greatest popularity (as % of records registered that year)\tEarliest year of greatest popularity\tYear of last recorded registration\t";
print OUT_PCT_MIDDLE "Debut year (year in which the name is first used, assuming 1 or more years of no use prior to this - i.e. this is not the same as year of first recorded registration, which may simply be the start of the dataset)\t";
print OUT_PCT_MIDDLE "Year of abandonment (year in which the proportion of records with that name first drops below $abandon_pc% of its past maximum; given only if applicable and for names used (a) a total of > $min_records times, and (b) in consecutive use for >= $min_consecutive_years years, with (c) their peak usage within the longest consecutive use period)\t";
print OUT_PCT_MIDDLE "Year of revival (after abandonment, year in which the proportion of records with that name reaches $revival_pc% of its past maximum; given only if applicable and for names used (a) a total of > $min_records times, and (b) in consecutive use for >= $min_consecutive_years years, with (c) their peak usage, year of abandonment and year of revival within the longest consecutive use period, and (d) at least $years_between_abandonment_and_revival years between abandonment and revival)\t";
print OUT_PCT_MIDDLE "No. of years from debut to peak (if applicable)\tNo. of years from peak to abandonment (if applicable)\tNo. of years from debut to abandonment (if applicable)\tNo. of years from abandonment to revival (if applicable)\t";
print OUT_PCT_MIDDLE "$years\n";

print OUT_ABS_MIDDLE "Name\tGender\tRank (overall)\tRank (for female/mostly female names)\tRank (for male/mostly male names)\t";
print OUT_ABS_MIDDLE "No. of years in which this name is registered\tMax. no. of consecutive years in which this name is registered\t";
print OUT_ABS_MIDDLE "Total no. of records with this name\tTotal no. of uses of this name as a forename\tTotal no. of uses of this name as a middle name\tRatio of forename to middle name use\t";
print OUT_ABS_MIDDLE "Min. no. of records registered with this name in a given year\tMax. no. of records registered with this name in a given year\t";
print OUT_ABS_MIDDLE "Year of first recorded registration\tYear of greatest popularity (as % of records registered that year)\tEarliest year of greatest popularity\tYear of last recorded registration\t";
print OUT_ABS_MIDDLE "Debut year (year in which the name is first used, assuming 1 or more years of no use prior to this - i.e. this is not the same as year of first recorded registration, which may simply be the start of the dataset)\t";
print OUT_ABS_MIDDLE "Year of abandonment (year in which the proportion of records with that name first drops below $abandon_pc% of its past maximum; given only if applicable and for names used (a) a total of > $min_records times, and (b) in consecutive use for >= $min_consecutive_years years, with (c) their peak usage within the longest consecutive use period)\t";
print OUT_ABS_MIDDLE "Year of revival (after abandonment, year in which the proportion of records with that name reaches $revival_pc% of its past maximum; given only if applicable and for names used (a) a total of > $min_records times, and (b) in consecutive use for >= $min_consecutive_years years, with (c) their peak usage, year of abandonment and year of revival within the longest consecutive use period, and (d) at least $years_between_abandonment_and_revival years between abandonment and revival)\t";
print OUT_ABS_MIDDLE "No. of years from debut to peak (if applicable)\tNo. of years from peak to abandonment (if applicable)\tNo. of years from debut to abandonment (if applicable)\tNo. of years from abandonment to revival (if applicable)\t";
print OUT_ABS_MIDDLE "$years\n";

my %pc_of_records_per_year_with_a_middle_name = ();
for(my $x=0;$x<=1;$x++)
	{ my %names = (); my %data = (); my %female = (); my %male = (); my $data_type = '';
	  if 	($x == 0) { %names = %forenames;    %data = %forenames_data;	%female = %f_forenames;    %male = %m_forenames; 	$data_type = 'forenames'; 	 }
	  elsif ($x == 1) { %names = %middle_names; %data = %middle_names_data; %female = %f_middle_names; %male = %m_middle_names; $data_type = 'middle names'; }
	  
	  # iterate through the list of names so as to calculate the total counts of each name - this data will be used to determine the overall rank for each name
	  # when ranking middle names, we intentionally omit "(none)"
	  my @names = ();
	  while((my $name,my $irrel)=each(%names))
		{ push(@names,$name); }
	  my @sorted_names = sort {$a cmp $b} @names;
	  my @all_name_usage = (); my @all_name_usage_F = (); my @all_name_usage_M = ();
	  foreach my $name (@sorted_names)
		{ print "parsing $data_type, first round: $name...\n";
		  my $total_number_of_people_with_this_name_across_time = 0;
		  foreach my $year (@sorted_years)
			{ if (exists($data{$year}{$name}))
				{ my $num_names = $data{$year}{$name};
				  $total_number_of_people_with_this_name_across_time += $num_names;
				}
			}
		  my $total_F_records_with_this_name = 0; if (exists($female{$name})) { $total_F_records_with_this_name = $female{$name}; }
		  my $total_M_records_with_this_name = 0; if (exists($male{$name}))   { $total_M_records_with_this_name = $male{$name};   }	  
		  if ($name ne "(none)")
			{ push(@all_name_usage,[$total_number_of_people_with_this_name_across_time,$name]);
			  push(@all_name_usage_F,[$total_F_records_with_this_name,$name]) unless ($total_F_records_with_this_name == 0);
			  push(@all_name_usage_M,[$total_M_records_with_this_name,$name]) unless ($total_M_records_with_this_name == 0);
			}
		}
	  
	  # determine overall rank for each name
	  my @sorted_nums = map { $_->[0] } sort { $b->[1] <=> $a->[1] } map { [$_, $_->[0]] } @all_name_usage;
	  my $rank = 0; my %counts_per_rank_per_name = ();
	  for(my $x=0;$x<@sorted_nums;$x++)
		{ my $num = $sorted_nums[$x][0]; my $name = $sorted_nums[$x][1];
		  $rank++ unless ((defined($sorted_nums[$x-1][0])) and ($sorted_nums[$x-1][0] == $num)); # don't increase rank number if this name has the same number of registrations as the previously-ranked name (i.e. their ranks are equal)
		  $counts_per_rank_per_name{$rank}{$name} += $num;
		}
	  
	  # determine the rank of each name, by reference to its gender-specific distribution
	  my @sorted_nums_F = map { $_->[0] } sort { $b->[1] <=> $a->[1] } map { [$_, $_->[0]] } @all_name_usage_F;
	  my @sorted_nums_M = map { $_->[0] } sort { $b->[1] <=> $a->[1] } map { [$_, $_->[0]] } @all_name_usage_M;
	  my $rank_f = 0; my %ranks_per_name_F = ();
	  for(my $x=0;$x<@sorted_nums_F;$x++)
		{ my $num = $sorted_nums_F[$x][0]; my $name = $sorted_nums_F[$x][1];
		  $rank_f++ unless ((defined($sorted_nums_F[$x-1][0])) and ($sorted_nums_F[$x-1][0] == $num)); # don't increase rank number if this name has the same number of registrations as the previously-ranked name (i.e. their ranks are equal)
		  $ranks_per_name_F{$name} = $rank_f;
		}
	  my $rank_m = 0; my %ranks_per_name_M = ();
	  for(my $x=0;$x<@sorted_nums_M;$x++)
		{ my $num = $sorted_nums_M[$x][0]; my $name = $sorted_nums_M[$x][1];
		  $rank_m++ unless ((defined($sorted_nums_M[$x-1][0])) and ($sorted_nums_M[$x-1][0] == $num)); # don't increase rank number if this name has the same number of registrations as the previously-ranked name (i.e. their ranks are equal)
		  $ranks_per_name_M{$name} = $rank_m;
		}
	  
	  # summarise rank info per name
	  my @ranks = ();
	  while((my $rank,my $irrel)=each(%counts_per_rank_per_name))
		{ push(@ranks,$rank); }
	  my @sorted_ranks = sort {$a <=> $b} @ranks;
	  my %ranks_per_name = ();
	  foreach my $rank (@sorted_ranks)
		{ my @names = ();
		  while((my $name,my $irrel)=each(%{$counts_per_rank_per_name{$rank}}))
			{ push(@names,$name); }
		  my @sorted_names = sort {$a cmp $b} @names;
		  foreach my $name (@sorted_names)
			{ my $rank_f = 'NA'; my $rank_m = 'NA';
			  if (exists($ranks_per_name_F{$name})) { $rank_f = $ranks_per_name_F{$name}; }
			  if (exists($ranks_per_name_M{$name})) { $rank_m = $ranks_per_name_M{$name}; }
			  $ranks_per_name{$name}{rank_all} = $rank;
			  $ranks_per_name{$name}{rank_f} = $rank_f;
			  $ranks_per_name{$name}{rank_m} = $rank_m;
			}
		}
		
	  # iterate through the list of names a second time, and print a large number of summary statistics per name
	  foreach my $name (@sorted_names)
		{ print "parsing $data_type, second round: $name...\n";
		  
		  # convert absolute counts of name use per year into percentages
		  my @arr = ();
		  foreach my $year (@sorted_years)
			{ my $total_num_of_records_this_year = $records_per_year{$year};
			  if (exists($data{$year}{$name}))
				{ my $num_names = $data{$year}{$name};
				  my $pc = sprintf("%.6f",(($num_names/$total_num_of_records_this_year)*100));
				  push(@arr,[$pc,$year]);
				}
			  else
				{ push(@arr,[0,$year]); }
			}
		  my @sorted_arr = map { $_->[0] } sort { $b->[1] <=> $a->[1] } map { [$_, $_->[0]] } @arr;
		  my $peak_pc = $sorted_arr[0][0]; my $peak_year = $sorted_arr[0][1];
		  my %peak_years = ();
		  $peak_years{$peak_year}++;
		  for(my $x=1;$x<@sorted_arr;$x++)
			{ my $this_pc = $sorted_arr[$x][0]; my $this_year = $sorted_arr[$x][1];
			  if ($this_pc == $peak_pc) # i.e. name use in this year is the same as the peak year
				{ $peak_years{$this_year}++;
				}
			}
		  $peak_year = CONCATENATE_YEARS(\%peak_years); # in the event multiple years are tied for peak popularity, we tidy up the presentation, concatenating consecutive years
		  
		  # produce the rows of the table, $out_line_num and $out_line_pc: the absolute number of names registered per year, and the % of names registered per year
		  my %years_with_data = ();
		  my $out_line_pc = ''; my $out_line_num = '';
		  foreach my $year (@sorted_years)
			{ my $total_num_of_records_this_year = $records_per_year{$year};
			  if (exists($data{$year}{$name}))
				{ my $num_names = $data{$year}{$name};
				  my $pc = sprintf("%.6f",(($num_names/$total_num_of_records_this_year)*100));
				  $out_line_pc  .= "$pc\t";
				  $out_line_num .= "$num_names\t";
				  $years_with_data{$year}++ if ($num_names > 0);
				  if (($x == 1) and ($name eq '(none)'))
					{ $pc_of_records_per_year_with_a_middle_name{$year} = sprintf("%.3f",(100-$pc));
					}
				}
			  else
				{ $out_line_pc  .= "0\t";
				  $out_line_num .= "0\t";
				}
			}
		  $out_line_pc =~ s/\t$//; $out_line_num =~ s/\t$//;
		  
		  # determine the maximum and minimum number of birth records registered with this name, and the number of years this name has been in use
		  my @out_line_pc 		  = split(/\t/,$out_line_pc);
		  my @out_line_num 		  = split(/\t/,$out_line_num);
		  my @sorted_out_line_pc  = sort {$a <=> $b} @out_line_pc;
		  my @sorted_out_line_num = sort {$a <=> $b} @out_line_num;
		  my $min_no_of_records   = $sorted_out_line_num[0];
		  my $max_no_of_records   = $sorted_out_line_num[$#sorted_out_line_num];
		  my $max_pc_of_records	  = $sorted_out_line_pc[$#sorted_out_line_pc];
		  my $pc_of_max_abandon	  = $abandon_frac*$max_pc_of_records;
		  my $pc_of_max_revival	  = $revival_frac*$max_pc_of_records;
		  my $num_of_years_in_use = scalar keys %years_with_data;
		  
		  # determine first and last year of registration, and debut year (which is not the same as the first year of registration - rather, it is the first year in which non-0 records are recorded, thus presupposing the existence of years with no use)
		  my @years_with_data = ();
		  while((my $year,my $irrel)=each(%years_with_data))
			{ push(@years_with_data,$year); }
		  my $first_recorded_sighting = 'NA'; my $last_recorded_sighting = 'NA';
		  if ($#years_with_data != -1)
			{ my @sorted_years_with_data = sort {$a <=> $b} @years_with_data;
			  $first_recorded_sighting = $sorted_years_with_data[0];
			  $last_recorded_sighting  = $sorted_years_with_data[$#sorted_years_with_data];
			}
		  my $debut_year = 'NA';
		  for(my $x=0;$x<@sorted_years;$x++)
			{ my $yr = $sorted_years[$x];
			  my $no = $out_line_num[$x];
			  last if (($x == 0) and ($no > 0)); # if this name is recorded in the first year of the data, then we cannot say that it 'debuts' - it may have been recorded before
			  if ($no > 0)
				{ $debut_year = $yr; }
			  last if ($no > 0);
			}
		  
		  # determine the total number of consecutive years in which this name has been used, and the longest consecutive stretch
		  my $cat_years_with_data = CONCATENATE_YEARS(\%years_with_data);
		  my @cat_years_with_data = split(/\,/,$cat_years_with_data);
		  my @len_of_consec_years = ();
		  foreach my $years (@cat_years_with_data)
			{ if ($years =~ /^(\d+)\-(\d+)$/)
				{ my $yr1 = $1; my $yr2 = $2;
				  my $dist = ($yr2-$yr1)+1;
				  push(@len_of_consec_years,[$dist,$yr1,$yr2]);
				}
			  elsif ($years =~ /^\d+$/)
				{ push(@len_of_consec_years,[1,$years,$years]); }
			}
		  my @sorted_len_of_consec_years = map { $_->[0] } sort { $b->[1] <=> $a->[1] } map { [$_, $_->[0]] } @len_of_consec_years;
		  my $max_num_of_consecutive_years_of_use = $sorted_len_of_consec_years[0][0];
		  my $consecutive_period_start 			  = $sorted_len_of_consec_years[0][1];
		  my $consecutive_period_end   			  = $sorted_len_of_consec_years[0][2];
	  
	  	  # for names used > $min_records times, for longer than $min_consecutive_years consecutive years and with peak usage within this period, determine the year of abandonment (if applicable)
		  my $year_of_abandonment = 'NA';
		  my $first_peak_year = $peak_year;
		  if (($peak_year =~ /^(\d+)\-.*?$/) or ($peak_year =~ /^(\d+)\,.*?$/)) { $first_peak_year = $1; }
		  my $absolute_number_of_records_with_this_name = sum(@out_line_num);
		  if (($max_num_of_consecutive_years_of_use >= $min_consecutive_years) and ($absolute_number_of_records_with_this_name > $min_records) and ($first_peak_year > $consecutive_period_start) and ($first_peak_year < $consecutive_period_end))
			{ for(my $x=0;$x<@sorted_years;$x++)
				{ my $yr = $sorted_years[$x];
				  my $pc = $out_line_pc[$x];
				  next if ($yr < $first_peak_year); # CHECKPOINT: a name cannot be abandoned before it has peaked in use (this is a sanity test)
				  next if ($yr > $consecutive_period_end); # CHECKPOINT: to consider a name abandoned, it must have peaked *and then* been abandoned within the consecutive use period
				  if ($pc < $pc_of_max_abandon)
					{ $year_of_abandonment = $yr; }
				  last if ($pc < $pc_of_max_abandon);
				}
			}
			
		  # for names that have been abandoned, determine the year of revival (if applicable). A name is considered abandoned if it drops below $year_of_abandonment % of its past maximum and revived if after $years_between_abandonment_and_revival years it has again exceeded $pc_of_max_revival % of its past maximum
		  my $year_of_revival = 'NA';
		  if ($year_of_abandonment =~ /^\d+/)
			{ for(my $x=0;$x<@sorted_years;$x++)
				{ my $yr = $sorted_years[$x];
				  my $pc = $out_line_pc[$x];
				  next if ($yr < $year_of_abandonment); # CHECKPOINT: a name cannot be revived before it has been abandoned (this is a sanity test)
				  next if ($yr > $consecutive_period_end); # CHECKPOINT: to consider a name revived, it must have been abandoned *and then* revived within the consecutive use period, i.e. it cannot have disappeared to 0 completely (that is more likely to indicate patchy record-keeping instead)
				  if (($pc > $pc_of_max_revival) and ($yr > $year_of_abandonment+$years_between_abandonment_and_revival))
					{ $year_of_revival = $yr; }
				  last if ($pc > $pc_of_max_revival);
				}
			}
		  
		  # determine the number of years from debut to peak, debut to abandonment, peak to abandonment, and abandonment to revival (if applicable)
		  my $num_of_years_debut_to_peak = 'NA'; my $num_of_years_debut_to_abandonment = 'NA'; my $num_of_years_peak_to_abandonment = 'NA'; my $num_of_years_abandonment_to_revival = 'NA';
		  if (($first_peak_year =~ /^\d+$/) and ($debut_year =~ /^\d+$/))
			{ $num_of_years_debut_to_peak = $first_peak_year-$debut_year; }
		  if (($year_of_abandonment =~ /^\d+$/) and ($first_peak_year =~ /^\d+$/))
			{ $num_of_years_peak_to_abandonment = $year_of_abandonment-$first_peak_year; }
		  if (($year_of_abandonment =~ /^\d+$/) and ($first_peak_year =~ /^\d+$/) and ($debut_year =~ /^\d+$/))
			{ $num_of_years_debut_to_abandonment = $year_of_abandonment-$debut_year; }
		  if (($year_of_abandonment =~ /^\d+$/) and ($year_of_revival =~ /^\d+$/))
			{ $num_of_years_abandonment_to_revival = $year_of_revival-$year_of_abandonment; }
	  
		  # determine the number of times this name has been used as a first name and middle name, and the ratio thereof
		  my $num_occurrences_as_forename = 0; my $num_occurrences_as_middle_name = 0;
		  if (exists($forenames{$name}))    { $num_occurrences_as_forename    = $forenames{$name};    }
		  if (exists($middle_names{$name})) { $num_occurrences_as_middle_name = $middle_names{$name}; }
		  my $ratio_of_forename_to_middle_name_use = 'NA';
		  if ($num_occurrences_as_middle_name > 0)
			{ $ratio_of_forename_to_middle_name_use = sprintf("%.3f",($num_occurrences_as_forename/$num_occurrences_as_middle_name)); }
		  
		  # predict the gender of the name
		  my $gender = 'undetermined'; # the default classification
		  my $name_uc = uc($name);
		  if ((exists($genders{$name_uc})) and ($name_uc !~ /^\w{1}$/)) { $gender = $genders{$name_uc}; }
		  
		  # determine the rank of this name - how popularity it is both overall and in the F/M categories
		  my $rank_all = 'NA'; my $rank_f = 'NA'; my $rank_m = 'NA';
		  if (exists($ranks_per_name{$name}{rank_all})) { $rank_all = $ranks_per_name{$name}{rank_all}; }
		  if (exists($ranks_per_name{$name}{rank_f}))   { $rank_f   = $ranks_per_name{$name}{rank_f};   }
		  if (exists($ranks_per_name{$name}{rank_m}))   { $rank_m   = $ranks_per_name{$name}{rank_m};   }
		  
		  if ($x == 0)
			{ print OUT_PCT_FIRST "$name\t$gender\t$rank_all\t$rank_f\t$rank_m\t$num_of_years_in_use\t$max_num_of_consecutive_years_of_use\t$absolute_number_of_records_with_this_name\t$num_occurrences_as_forename\t$num_occurrences_as_middle_name\t$ratio_of_forename_to_middle_name_use\t$min_no_of_records\t$max_no_of_records\t$first_recorded_sighting\t$peak_year\t$first_peak_year\t$last_recorded_sighting\t$debut_year\t$year_of_abandonment\t$year_of_revival\t$num_of_years_debut_to_peak\t$num_of_years_peak_to_abandonment\t$num_of_years_debut_to_abandonment\t$num_of_years_abandonment_to_revival\t$out_line_pc\n";
			  print OUT_ABS_FIRST "$name\t$gender\t$rank_all\t$rank_f\t$rank_m\t$num_of_years_in_use\t$max_num_of_consecutive_years_of_use\t$absolute_number_of_records_with_this_name\t$num_occurrences_as_forename\t$num_occurrences_as_middle_name\t$ratio_of_forename_to_middle_name_use\t$min_no_of_records\t$max_no_of_records\t$first_recorded_sighting\t$peak_year\t$first_peak_year\t$last_recorded_sighting\t$debut_year\t$year_of_abandonment\t$year_of_revival\t$num_of_years_debut_to_peak\t$num_of_years_peak_to_abandonment\t$num_of_years_debut_to_abandonment\t$num_of_years_abandonment_to_revival\t$out_line_num\n";
			}
		  elsif ($x == 1)
			{ print OUT_PCT_MIDDLE "$name\t$gender\t$rank_all\t$rank_f\t$rank_m\t$num_of_years_in_use\t$max_num_of_consecutive_years_of_use\t$absolute_number_of_records_with_this_name\t$num_occurrences_as_forename\t$num_occurrences_as_middle_name\t$ratio_of_forename_to_middle_name_use\t$min_no_of_records\t$max_no_of_records\t$first_recorded_sighting\t$peak_year\t$first_peak_year\t$last_recorded_sighting\t$debut_year\t$year_of_abandonment\t$year_of_revival\t$num_of_years_debut_to_peak\t$num_of_years_peak_to_abandonment\t$num_of_years_debut_to_abandonment\t$num_of_years_abandonment_to_revival\t$out_line_pc\n";
			  print OUT_ABS_MIDDLE "$name\t$gender\t$rank_all\t$rank_f\t$rank_m\t$num_of_years_in_use\t$max_num_of_consecutive_years_of_use\t$absolute_number_of_records_with_this_name\t$num_occurrences_as_forename\t$num_occurrences_as_middle_name\t$ratio_of_forename_to_middle_name_use\t$min_no_of_records\t$max_no_of_records\t$first_recorded_sighting\t$peak_year\t$first_peak_year\t$last_recorded_sighting\t$debut_year\t$year_of_abandonment\t$year_of_revival\t$num_of_years_debut_to_peak\t$num_of_years_peak_to_abandonment\t$num_of_years_debut_to_abandonment\t$num_of_years_abandonment_to_revival\t$out_line_num\n";
			}
		}
	}
close(OUT_PCT_FIRST) or die $!; close(OUT_PCT_MIDDLE) or die $!;
close(OUT_ABS_FIRST) or die $!; close(OUT_ABS_MIDDLE) or die $!;

# OUTPUT A SUMMARY OF DATA PER YEAR
for(my $y=0;$y<@sorted_years;$y++)
	{ my $year = $sorted_years[$y];
	  my $no_of_forename_records = 0; #my $no_of_middle_name_records = 0;
	  my $most_used_forename = ''; my $second_most_used_forename = ''; my $third_most_used_forename = ''; my $fourth_most_used_forename = ''; my $fifth_most_used_forename = '';
	  my $most_used_middle_name = ''; my $second_most_used_middle_name = ''; my $third_most_used_middle_name = ''; my $fourth_most_used_middle_name = ''; my $fifth_most_used_middle_name = '';
	  my $no_of_M_forename_records = 0; my $no_of_F_forename_records = 0;
	  for(my $x=0;$x<=1;$x++)
		{ my %names_data = ();
		  if ($x == 0) { %names_data = %forenames_data; } elsif ($x == 1) { %names_data = %middle_names_data; }
		  my $total_records = 0;
		  my @names = ();
		  while((my $name,my $num)=each(%{$names_data{$year}}))
			{ next if ($name eq '(none)');
			  my $num = $names_data{$year}{$name};
			  push(@names,[$num,$name]);
			  $total_records += $num;
			  if ($x == 0)
				{ my $gender = 'undetermined';
				  my $name_uc = uc($name);
				  if ((exists($genders{$name_uc})) and ($name_uc !~ /^\w{1}$/)) { $gender = $genders{$name_uc}; }
				  if    (($gender eq 'male')   or ($gender eq 'mostly male'))   { $no_of_M_forename_records += $num; }
				  elsif (($gender eq 'female') or ($gender eq 'mostly female')) { $no_of_F_forename_records += $num; }
				}
			}
		  my @sorted_names = map { $_->[0] } sort { $b->[1] <=> $a->[1] } map { [$_, $_->[0]] } @names;
		  my $most_used_num 	   = 'NA'; my $most_used_name 		 = 'NA';
		  my $second_most_used_num = 'NA'; my $second_most_used_name = 'NA';
		  my $third_most_used_num  = 'NA'; my $third_most_used_name  = 'NA';
		  my $fourth_most_used_num = 'NA'; my $fourth_most_used_name = 'NA';
		  my $fifth_most_used_num  = 'NA'; my $fifth_most_used_name  = 'NA';
		  if (defined($sorted_names[0][0])) { $most_used_num 	    = $sorted_names[0][0]; $most_used_name 		  = $sorted_names[0][1]; }
		  if (defined($sorted_names[1][0])) { $second_most_used_num = $sorted_names[1][0]; $second_most_used_name = $sorted_names[1][1]; }
		  if (defined($sorted_names[2][0])) { $third_most_used_num  = $sorted_names[2][0]; $third_most_used_name  = $sorted_names[2][1]; }
		  if (defined($sorted_names[3][0])) { $fourth_most_used_num = $sorted_names[3][0]; $fourth_most_used_name = $sorted_names[3][1]; }
		  if (defined($sorted_names[4][0])) { $fifth_most_used_num  = $sorted_names[4][0]; $fifth_most_used_name  = $sorted_names[4][1]; }
		  my $most_used_pc 		   = 'NA'; if (($total_records > 0) and ($most_used_num 	   !~ /NA/)) { $most_used_pc        = sprintf("%.3f",(($most_used_num/$total_records)*100));		}
		  my $second_most_used_pc  = 'NA'; if (($total_records > 0) and ($second_most_used_num !~ /NA/)) { $second_most_used_pc = sprintf("%.3f",(($second_most_used_num/$total_records)*100)); }
		  my $third_most_used_pc   = 'NA'; if (($total_records > 0) and ($third_most_used_num  !~ /NA/)) { $third_most_used_pc  = sprintf("%.3f",(($third_most_used_num/$total_records)*100));  }
		  my $fourth_most_used_pc  = 'NA'; if (($total_records > 0) and ($fourth_most_used_num !~ /NA/)) { $fourth_most_used_pc = sprintf("%.3f",(($fourth_most_used_num/$total_records)*100)); }
		  my $fifth_most_used_pc   = 'NA'; if (($total_records > 0) and ($fifth_most_used_num  !~ /NA/)) { $fifth_most_used_pc  = sprintf("%.3f",(($fifth_most_used_num/$total_records)*100));  }
		  if ($x == 0)
			{ $most_used_forename 		 = "$most_used_name ($most_used_pc%)";
			  $second_most_used_forename = "$second_most_used_name ($second_most_used_pc%)";
			  $third_most_used_forename  = "$third_most_used_name ($third_most_used_pc%)";
			  $fourth_most_used_forename = "$fourth_most_used_name ($fourth_most_used_pc%)";
			  $fifth_most_used_forename  = "$fifth_most_used_name ($fifth_most_used_pc%)";
			}
		  elsif ($x == 1)
			{ $most_used_middle_name 	    = "$most_used_name ($most_used_pc%)";
			  $second_most_used_middle_name = "$second_most_used_name ($second_most_used_pc%)";
			  $third_most_used_middle_name  = "$third_most_used_name ($third_most_used_pc%)";
			  $fourth_most_used_middle_name = "$fourth_most_used_name ($fourth_most_used_pc%)";
			  $fifth_most_used_middle_name  = "$fifth_most_used_name ($fifth_most_used_pc%)";
			}
		  if 	($x == 0) { $no_of_forename_records    = $total_records; }
		  #elsif ($x == 1) { $no_of_middle_name_records = $total_records; }
		}
	  my $no_of_middle_name_records = 0;
	  if (exists($number_of_records_with_a_middle_name_per_year{$year})) { $no_of_middle_name_records = $number_of_records_with_a_middle_name_per_year{$year}; }
	  my $gender_ratio = 'NA';
	  if ($no_of_F_forename_records > 0) { $gender_ratio = sprintf("%.3f",($no_of_M_forename_records/$no_of_F_forename_records)); }
	  my $no_of_U_forename_records = $no_of_forename_records-$no_of_M_forename_records-$no_of_F_forename_records;
	  my $pc_of_M_forename_records = sprintf("%.3f",(($no_of_M_forename_records/$no_of_forename_records)*100));
	  my $pc_of_F_forename_records = sprintf("%.3f",(($no_of_F_forename_records/$no_of_forename_records)*100));
	  my $pc_of_U_forename_records = sprintf("%.3f",(($no_of_U_forename_records/$no_of_forename_records)*100));
	  my $no_of_unique_forenames_seen = scalar keys %{$forenames_data{$year}};
	  my $forename_diversity = sprintf("%.3f",($no_of_unique_forenames_seen/$no_of_forename_records));
	  my $pc_of_this_years_forenames_new_this_year = 'NA'; my $pc_of_this_years_forenames_also_used_last_year = 'NA';
	  my $last_year = $year-1;
	  if (exists($usable_years{$last_year}))
		{ my %this_years_forenames = %{$forenames_data{$year}};
		  my %last_years_forenames = %{$forenames_data{$last_year}};
		  my $no_of_this_years_forenames = scalar keys %this_years_forenames;
		  my $no_of_this_years_forenames_new_this_year = 0; my $no_of_this_years_forenames_also_used_last_year = 0;
		  while((my $name,my $irrel)=each(%this_years_forenames))
			{ if (exists($last_years_forenames{$name}))
				{ $no_of_this_years_forenames_also_used_last_year++; }
			  else
				{ $no_of_this_years_forenames_new_this_year++; }
			}
		  $pc_of_this_years_forenames_new_this_year = sprintf("%.3f",(($no_of_this_years_forenames_new_this_year/$no_of_this_years_forenames)*100));
		  $pc_of_this_years_forenames_also_used_last_year = sprintf("%.3f",(($no_of_this_years_forenames_also_used_last_year/$no_of_this_years_forenames)*100));
		}
	  my $avg_no_of_middle_names_per_record = 0;
	  if (exists($average_number_of_middle_names_per_record{$year})) { $avg_no_of_middle_names_per_record = avg(@{$average_number_of_middle_names_per_record{$year}}); }
	  $avg_no_of_middle_names_per_record = sprintf("%.3f",$avg_no_of_middle_names_per_record);
	  print SUMMARY_PER_YEAR "$year\t$no_of_forename_records\t$no_of_M_forename_records\t$no_of_F_forename_records\t$no_of_U_forename_records\t";
	  print SUMMARY_PER_YEAR "$pc_of_M_forename_records\t$pc_of_F_forename_records\t$pc_of_U_forename_records\t";
	  print SUMMARY_PER_YEAR "$gender_ratio\t$no_of_middle_name_records\t$avg_no_of_middle_names_per_record\t$no_of_unique_forenames_seen\t$forename_diversity\t$pc_of_this_years_forenames_new_this_year\t";
	  print SUMMARY_PER_YEAR "$most_used_forename\t$second_most_used_forename\t$third_most_used_forename\t$fourth_most_used_forename\t$fifth_most_used_forename\t";
	  print SUMMARY_PER_YEAR "$most_used_middle_name\t$second_most_used_middle_name\t$third_most_used_middle_name\t$fourth_most_used_middle_name\t$fifth_most_used_middle_name\n";
	}
close(SUMMARY_PER_YEAR) or die $!;

# PRINT THE FULL LIST OF FIRST NAMES, AND ASSOCIATED ABSOLUTE COUNT
my @first_names = ();
while((my $first_name,my $irrel)=each(%forenames))
	{ push(@first_names,$first_name); }
my @sorted_first_names = sort {$a cmp $b} @first_names;
my $abs_total = 0;
foreach my $first_name (@sorted_first_names)
	{ my $total = $forenames{$first_name};
	  $abs_total += $total;
	}
foreach my $first_name (@sorted_first_names)
	{ my $gender = 'undetermined';
	  my $first_name_uc = uc($first_name);
	  if ((exists($genders{$first_name_uc})) and ($first_name_uc !~ /^\w{1}$/)) { $gender = $genders{$first_name_uc}; }
	  my $total = $forenames{$first_name};
	  my $pc = sprintf("%.6f",(($total/$abs_total)*100));
	  print OUT_ALL_FIRST "$first_name\t$gender\t$total\t$pc\n";
	}
close(OUT_ALL_FIRST) or die $!;

# PRINT THE FULL LIST OF MIDDLE NAMES, AND ASSOCIATED ABSOLUTE COUNT
my @middle_names = ();
while((my $middle_name,my $irrel)=each(%middle_names))
	{ push(@middle_names,$middle_name); }
my @sorted_middle_names = sort {$a cmp $b} @middle_names;
$abs_total = 0;
foreach my $middle_name (@sorted_middle_names)
	{ my $total = $middle_names{$middle_name};
	  $abs_total += $total;
	}
foreach my $middle_name (@sorted_middle_names)
	{ my $gender = 'undetermined';
	  my $middle_name_uc = uc($middle_name);
	  if ((exists($genders{$middle_name_uc})) and ($middle_name_uc !~ /^\w{1}$/)) { $gender = $genders{$middle_name_uc}; }
	  my $total = $middle_names{$middle_name};
	  my $pc = sprintf("%.6f",(($total/$abs_total)*100));
	  print OUT_ALL_MIDDLE "$middle_name\t$gender\t$total\t$pc\n";
	}
close(OUT_ALL_MIDDLE) or die $!;

# PRINT THE FULL LIST OF FIRST AND MIDDLE NAMES, AND ASSOCIATED ABSOLUTE COUNT
my @first_and_middle_names = ();
while((my $first_and_middle_name,my $irrel)=each(%first_and_middle_names))
	{ push(@first_and_middle_names,$first_and_middle_name); }
my @sorted_first_and_middle_names = sort {$a cmp $b} @first_and_middle_names;
$abs_total = 0;
foreach my $first_and_middle_name (@sorted_first_and_middle_names)
	{ my $total = $first_and_middle_names{$first_and_middle_name};
	  $abs_total += $total;
	}
foreach my $first_and_middle_name (@sorted_first_and_middle_names)
	{ my $first_name; my $middle_names;
	  if ($first_and_middle_name =~ /^(.*?) (.*?)$/)
		{ $first_name = $1; $middle_names = $2;	}
	  my @middle_names = split(/ /,$middle_names);
	  my $num_of_middle_names = @middle_names;
	  my $total = $first_and_middle_names{$first_and_middle_name};
	  my $pc = sprintf("%.6f",(($total/$abs_total)*100));
	  my $gender_of_first_name = 'undetermined';
	  my $first_name_uc = uc($first_name);
	  if ((exists($genders{$first_name_uc})) and ($first_name_uc !~ /^\w{1}$/)) { $gender_of_first_name = $genders{$first_name_uc}; }
	  my $genders_of_middle_names = 'not applicable';
	  if ($num_of_middle_names > 0)
		{ $genders_of_middle_names = '';
		  foreach my $middle_name (@middle_names)
			{ my $gender_of_middle_name = 'undetermined';
			  my $middle_name_uc = uc($middle_name);
			  if ((exists($genders{$middle_name_uc})) and ($middle_name_uc !~ /^\w{1}$/)) { $gender_of_middle_name = $genders{$middle_name_uc}; }
			  $genders_of_middle_names .= "$gender_of_middle_name, ";
			}
		}
	  $genders_of_middle_names =~ s/\, $//;
	  print OUT_ALL_FIRST_MIDL "$first_and_middle_name\t$num_of_middle_names\t$total\t$pc\t$gender_of_first_name\t$genders_of_middle_names\n";
	}
close(OUT_ALL_FIRST_MIDL) or die $!;

# PRINT THE FULL LIST OF NAMES, AND ASSOCIATED ABSOLUTE COUNT PER YEAR
my @full_names = ();
while((my $full_name,my $irrel)=each(%full_names))
	{ push(@full_names,$full_name); }
my @sorted_full_names = sort {$a cmp $b} @full_names;
foreach my $full_name (@sorted_full_names)
	{ my @years = ();
	  while((my $year,my $irrel)=each(%{$full_names{$full_name}}))
		{ push(@years,$year); }
	  my @sorted_years = sort {$a <=> $b} @years;
	  foreach my $year (@sorted_years)
		{ my $num = $full_names{$full_name}{$year};
		  print OUT_ALL_FULL "$full_name\t$year\t$num\n";
		}
	}
close(OUT_ALL_FULL) or die $!;

# OUTPUT A SUMMARY OF THE DATA BY REGION
foreach my $region (@sorted_regions)
	{ next if (($region eq '.') or ($region eq '..'));
	  next if (!(exists($records_per_region{$region})));
	  my $no_of_subdistricts_in_region = scalar keys %{$subdistricts_in_region{$region}};
	  my @subdistricts_in_region = ();
	  while((my $subdistrict,my $irrel)=each(%{$subdistricts_in_region{$region}}))
		{ push(@subdistricts_in_region,$subdistrict); }
	  my @sorted_subdistricts_in_region = sort {$a cmp $b} @subdistricts_in_region;
	  my $subdistricts_in_region = join(" | ",@sorted_subdistricts_in_region);
	  my $url   			  = $records_per_region{$region}{url};
	  my $count 			  = $records_per_region{$region}{count};
	  my $no_of_records 	  = $records_per_region{$region}{no_of_birth_records};
	  my $no_of_records_mid	  = $records_per_region{$region}{no_of_birth_records_with_middle_names};
	  my $date_of_last_update = $records_per_region{$region}{date_of_last_update};
	  my @years = ();
	  while((my $year,my $irrel)=each(%{$records_per_region{$region}{years_covered}}))
		{ push(@years,$year); }
	  my @sorted_years = sort {$a <=> $b} @years;
	  my @range = (); my @ranges = (); my $range;
	  for(@sorted_years)
		{ push @$range,$_ and next
		  if $range and $_-$range->[-1]==1;
		  push @ranges,($range = [$_]);
		}
	  my $years_covered = join
	  (',', map
		{ @$_>2 ?
		  "$_->[0]-$_->[-1]" :
		  @$_
		} @ranges
	  );
	  print SUMMARY "$region\t$url\t$date_of_last_update\t$no_of_subdistricts_in_region\t$subdistricts_in_region\t$no_of_records\t$no_of_records_mid\t$years_covered\n";
	}
close(SUMMARY) or die $!;

# OUTPUT THE ABSOLUTE NUMBER OF TIMES EACH NAME HAS BEEN SEEN, AND IN WHAT CONTEXT (FORENAME, MIDDLE NAME OR SURNAME)
my %all_names = ();
while((my $name,my $irrel)=each(%forenames))
	{ $all_names{$name}++; }
while((my $name,my $irrel)=each(%middle_names))
	{ $all_names{$name}++; }
my %usage_as_a_forename = (); my %usage_as_a_middle_name = (); my %usage_as_a_surname = (); my %number_of_times_used = ();
while((my $name,my $irrel)=each(%all_names))
	{ next if ($name eq '(none)');
	  my $name_uc = uc($name); # the convention is that surnames are upper case but fore- and middle names are ucfirst
	  my $num_of_times_used_as_forename = 0; my $num_of_times_used_as_middle_name = 0; my $num_of_times_used_as_surname = 0;
	  if (exists($forenames{$name}))    { $num_of_times_used_as_forename    = $forenames{$name};    }
	  if (exists($middle_names{$name})) { $num_of_times_used_as_middle_name = $middle_names{$name}; }
	  if (exists($surnames{$name_uc})) 	{ $num_of_times_used_as_surname     = $surnames{$name_uc};  }
	  $usage_as_a_forename{$num_of_times_used_as_forename}{$name}++;
	  $usage_as_a_middle_name{$num_of_times_used_as_forename}{$num_of_times_used_as_middle_name}{$name}++;
	  $usage_as_a_surname{$num_of_times_used_as_forename}{$num_of_times_used_as_surname}{$name}++;
	  $number_of_times_used{$name}{forename}    = $num_of_times_used_as_forename;
	  $number_of_times_used{$name}{middle_name} = $num_of_times_used_as_middle_name;
	  $number_of_times_used{$name}{surname}     = $num_of_times_used_as_surname;
	}
my @numbers = ();
while((my $number,my $irrel)=each(%usage_as_a_forename))
	{ push(@numbers,$number); }
my @sorted_numbers = sort {$b <=> $a} @numbers;
my %ratio_of_surname_to_forename_use = ();
foreach my $num_of_times_used_as_forename (@sorted_numbers)
	{ my $num_of_names = scalar keys %{$usage_as_a_forename{$num_of_times_used_as_forename}};
	  my $sort_by_middle_name = 0;
	  my %print_order = ();
	  my @arr1 = ();
	  while((my $name,my $irrel)=each(%{$usage_as_a_forename{$num_of_times_used_as_forename}}))
		{ my $gender = 'undetermined';
		  my $name_uc = uc($name);
		  if ((exists($genders{$name_uc})) and ($name_uc !~ /^\w{1}$/)) { $gender = $genders{$name_uc}; }
		  my $num_of_times_used_as_middle_name = $number_of_times_used{$name}{middle_name};
		  if ($num_of_names == 1)
			{ my $num_of_times_used_as_surname = $number_of_times_used{$name}{surname};
			  my $ratio_of_surname_to_forename_use = 'NA';
			  if ($num_of_times_used_as_forename > 0) { $ratio_of_surname_to_forename_use = sprintf("%.3f",($num_of_times_used_as_surname/$num_of_times_used_as_forename)); }
			  my $out_line = "$name\t$gender\t$num_of_times_used_as_forename\t$num_of_times_used_as_middle_name\t$num_of_times_used_as_surname\t$ratio_of_surname_to_forename_use";
			  push(@{$print_order{$num_of_times_used_as_middle_name}{$num_of_times_used_as_surname}},$out_line);
			}
		  else
			{ push(@arr1,[$num_of_times_used_as_middle_name,$name]);
			  $sort_by_middle_name++;
			}
		}
	  my $sort_by_surname = 0;
	  my @arr2 = ();
	  if ($sort_by_middle_name > 0)
		{ my @sorted_arr1 = map { $_->[0] } sort { $b->[1] <=> $a->[1] } map { [$_, $_->[0]] } @arr1;
		  for(my $x=0;$x<@sorted_arr1;$x++)
			{ my $num_of_times_used_as_middle_name = $sorted_arr1[$x][0];
			  my $name = $sorted_arr1[$x][1];
			  my $gender = 'undetermined';
			  my $name_uc = uc($name);
			  if ((exists($genders{$name_uc})) and ($name_uc !~ /^\w{1}$/)) { $gender = $genders{$name_uc}; }
			  my $num_of_times_used_as_surname = $number_of_times_used{$name}{surname};
			  my $num_of_names = scalar keys %{$usage_as_a_middle_name{$num_of_times_used_as_forename}{$num_of_times_used_as_middle_name}};
			  if ($num_of_names == 1)
				{ my $ratio_of_surname_to_forename_use = 'NA';
				  if ($num_of_times_used_as_forename > 0) { $ratio_of_surname_to_forename_use = sprintf("%.3f",($num_of_times_used_as_surname/$num_of_times_used_as_forename)); }
				  my $out_line = "$name\t$gender\t$num_of_times_used_as_forename\t$num_of_times_used_as_middle_name\t$num_of_times_used_as_surname\t$ratio_of_surname_to_forename_use";
				  push(@{$print_order{$num_of_times_used_as_middle_name}{$num_of_times_used_as_surname}},$out_line);
				}
			  else
				{ push(@arr2,[$num_of_times_used_as_surname,$name]);
				  $sort_by_surname++;
				}
			}
		}
	  my $sort_by_name = 0;
	  my @arr3 = ();
	  if ($sort_by_surname > 0)
		{ my @sorted_arr2 = map { $_->[0] } sort { $b->[1] <=> $a->[1] } map { [$_, $_->[0]] } @arr2;
		  for(my $x=0;$x<@sorted_arr2;$x++)
			{ my $num_of_times_used_as_surname = $sorted_arr2[$x][0];
			  my $name = $sorted_arr2[$x][1];
			  my $gender = 'undetermined';
			  my $name_uc = uc($name);
			  if ((exists($genders{$name_uc})) and ($name_uc !~ /^\w{1}$/)) { $gender = $genders{$name_uc}; }
			  my $num_of_times_used_as_middle_name = $number_of_times_used{$name}{middle_name};
			  my $num_of_names = scalar keys %{$usage_as_a_surname{$num_of_times_used_as_forename}{$num_of_times_used_as_surname}};
			  if ($num_of_names == 1)
				{ my $ratio_of_surname_to_forename_use = 'NA';
				  if ($num_of_times_used_as_forename > 0) { $ratio_of_surname_to_forename_use = sprintf("%.3f",($num_of_times_used_as_surname/$num_of_times_used_as_forename)); }
				  my $out_line = "$name\t$gender\t$num_of_times_used_as_forename\t$num_of_times_used_as_middle_name\t$num_of_times_used_as_surname\t$ratio_of_surname_to_forename_use";
				  push(@{$print_order{$num_of_times_used_as_middle_name}{$num_of_times_used_as_surname}},$out_line);
				}
			  else
				{ push(@arr3,$name);
				  $sort_by_name++;
				}
			}
		}
	  if ($sort_by_name > 0)
		{ my @sorted_arr3 = sort {$a cmp $b} @arr3;
		  foreach my $name (@sorted_arr3)
			{ my $gender = 'undetermined';
			  my $name_uc = uc($name);
			  if ((exists($genders{$name_uc})) and ($name_uc !~ /^\w{1}$/)) { $gender = $genders{$name_uc}; }
			  my $num_of_times_used_as_forename	   = $number_of_times_used{$name}{forename};
			  my $num_of_times_used_as_middle_name = $number_of_times_used{$name}{middle_name};
			  my $num_of_times_used_as_surname 	   = $number_of_times_used{$name}{surname};
			  my $ratio_of_surname_to_forename_use = 'NA';
			  if ($num_of_times_used_as_forename > 0) { $ratio_of_surname_to_forename_use = sprintf("%.3f",($num_of_times_used_as_surname/$num_of_times_used_as_forename)); }
			  my $out_line = "$name\t$gender\t$num_of_times_used_as_forename\t$num_of_times_used_as_middle_name\t$num_of_times_used_as_surname\t$ratio_of_surname_to_forename_use";
			  push(@{$print_order{$num_of_times_used_as_middle_name}{$num_of_times_used_as_surname}},$out_line);
			}
		}
	  my @num_of_times_used_as_middle_name = ();
	  while((my $num_of_times_used_as_middle_name,my $irrel)=each(%print_order))
		{ push(@num_of_times_used_as_middle_name,$num_of_times_used_as_middle_name); }
	  my @sorted_num_of_times_used_as_middle_name = sort {$b <=> $a} @num_of_times_used_as_middle_name;
	  foreach my $num_of_times_used_as_middle_name (@sorted_num_of_times_used_as_middle_name)
		{ my @num_of_times_used_as_surname = ();
		  while((my $num_of_times_used_as_surname,my $irrel)=each(%{$print_order{$num_of_times_used_as_middle_name}}))
			{ push(@num_of_times_used_as_surname,$num_of_times_used_as_surname); }
		  my @sorted_num_of_times_used_as_surname = sort {$b <=> $a} @num_of_times_used_as_surname;
		  foreach my $num_of_times_used_as_surname (@sorted_num_of_times_used_as_surname)
			{ my @print_order = @{$print_order{$num_of_times_used_as_middle_name}{$num_of_times_used_as_surname}};
			  foreach my $out_line (@print_order)
				{ my @out_line = split(/\t/,$out_line);
				  my $name = $out_line[0];
				  my $ratio_of_surname_to_forename_use = $out_line[5];
				  $ratio_of_surname_to_forename_use{$name} = $ratio_of_surname_to_forename_use;
				  my %years_this_name_is_used = ();
				  while((my $year,my $irrel)=each(%{$years_in_which_forename_used{$name}}))
					{ $years_this_name_is_used{$year}++; }
				  while((my $year,my $irrel)=each(%{$years_in_which_middle_name_used{$name}}))
					{ $years_this_name_is_used{$year}++; }
				  my $num_of_years_this_name_is_used_either_as_forename_or_middle_name = scalar keys %years_this_name_is_used;
				  my @years_this_name_is_used = ();
				  while((my $year,my $irrel)=each(%years_this_name_is_used))
					{ push(@years_this_name_is_used,$year); }
				  my @sorted_years_this_name_is_used = sort {$a <=> $b} @years_this_name_is_used;
				  my @range = (); my @ranges = (); my $range;
				  for(@sorted_years_this_name_is_used) # see http://www.perlmonks.org/?node_id=230786
					{ push @$range,$_ and next
					  if $range and $_-$range->[-1]==1;
					  push @ranges,($range = [$_]);
					}
				  my $years_in_which_this_name_is_used_either_as_forename_or_middle_name = join
				  (',', map
					{ @$_>2 ?
					  "$_->[0]-$_->[-1]" :
					  @$_
					} @ranges
				  );
				  print OUT_TOTAL_NAME_FREQ "$out_line\t$num_of_years_this_name_is_used_either_as_forename_or_middle_name\t$years_in_which_this_name_is_used_either_as_forename_or_middle_name\n";
				}
			}
		}
	}
close(OUT_TOTAL_NAME_FREQ) or die $!;
exit 1;

sub CONCATENATE_YEARS
	{ my $param = shift;
	  my %hash = %$param;
	  my $coords = '';
	  my @years = ();
	  while((my $year,my $irrel)=each(%hash))
		{ push(@years,$year); }
	  my @sorted_years = sort {$a <=> $b} @years;
	  @years = @sorted_years;
	  my $start_year = '';
	  my %years = ();
	  for(my $x=0;$x<@years;$x++)
		{ my $year = $years[$x];
		  if ($x == 0)
			{ $start_year = $year; }
		  push(@{$years{$start_year}},$year);
		  if ((defined($years[$x+1])) && ($years[$x+1] != $year+1))
			{ push(@{$years{$start_year}},$year);
			  $start_year = $years[$x+1];
			}
		}
	  my @start_years = ();
	  while((my $start_year,my $irrel)=each(%years))
		{ push(@start_years,$start_year); }
	  my @sorted_start_years = sort {$a <=> $b} @start_years;
	  foreach my $start_year (@sorted_start_years)
		{ my @arr = @{$years{$start_year}};
		  my @sorted_arr = sort {$a <=> $b} @arr;
		  my $end_year   = $sorted_arr[$#sorted_arr];
		  if ($start_year != $end_year)
			{ $coords .= "$start_year-$end_year,"; }
		  else
			{ $coords .= "$start_year,"; }
		}
	  $coords =~ s/\,$//;
	  return $coords;
	}