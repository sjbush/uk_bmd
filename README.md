# uk_bmd
This repository contains the datasets described in the paper "The UK Local BMD: A Full Name Onomastic Resource", alongside the scripts necessary to generate them.

The raw data (not included in this repo) are sourced from the [UK Local BMD](https://www.ukbmd.org.uk/localbmdproject), a volunteer project to transcribe the birth, marriage and death records of England and Wales (more specifically, from the 12 cities, counties and regions of [Bath](http://www.bathbmd.org.uk/), [Berkshire](https://www.berkshirebmd.org.uk/), [Cheshire](http://www.cheshirebmd.org.uk/), [Cumbria](http://www.cumbriabmd.org.uk/), [Kingston-upon-Thames](https://kingstonbmd.org.uk/), [Lancashire](http://www.lancashirebmd.org.uk/), [North Wales](http://www.northwalesbmd.org.uk/), [Shropshire](http://www.shropshirebmd.info/), [Staffordshire](https://www.staffordshirebmd.org.uk/), [West Midlands](https://www.westmidlandsbmd.org.uk/), [Wiltshire](http://www.wiltshirebmd.org.uk/), and [Yorkshire](http://www.yorkshirebmd.org.uk/)), and processed to generate a rare onomastic resource - one which contains unredacted full names.

The two subdirectories in this repo, 'dataset_B' and 'dataset_D', represent data processed from 23,395,527 birth and 9,823,051 death records, respectively, with the contents of each file described in the paper. These include the total count of each name registered per year. Birth records span the period 1837 - 2014 and death records 1733 - 2009, in both cases representing an assumed unbiased population sample.

**IMPORTANT**: the years shown in both datasets represent the known or imputed year of birth, and in this respect, the two datasets are directly comparable. To repeat: the years shown in the 'death' dataset do not represent the year of death; they represent the imputed year of birth (i.e. year of death - age at death). Unfortunately, age at death was not provided for records in Cumbria, Shropshire, the West Midlands and the vast majority of data from North Wales, and as such, no (or very few) death records could be used from those regions.

# A Note on the Name

The "UK BMD" is somewhat misleadingly named as it does not contain records from Scotland or Northern Ireland. This is due to differences in their legislative frameworks and history of civil registration relative to England and Wales. In the latter, civil registration began on the 1st July 1837 although only became compulsory from 1st January 1875 with the passing of the Births and Deaths Registration Act 1874.

Prior to 1837, records of baptisms, marriages, and funerals can be found in local parish registers although as these were maintained by Anglican clergy, they wouldn’t have included non-conformists (among others).

# Scripts

The scripts, which should be run in numbered order, perform the following processing steps:

## Gender prediction

>**1a.predict_gender_of_name_using_US_SSA.pl**

>**1b.predict_gender_of_name_using_UK_ONS.pl**

>**1c.predict_gender_of_name_using_UK_NRS.pl**

>**1d.predict_gender_of_name_using_Canada_Alberta.pl**

These scripts parse four birth registration datasets, each of which represent official government statistics, to record the gender (more precisely, sex assigned at birth) associated with each name.

These scripts replicate the method described by [Blevins and Mullen 2015](http://www.digitalhumanities.org/dhq/vol/9/3/000223/000223.html) and implemented, with guidelines for responsible use, [here](https://github.com/lmullen/gender). Although a pragmatic approach to predicting gender it is, to quote their paper, a "blunt tool to study a complex subject". Note in particular that these are state-generated datasets which acknowledge only two genders, and that the method can only provide population-level classifications of the gender of each name - individual usage may differ.

The four datasets used by these scripts are obtained from the [US Social Security Administration](https://www.ssa.gov/OACT/babynames/names.zip), the [UK Office for National Statistics (ONS)](https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/livebirths/bulletins/babynamesenglandandwales/2021/relateddata), the [National Records of Scotland](https://www.nrscotland.gov.uk/statistics-and-data/statistics/statistics-by-theme/vital-events/names/babies-first-names), and the [Government of Alberta, Canada](https://open.alberta.ca/opendata/frequency-and-ranking-of-baby-names-by-year-and-gender).

The US dataset contains the first names and gender of all US Americans with a social security number, with names registered to fewer than 5 people a year excluded, whilst the UK and Canadian datasets are full population samples of all live births in their respective regions. The UK ONS dataset excludes names registered to fewer than 3 people a year whereas the NRS and Alberta datasets do not require a minimum number of births per name. For further details as to how these datasets were compiled and their coverage, please refer to their respective URLs.

>**2.predict_gender_of_name_by_combining_datasets.pl**

This script pools the count data from the four aforementioned datasets to make one of five gender classifications per name:

- male - the name was more frequently assigned to males for _every_ year in which it was recorded

- female - the name was more frequently assigned to females for _every_ year in which it was recorded

- mostly male - the name was _not_ more frequently assigned to males for _every_ year in which it was recorded but by total number of birth records (summed across all years), the name was more commonly given to males than females

- mostly female - the name was _not_ more frequently assigned to females for _every_ year in which it was recorded but by total number of birth records (summed across all years), the name was more commonly given to females than males

- undetermined - the name could not be automatically gender-typed because there was an even number of male and female records

This pooled list of gender classifications is used in subsequent scripts to gender-type names in the UK BMD (within which, gender was not recorded). Names present in the UK BMD but not this list are, by default, "undetermined" gender.

## Birth and death record parsing

>**3a.parse_birth_records.pl**

>**3b.parse_death_records.pl**

These scripts parse the UK BMD's birth and death records, respectively, generating a number of tab-separated plain text files containing summary statistics including the absolute and relative (percentage) count of each first and middle name per year.

## Internal and external validation

>**4a.compare_total_cts_per_year_for_B_vs_D.pl**

>**4b.compare_total_cts_per_year_for_B_vs_ONS.pl**

These scripts perform internal and external validation of the processed dataset, respectively.

Script 4a compares the total number of records per forename in the ‘B’ and ‘D’ datasets to find (as expected) a strong positive correlation between them. This is a crude sanity-test of the data and although not controlling for differences in either temporal or geographical scope, nevertheless suggests that both datasets are, correctly, randomly sampling from the same population.

Script 4b compares the total number of records per forename in the ‘B’ dataset to the total number of records per forename in the UK ONS dataset. This analysis was restricted to the years 1996 - 2007 as in this period the two datasets had a substantive number of records in common (the ‘B’ dataset has >10,000 records per year for each of these years). Unfortunately, it was not possible to compare the ‘D’ dataset with the ONS dataset due to paucity of records in the years they have in common.

>**5.count_how_many_first_and_middle_names_in_B_and_D.pl**

This script determines how many different first names and middle names there are in each of the B and D datasets and how many are unique to either.

# Figures

The four figures of the paper were created using [R](https://www.r-project.org/) with packages [ggplot2](https://ggplot2.tidyverse.org/) and [scales](https://scales.r-lib.org/). Code is available as comments within the following scripts:

Figure 1: 3b.parse_death_records.pl

Figure 2: 5.compare_total_cts_per_year_for_B_vs_D.pl

Figure 3: 6.compare_total_cts_per_year_for_B_vs_ONS.pl

Figure 4: in both 3a.parse_birth_records.pl and 3b.parse_death_records.pl

# Copyright Statement

The website hosting [the UK local BMD project](http://www.ukbmd.org.uk) is operated by Weston Technologies Limited (Crewe, Cheshire, UK). This company is the owner or license-holder of the intellectual property constituting the raw birth and death records, as detailed [here](https://www.ukbmd.org.uk/TermsAndConditions).

Under section 29A of the UK Copyright, Designs and Patents Act 1988, a copyright exception permits copies to be made of lawfully accessible material in order to conduct text and data mining for non-commercial research.

Consistent with this, the processed datasets presented here are the result of text-mining and neither reproduce any given birth or death record in their entirety, nor make it possible for them to be reconstructed.

The processed data in this repo are made available for non-commercial research purposes only.
