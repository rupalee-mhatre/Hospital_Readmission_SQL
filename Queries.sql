select count(*) from diabetic_data_raw;
-- Set the safe mode off for the updates 
-- If not sql throws an error because of the number of rows updated

Set SQL_SAFE_UPDATES=0

-- Step 1- Update the columns that have ? instead of Null

update diabetic_data_raw
set race=NULLIF(race,'?'),
	weight=NULLIF(weight,'?'),
    payer_code=NULLIF(payer_code,'?'),
    medical_specialty=nullif(medical_specialty,'?'),
    diag_1=nullif(diag_1,'?'),
    diag_2=nullif(diag_2,'?'),
    diag_3=nullif(diag_1,'?');
   
   -- ReSet the safe mode back on 
   Set SQL_SAFE_UPDATES=1
   
   -- Step 2- Find missing values
   Select
	Round(Sum(weight IS NULL)/Count(*) * 100,1) As pct_missing_weight,
    Round(Sum(payer_code IS NULL)/Count(*) * 100,1) As pct_missing_payer_code,
    Round(Sum(medical_specialty IS NULL)/Count(*) * 100,1) As pct_missing_medical_specialty,
    Round(Sum(diag_2 IS NULL)/Count(*) * 100,1) As pct_missing_diag2
	From diabetic_data_raw;
  
  -- Find patient numbers with repeat encounter numbers
    
    Select
     patient_nbr,
     count(*) as encounter_count
	from diabetic_data_raw
    group by patient_nbr
    having encounter_count>1
    order by encounter_count desc;
    
    -- Step 3- create a duplicate table with values of patients with repeat encounter numbers
    -- but just with the first encounter
    
    Create Table diabetic_data_dup as
    select t.*
    from diabetic_data_raw as t
    Inner join (select
		patient_nbr,
		min(encounter_id) as first_encounter
    from diabetic_data_raw
    group by patient_nbr) first_enc
    on t.patient_nbr = first_enc.patient_nbr
    and t.encounter_id=first_enc.first_encounter;
    
    select * from diabetic_data_dup;
    
    -- find discharge ids that are hospice or deceased
    
    select * from ids_mapping_raw
    where description like '%hospice%' or description like '%expired%' or description like '%deceased%';
    
-- The discharge ids are 11,13,14,19,20,21,26
-- Step 4- Delete the IDs from the new table

DELETE FROM diabetic_data_dup 
WHERE
    discharge_disposition_id IN (11 , 13, 14, 19, 20, 21, 26);
    
-- Step 5 the ids_mapping_raw data was imported incorrectly. so creating 2 seperate tables 
  
Create table discharge_disposition_map(
	discharge_disposition_id int,
    description varchar(150)
    );
    
INSERT INTO discharge_disposition_map (discharge_disposition_id, description)
VALUES
(1, 'Discharged to home'),
(2, 'Discharged/transferred to another short term hospital'),
(3, 'Discharged/transferred to SNF'),
(4, 'Discharged/transferred to ICF'),
(5, 'Discharged/transferred to another type of inpatient care institution'),
(6, 'Discharged/transferred to home with home health service'),
(7, 'Left AMA'),
(8, 'Discharged/transferred to home under care of Home IV provider'),
(9, 'Admitted as an inpatient to this hospital'),
(10, 'Neonate discharged to another hospital for neonatal aftercare'),
(11, 'Expired'),
(12, 'Still patient or expected to return for outpatient services'),
(13, 'Hospice / home'),
(14, 'Hospice / medical facility'),
(15, 'Discharged/transferred within this institution to Medicare approved swing bed'),
(16, 'Discharged/transferred/referred another institution for outpatient services'),
(17, 'Discharged/transferred/referred to this institution for outpatient services'),
(18, NULL),
(19, 'Expired at home. Medicaid only, hospice.'),
(20, 'Expired in a medical facility. Medicaid only, hospice.'),
(21, 'Expired, place unknown. Medicaid only, hospice.'),
(22, 'Discharged/transferred to another rehab fac including rehab units of a hospital.'),
(23, 'Discharged/transferred to a long term care hospital.'),
(24, 'Discharged/transferred to a nursing facility certified under Medicaid but not certified under Medicare.'),
(25, 'Not Mapped'),
(26, 'Unknown/Invalid'),
(27, 'Discharged/transferred to a federal health care facility.'),
(28, 'Discharged/transferred/referred to a psychiatric hospital of psychiatric distinct part unit of a hospital'),
(29, 'Discharged/transferred to a Critical Access Hospital (CAH).'),
(30, 'Discharged/transferred to another Type of Health Care Institution not Defined Elsewhere');
   
Create table admission_source_map(
	admission_source_id int,
    description varchar(150)
    );
    
INSERT INTO admission_source_map (admission_source_id, description)
VALUES
(1, 'Physician Referral'),
(2, 'Clinic Referral'),
(3, 'HMO Referral'),
(4, 'Transfer from a hospital'),
(5, 'Transfer from a Skilled Nursing Facility (SNF)'),
(6, 'Transfer from another health care facility'),
(7, 'Emergency Room'),
(8, 'Court/Law Enforcement'),
(9, 'Not Available'),
(10, 'Transfer from critial access hospital'),
(11, 'Normal Delivery'),
(12, 'Premature Delivery'),
(13, 'Sick Baby'),
(14, 'Extramural Birth'),
(15, 'Not Available'),
(17, NULL),
(18, 'Transfer From Another Home Health Agency'),
(19, 'Readmission to Same Home Health Agency'),
(20, 'Not Mapped'),
(21, 'Unknown/Invalid'),
(22, 'Transfer from hospital inpt/same fac reslt in a sep claim'),
(23, 'Born inside this hospital'),
(24, 'Born outside this hospital'),
(25, 'Transfer from Ambulatory Surgery Center'),
(26, 'Transfer from Hospice');


-- STEP 6 Add column for age midpoint

Alter table diabetic_data_dup
add column age_midpoint int;

select age_midpoint from diabetic_data_dup;

update diabetic_data_dup
set age_midpoint=Case
when age='0-10' then 5
when age='10-20' then 15
when age='20-30' then 25
when age='30-40' then 35
when age='40-50' then 45
when age='50-60' then 55
when age='60-70' then 65
when age='70-80' then 75
when age='80-90' then 85
when age='90-100' then 95
end;

-- Step 7 Exploratory Analysis


--  Calculate the number of each readmission type
select 
	readmitted,
    count(*) as total,
    round(count(*)/(select count(*) from diabetic_data_dup) *100,1) as percentage
    from diabetic_data_dup
    group by readmitted
    order by percentage desc;
    
    -- Calculate the number of patients with readmission <30 by age
    
    select
		age_midpoint ,
        count(*) as total_encounters,
        sum(readmitted='<30') as readmit_under_30,
        round(sum(readmitted='<30') /count(*) *100,1) as readmission_pct
        from diabetic_data_dup
        group by age_midpoint
        order by age_midpoint;
        
	-- Calculate the number of patients with readmission <30 by admission type
        
        
	select
		m.description as admission_type,
        Count(*) as total_encounters,
        round(sum(d.readmitted= '<30')/count(*)*100,1) as readmission_pct
	from diabetic_data_dup as d
    join ids_mapping_raw as m
    on d.admission_type_id=m.admission_type_id
    group by m.description
    order by readmission_pct desc;
    
    -- Advanced Analysis
    
-- CTE

With patient_risk_base as (
	select 
		encounter_id,
        patient_nbr,
        age_midpoint,
		time_in_hospital,
		num_lab_procedures,
        num_medications,
        number_diagnoses,
        number_inpatient,
        number_emergency,
        number_outpatient,
        diag_1,
        diag_2,
        diag_3,
        readmitted,
        Case when readmitted='<30' then 1 else 0 end as readmitted_less30
	from diabetic_data_dup
    )
    select * from patient_risk_base
    limit 20;
    
    -- Number of medications by age group
    With patient_risk_base as (
	select 
		encounter_id,
        age_midpoint,
        num_medications,
        readmitted,
		Case when readmitted='<30' then 1 else 0 end as readmitted_less30
	from diabetic_data_dup
    )
    select 
		encounter_id,
		age_midpoint,
        num_medications,
        readmitted,
		rank() over (partition by age_midpoint order by num_medications desc) as med_agegroup
	from patient_risk_base
    order by age_midpoint,med_agegroup
    limit 200;
    
    
    -- Number of inpatient visits quartile
    With patient_risk_base as (
	select 
		encounter_id,
        number_inpatient,
        readmitted,
		Case when readmitted='<30' then 1 else 0 end as readmitted_less30
	from diabetic_data_dup
    )
    Select
		encounter_id,
        number_inpatient,
        ntile(4) over (order by number_inpatient desc) as risk_quart
        from patient_risk_base
        
        -- categorize by medication quantity and diagnosis number
        
        select
			encounter_id,
            num_medications,
            number_diagnoses,
            case
				when num_medications <= 10 then 'Low'
                when num_medications between 11 and 20 then 'medium'
                else 'high'
			end as medication_amt_grp,
            case
				when number_diagnoses <= 5 then 'Low complexity'
                when number_diagnoses between 6 and 9 then 'Moderate complexity'
                else 'High complexity'
			end as diagnosis_num_grp
            from diabetic_data_dup;
            
            
-- diag_1 categories
-- 390-459: diseases of circulatory system
-- 460-519: diseases of respiratory system
-- 520-579 : diseases of the digestive system
-- 580-629 : diseases of the genitourinary system
-- 800-999: injury and poisining

with diag_categorized as (
	select 
		encounter_id,
        readmitted,
        case
        when diag_1 like '250%' then 'Diabetes'
        when cast(left(diag_1,3) as unsigned) between 390 and 459 then 'circulatory system'
		when cast(left(diag_1,3) as unsigned) between 460 and 519 then 'respiratory system'
        when cast(left(diag_1,3) as unsigned) between 520 and 579 then 'digestive system'
        when cast(left(diag_1,3) as unsigned) between 580 and 629 then 'genitourinary system'
        when cast(left(diag_1,3) as unsigned) between 800 and 999 then 'injury and poisining'
        else 'other'
	end as diag_cat,
    Case when readmitted='<30' then 1 else 0 end as readmitted_less30
    from diabetic_data_dup
    where diag_1 IS NOT NULL
    )
    select 
		diag_cat,
        count(*) as total_encounters,
        round(avg(readmitted_less30)*100,1) as readmission_pct
        from diag_categorized
        group by diag_cat
        having avg(readmitted_less30)> (
        select avg(readmitted_less30) from diag_categorized
        )
	order by readmission_pct desc;
    
    -- Top diagnosis category for readmission
    -- Use above query
    
    -- Does a medication change at discharge affect readmission
    select
		`change`,
        COUNT(*) as total_encounters,
        round(sum(readmitted= '<30')/count(*)*100,1) as readmission_pct
        from diabetic_data_dup
        group by `change`;
        
    -- Discharge disposition impact
    select
		m.description as discharge_disposition,
		count(*) as total_encounters,
		round(sum(d.readmitted= '<30')/count(*)*100,1) as readmission_pct    
     from diabetic_data_dup d
     inner join discharge_disposition_map m
     on d.discharge_disposition_id=m.discharge_disposition_id
     group by m.description
     having total_encounters > 100
     order by readmission_pct desc
     
     -- A1C testing and readmission 
     select 
		A1Cresult,
        count(*) as total_encounters,
        round(sum(readmitted= '<30')/count(*)*100,1) as readmission_pct  
        from diabetic_data_dup 
        group by A1Cresult
     
     