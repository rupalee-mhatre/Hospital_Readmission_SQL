<img width="1998" height="1333" alt="image" src="https://github.com/user-attachments/assets/86716ade-f843-401e-b11a-f5ae62d31a48" />


Hospital Readmission Analysis
 
Business Problem:
1. Failure to provide diabetes care increases the managing cost for the hospitals when patients are readmitted within 30 days of their discharge. It also impacts the mortality of patients who may face complications related to diabetes
2. The dataset represents ten years (1999-2008) of clinical care at 130 US hospitals and integrated delivery networks. Each row concerns hospital records of patients diagnosed with diabetes, who underwent laboratory, medications, and stayed up to 14 days.
3. The goal is to determine high risk patients with early readmission of the patient within 30 days of discharge and prevent such readmissions

Data and Tools:
1. Dataset: Diabetes 130-US Hospitals for Years 1999-2008
2. No. of records: ~100,000
3. Description:The dataset represents ten years (1999-2008) of clinical care at 130 US hospitals and integrated delivery networks
4. Database: MySQL Workbench
5. Techniques Used: multi table joins, subqueries, case-based risk tiering, CTEs , Windows Functions (RANK, NTILE)

Approach / Methodology:
 Data Cleaning:
 	1. Replaced missing values with NULL
2. Removed column with 97% missing values
3. Maintained only one encounter per patient to avoid duplicates
4. Removed patients that were deceased or discharged to hospice

Exploratory Analysis:
1. Analyzed readmission rates by age, admission type and diagnosis category

Advanced Analysis:
Built a high-risk patient group with CTE, applied window function to rank patients by risk, grouped them by medication use and number of diagnosis and determined diagnosis categories above average readmission rates.

Findings:
1. Circulatory and diabetes had the highest readmission rates exceeding the average readmission rate.
2. Patients with higher prior in-patient visits had an elevated risk of readmission.
3. Discharge dispositions like Discharged/transferred to another rehab fac including rehab units of a hospital, Discharged/transferred to another rehab fac including rehab units of a hospital  showed higher readmission rates than those discharged at home
4. AIC testing during the stay  and the resultants Medication change at discharge reduced the chances of readmission.

Recommendations:
1. Patients with diabetes and circulatory health conditions have higher readmission rates so additional care should be provided to these patients.
2. Patients with previous hospital visits should receive planned discharge follow-ups
3. Better co-ordination with facilities if the patient is discharged at facilities with higher readmission rates and areas of improvement for such facilities should be reviewed
4. HbAIC tests should be administered regularly to a patient during the hospital stay and the medications should be adjusted accordingly to reduce the chances of patient readmission
