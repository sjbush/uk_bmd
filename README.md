# uk_bmd
This repository contains the datasets described in the paper "The UK Local BMD: A Full Name Onomastic Resource", alongside the scripts necessary to generate them.

The raw data (not included in this repo) are sourced from the [UK Local BMD](https://www.ukbmd.org.uk/localbmdproject), a volunteer project to transcribe the birth, marriage and death records of England and Wales (more specifically, from the 12 cities, counties and regions of [Bath](http://www.bathbmd.org.uk/), [Berkshire](https://www.berkshirebmd.org.uk/), [Cheshire](http://www.cheshirebmd.org.uk/), [Cumbria](http://www.cumbriabmd.org.uk/), [Kingston-upon-Thames](https://kingstonbmd.org.uk/), [Lancashire](http://www.lancashirebmd.org.uk/), [North Wales](http://www.northwalesbmd.org.uk/), [Shropshire](http://www.shropshirebmd.info/), [Staffordshire](https://www.staffordshirebmd.org.uk/), [West Midlands](https://www.westmidlandsbmd.org.uk/), [Wiltshire](http://www.wiltshirebmd.org.uk/), and [Yorkshire](http://www.yorkshirebmd.org.uk/)), and processed to generate a rare onomastic resource - one which contains unredacted full names.

The two subdirectories in this repo, 'dataset_B' and 'dataset_D', represent data processed from 23,395,527 birth and 9,823,051 death records, respectively, with the contents of each file described in the paper. Birth records span the period 1837 - 2014 and death records 1733 - 2009, in both cases representing an assumed unbiased population sample.

Note that the "UK BMD" is somewhat misleadingly named as neither dataset contains records from Scotland or Northern Ireland. This is due to differences in their legislative frameworks and history of civil registration relative to England and Wales. In the latter, civil registration began on the 1st July 1837 although only became compulsory from 1st January 1875 with the passing of the Births and Deaths Registration Act 1874. Prior to 1837, records of baptisms, marriages, and funerals can be found in local parish registers although as these were maintained by Anglican clergy, they wouldn’t have included non-conformists (among others).

The scripts, which should be run in numbered order, perform the following processing steps:

**1a.predict_gender_of_name_using_US_SSA.pl**

**1b.predict_gender_of_name_using_UK_ONS.pl**

**1c.predict_gender_of_name_using_UK_NRS.pl**

**1d.predict_gender_of_name_using_Canada_Alberta.pl**

These scripts parse four birth registration datasets, each of which represent official government statistics, to record the genders assigned to each name. These datasets are obtained from the US Social Security Administration, the UK Office for National Statistics (ONS), the National Records of Scotland, and the Government of Alberta, Canada. Note that each dataset acknowledges only two genders.

**2.predict_gender_of_name_by_combining_datasets.pl**

This script pools the count data from the four aforementioned datasets to make one of five gender classifications per name:

male - the name was more frequently assigned to males for _every_ year in which it was recorded

female - the name was more frequently assigned to females for _every_ year in which it was recorded

mostly male - the name was _not_ more frequently assigned to males for _every_ year in which it was recorded but by total number of birth records (summed across all years), the name was more commonly given to males than females

mostly female - the name was _not_ more frequently assigned to females for _every_ year in which it was recorded but by total number of birth records (summed across all years), the name was more commonly given to females than males

undetermined - the name could not be automatically gender-typed because there was an even number of male and female records

This pooled list of gender classifications is used in subsequent scripts to gender-type names in the UK BMD (within which, gender was not recorded). Names present in the UK BMD but not this list are, by default, "undetermined" gender.

**3a.parse_birth_records.pl**

**3b.parse_death_records.pl**

These scripts parse the UK BMD's birth and death records, respectively, generating a number of tab-separated plain text files containing summary statistics including the absolute and relative (percentage) count of each first and middle name per year.

**4a.compare_total_cts_per_year_for_B_vs_D.pl**

**4b.compare_total_cts_per_year_for_B_vs_ONS.pl**

These scripts perform internal and external validation of the processed dataset, respectively.

Script 4a compares the total number of records per forename in the ‘B’ and ‘D’ datasets to find (as expected) a strong positive correlation between them. This is a crude sanity-test of the data and although not controlling for differences in either temporal or geographical scope, nevertheless suggests that both datasets are, correctly, randomly sampling from the same population.

Script 4b compares the total number of records per forename in the ‘B’ dataset to the total number of records per forename in the UK ONS dataset. This analysis was restricted to the years 1996 - 2007 as in this period the two datasets had a substantive number of records in common (the ‘B’ dataset has >10,000 records per year for each of these years). Unfortunately, it was not possible to compare the ‘D’ dataset with the ONS dataset due to paucity of records in the years they have in common.

**5.count_how_many_first_and_middle_names_in_B_and_D.pl**

This script determines how many different first names and middle names there are in each of the B and D datasets and how many are unique to either.
