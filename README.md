# uk_bmd
This repository contains the datasets described in the paper "The UK Local BMD: A Full Name Onomastic Resource", alongside the scripts necessary to generate them.

The raw data (not included in this repo) are sourced from the [UK Local BMD](https://www.ukbmd.org.uk/localbmdproject), a volunteer project to transcribe the birth, marriage and death records of England and Wales (more specifically, from the 12 cities, counties and regions of [Bath](http://www.bathbmd.org.uk/), [Berkshire](https://www.berkshirebmd.org.uk/), [Cheshire](http://www.cheshirebmd.org.uk/), [Cumbria](http://www.cumbriabmd.org.uk/), [Kingston-upon-Thames](https://kingstonbmd.org.uk/), [Lancashire](http://www.lancashirebmd.org.uk/), [North Wales](http://www.northwalesbmd.org.uk/), [Shropshire](http://www.shropshirebmd.info/), [Staffordshire](https://www.staffordshirebmd.org.uk/), [West Midlands](https://www.westmidlandsbmd.org.uk/), [Wiltshire](http://www.wiltshirebmd.org.uk/), and [Yorkshire](http://www.yorkshirebmd.org.uk/)), and processed to generate a rare onomastic resource - one which contains unredacted full names.

The two subdirectories in this repo, 'dataset_B' and 'dataset_D', represent data processed from 23,395,527 birth and 9,823,051 death records, respectively, with the contents of each file described in the paper. These include the total count of each name registered per year. Birth records span the period 1837 - 2014 and death records 1733 - 2009, in both cases representing an assumed unbiased population sample.

**IMPORTANT**: the years shown in both datasets represent the known or imputed year of birth, and in this respect, the two datasets are directly comparable. To repeat: the years shown in the 'death' dataset do not represent the year of death; they represent the year of birth (i.e. year of death - age at death, unless otherwise specified). Unfortunately, age at death was not provided for records in Cumbria, Shropshire, the West Midlands and the vast majority of data from North Wales, and as such, no (or very few) death records could be used from those regions.

# A Note on the Name

The "UK BMD" is somewhat misleadingly named as it does not contain records from Scotland or Northern Ireland. This is due to differences in their legislative frameworks and history of civil registration relative to England and Wales. In the latter, civil registration began on the 1st July 1837 although only became compulsory from 1st January 1875 with the passing of the Births and Deaths Registration Act 1874.

Prior to 1837, records of baptisms, marriages, and funerals can be found in local parish registers although as these were maintained by Anglican clergy, they wouldn’t have included non-conformists (among others).

# Record Parsing Criteria

The BMD records contain both 'forename(s)' and 'surname' fields, with the latter always capitalised.

These scripts parse the 'forename(s)' field to produce one 'first name' and zero or more 'middle names' on the basis that spaces separate individual names.

The name before the first space was considered the first name and all subsequent names, space delimited, were considered middle names. For example, _Ellen Sarah Jane SMITH_ has the first name _Ellen_, two middle names, _Sarah_ and _Jane_, and the surname _SMITH_ but _Sarahjane Ellen SMITH_ has one first name, _Sarahjane_, one middle name, _Ellen_, and one surname, _SMITH_.

Nevertheless, there are exceptions to this. The records were parsed using a small number of criteria, some to exclude them from consideration and others to make light edits. These are as follows:

## Criteria for exclusion

Records were excluded if the 'forename(s)' field:
* did not contain at least one alphabetical character (i.e. A to Z, irrespective of case)
* contained a number
* contained either of the symbols: ? & ( ) [ ]
  * these generally denote ambiguous transcription or a description appended to the name, such as _John Son of William & Mary_
* exactly matched any of the following phrases: Newborn, Not Named, Un-named, Unnamed, Unknown, Undetermined, No Name, No First Name, Name Not Given, Registered, Re-registered, Infant Girl, Infant Boy, Infant Female, Infant Male, Male Infant, Female Infant, Baby Female, Baby Male, Unchristened, Deceased
* contained the clause _" of "_ or _" Of "_, noting spaces between the word
	* this invariably matches a descriptive phrase instead of a name, such as in birth records beginning _Child of_, _Son of_ or _Daughter of_, and in death records beginning _Late of_
* for some regions (Bath, Cumbria, Shropshire, West Midlands, Wiltshire, Yorkshire), records had a unique reference number but for others (Berkshire, Cheshire, Kingston, Lancashire, North Wales, Staffordshire) multiple different records could share the same reference. In this case, the reference number refers to a processing batch, often (but not always) of around five records at a time.
	* for those regions where there is meant to be a one-to-one correspondence between record and reference number, what do we do when more than one record has that number?
	* we could exclude them as a matter of course, but on manual inspection we find there is a good reason why this has happened
	* it is either because the name is complex and there is ambiguity in the "forenames" and "surname" fields, *or* because the record did not include all names *or* (in the case of death records) because the record included prefered names as opposed to the literal birth name
	* e.g. _Brian Armstrong- CLIFFORD_ and _Brian ARMSTRONG-CLIFFORD_ - an example of the first
	* _John ALEXANDER_ and _Jack ALEXANDER_ - an example of the second
	* _Katherine Helen ANGUS_ and _Kit ANGUS_, and _Henry Frederick John ANDREWS_ and _Harry ANDREWS_, respectively - both examples of the third (and the second)
	* only manual inspection can rescue records of the second and third category, but we can automate rescue of the first
	* the way we do this is to convert all possible names associated with a given reference into a gapless capitalised string, and then count the number of strings associated with that reference
	* if there is only one string (e.g. _BRIANARMSTRONG-CLIFFORD_), then what this means is that irrespective of the number of records associated with that reference ID, the names are the same
	* in that case, we allow one of these records to be processed, randomly chosen, and exclude the others

## Criteria for editing

Records were edited according to the following criteria:
* if the forenames field began with either of the following - _Colonel, Corporal, Countness, Doctor, General, Lady, Lord, Major, Prince, Reverend, Sergeant_ - the text was removed
	* this is a unique complication with death records: they sometimes contain titles which must first be omitted, otherwise they may mistakenly be interpreted as names
* if the forenames field had one first name ending in a hyphen and only one middle name, then the latter is appended to the former - unless the middle name is an initial (because there is not enough information to go on)
	* e.g. _Ann- Marie FLYNN_ is edited to _Ann-Marie FLYNN_
* if the forenames field had one middle name and that name is "-" then it is treated as a placeholder character meaning "not applicable", and so removed
	* e.g. _Ann - FLYNN_ is edited to _Ann FLYNN_
* if the middle name contains multiple hyphens, e.g. _E-----_, then remove all of them and leave only the initial
	* this is a sign that the transcription was incomplete
* if either first or middle name was a conventional abbreviation, it was expanded, and if an obvious typo, amended (noting the subjective nature of this edit)
	* these are: _Wm_ to _William_, _Edwd_ to _Edward_, _Geo_ to _George_
	* for a full list, see the two-column file "names_to_revise.txt"; the leftmost column is a name as it appears in the BMD, the rightmost how it is amended
* if the forenames field had multiple middle names, the last of which ended in a hyphen, then we assume that is the first part of a compound surname - unless either middle name is an initial (because there is not enough information to go on) or the surname is already hyphenated
	* e.g. _Ann Marie Hucklebury- FLYNN_ is edited to _Ann Marie HUCKLEBURY-FLYNN_
	* note that there are many instances (mostly historical) where a familial surname has been used in a middle name position; we would assume _Ann Marie Hucklebury FLYNN_ (no hyphen) is one of them
	* further support for the assumption that the last middle name, if ending in a hyphen, is actually a compound surname comes from the presence of multiple people from the same area with the same compound, dying in close proximity (these are probably siblings)
	* e.g. the deaths of _Courtenay Sandilands Wynell- MAYOW_ and _Robert Lawrence Wynell- MAYOW_

There will inevitably be a number of errors remaining in the final, processed, dataset.

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
