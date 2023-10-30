# parse the list of first and middle names to identify possible typos for manual review
# these are names where there are at least two of the same character at the start or end of the name, or three consecutive characters anywhere in it
# this is a quick but crude way of drawing attention to *possible* errors. Note they won't ALL be typos, e.g. Aaron or Llewellyn.

use strict;
use warnings;

# REQUIREMENTS
my $in_file1 = 'dataset_B/all_first_names.txt';  # from 3a.parse_birth_records.pl
my $in_file2 = 'dataset_B/all_middle_names.txt'; # from 3a.parse_birth_records.pl
my $in_file3 = 'dataset_D/all_first_names.txt';  # from 3b.parse_death_records.pl
my $in_file4 = 'dataset_D/all_middle_names.txt'; # from 3b.parse_death_records.pl

# OUTPUT
my $out_file = 'possible_typos.txt';
open(OUT,'>',$out_file) or die $!;

my %candidate_typos = ();
for(my $x=0;$x<=3;$x++)
	{ my $in_file = '';
	  if    ($x == 0) { $in_file = $in_file1; }
	  elsif ($x == 1) { $in_file = $in_file2; }
	  elsif ($x == 2) { $in_file = $in_file3; }
	  elsif ($x == 3) { $in_file = $in_file4; }
	  open(IN,$in_file) or die $!;
	  while(<IN>)
		{ next if ($. == 1);
		  my $line = $_; chomp($line);
		  my @line = split(/\t/,$line);
		  my $name = $line[0];
		  
		  # are the first two letters the same?
		  if ($name =~ /^(\w{1})(\w{1})(.*?)$/)
			{ my $first_letter = $1; my $second_letter = $2;
			  if ((uc($first_letter)) eq (uc($second_letter)))
				{ $candidate_typos{$name}++; }
			}
		  
		  # are the last two letters the same?
		  if ($name =~ /^(.*?)(\w{1})(\w{1})$/)
			{ my $last_letter = $1; my $last_but_one_letter = $2;
			  if ((uc($last_letter)) eq (uc($last_but_one_letter)))
				{ $candidate_typos{$name}++; }
			}
		  
		  # are there three consecutive characters anywhere in the name?
		  if (($name =~ /^.+?(\w{1})(\w{1})(\w{1}).+?$/) or ($name =~ /^.*?(\w{1})(\w{1})(\w{1}).*?$/) or ($name =~ /^.*(\w{1})(\w{1})(\w{1}).*$/))
			{ my $first_letter = $1; my $second_letter = $2; my $third_letter = $3;
			  if ((uc($first_letter)) eq (uc($second_letter)) eq (uc($third_letter)))
				{ $candidate_typos{$name}++; }
			}
		}
	  close(IN) or die $!;
	}
my @names = ();
while((my $name,my $irrel)=each(%candidate_typos))
	{ push(@names,$name); }
my @sorted_names = sort {$a cmp $b} @names;
foreach my $name (@sorted_names)
	{ print OUT "$name\n";
	}

close(OUT) or die $!;
exit 1;