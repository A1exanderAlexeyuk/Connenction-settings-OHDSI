sql_target <- "select 1 as cohort_definition_id, de.person_id as subject_id,
    drug_era_start_date as cohort_start_date,
    dateadd(day, 30, drug_era_end_date) as cohort_end_date
into @cohortDatabaseSchema.plpDemo
from
(select * from @cdmDatabaseSchema.drug_era 
  inner join @cdmDatabaseSchema.concept_ancestor ca on ca.descendant_concept_id = @cdmDatabaseSchema.drug_era.DRUG_CONCEPT_ID
  where ca.ancestor_concept_id = 974166) as de 
inner join
(select person_id, min(drug_era_start_date) as first_date
    from @cdmDatabaseSchema.drug_era  
    inner join @cdmDatabaseSchema.concept_ancestor ca on ca.descendant_concept_id = @cdmDatabaseSchema.drug_era.DRUG_CONCEPT_ID
    where ca.ancestor_concept_id = 974166 group by person_id) as first_dates
on de.person_id = first_dates.person_id and de.drug_era_start_date = first_dates.first_date
" 

sql_outcome <- "insert into @cohortDatabaseSchema.plpDemo(
cohort_definition_id, subject_id, cohort_start_date,
cohort_end_date)
select 2 as cohort_definition_id, co.person_id as subject_id,
condition_start_date as cohort_start_date, condition_start_date as cohort_end_date
from
@cdmDatabaseSchema.condition_occurrence co
inner join
@cdmDatabaseSchema.concept_ancestor ca on ca.descendant_concept_id = co.condition_concept_id
where ca.ancestor_concept_id = 378253 
" 

