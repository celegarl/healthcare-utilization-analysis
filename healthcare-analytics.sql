-- ============================================================
-- HEALTHCARE UTILIZATION & PATIENT CONDITIONS ANALYSIS
-- Dataset: Synthea Synthetic Patient Data
-- Database: PostgreSQL
-- ============================================================

-- PROJECT OBJECTIVE:
-- Analyze patient demographics, healthcare utilization,
-- clinical conditions, and medication use using synthetic
-- electronic health record (EHR) data.


-- ============================================================
-- 1. PATIENT DEMOGRAPHICS
-- ============================================================

-- 1.1 Gender Distribution
-- Question: What is the gender distribution of the patient population?

SELECT
    gender,
    COUNT(*) AS patient_count
FROM patients
GROUP BY gender
ORDER BY patient_count DESC;


-- 1.2 Age Group Distribution
-- Question: How are patients distributed across age groups?

SELECT
    CASE
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, birthdate)) < 18
            THEN '0-17'
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, birthdate)) BETWEEN 18 AND 34
            THEN '18-34'
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, birthdate)) BETWEEN 35 AND 49
            THEN '35-49'
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, birthdate)) BETWEEN 50 AND 64
            THEN '50-64'
        ELSE '65+'
    END AS age_group,
    COUNT(*) AS patient_count
FROM patients
GROUP BY age_group
ORDER BY age_group;

-- ============================================================
-- 2. HEALTHCARE UTILIZATION
-- ============================================================

-- 2.1 Encounter Type Distribution
-- Question: What types of healthcare encounters are most common?

SELECT
    encounterclass,
    COUNT(*) AS total_encounters
FROM encounters
GROUP BY encounterclass
ORDER BY total_encounters DESC;


-- 2.2 Average Encounters per Patient
-- Question: On average, how many healthcare encounters does each patient have?

SELECT
    ROUND(
        COUNT(*)::NUMERIC / COUNT(DISTINCT patient),
        2
    ) AS avg_encounters_per_patient
FROM encounters;

-- 2.3 Highest-Utilization Patients
-- Question: Which patients have the highest number of healthcare encounters?

SELECT
    p.id,
    p.first,
    p.last,
    COUNT(e.id) AS total_encounters
FROM patients p
JOIN encounters e
    ON p.id = e.patient
GROUP BY
    p.id,
    p.first,
    p.last
ORDER BY total_encounters DESC
LIMIT 10;


-- 2.4 Encounter Types for the Highest-Utilization Patient
-- Question: What types of encounters account for the highest patient's utilization?

SELECT
    e.encounterclass,
    COUNT(*) AS encounter_count
FROM encounters e
WHERE e.patient = (
    SELECT patient
    FROM encounters
    GROUP BY patient
    ORDER BY COUNT(*) DESC
    LIMIT 1
)
GROUP BY e.encounterclass
ORDER BY encounter_count DESC;

-- 2.5 Healthcare Utilization by Age Group
-- Question: Which age groups have the highest healthcare utilization?

SELECT
    CASE
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.birthdate)) < 18
            THEN '0-17'
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.birthdate)) BETWEEN 18 AND 34
            THEN '18-34'
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.birthdate)) BETWEEN 35 AND 49
            THEN '35-49'
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.birthdate)) BETWEEN 50 AND 64
            THEN '50-64'
        ELSE '65+'
    END AS age_group,
    COUNT(e.id) AS total_encounters,
    COUNT(DISTINCT p.id) AS patients,
    ROUND(
        COUNT(e.id)::NUMERIC / COUNT(DISTINCT p.id),
        2
    ) AS encounters_per_patient
FROM patients p
JOIN encounters e
    ON p.id = e.patient
GROUP BY age_group
ORDER BY encounters_per_patient DESC;

-- ============================================================
-- 3. CLINICAL CONDITIONS
-- ============================================================

-- 3.1 Most Common Conditions
-- Question: Which clinical conditions affect the most unique patients?

SELECT
    description,
    COUNT(*) AS total_records,
    COUNT(DISTINCT patient) AS unique_patients
FROM conditions
GROUP BY description
ORDER BY unique_patients DESC
LIMIT 10;

-- 3.2 Conditions by Age Group
-- Question: Which conditions are most common within each age group?

WITH condition_by_age AS (
    SELECT
        CASE
            WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.birthdate)) < 18
                THEN '0-17'
            WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.birthdate)) BETWEEN 18 AND 34
                THEN '18-34'
            WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.birthdate)) BETWEEN 35 AND 49
                THEN '35-49'
            WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.birthdate)) BETWEEN 50 AND 64
                THEN '50-64'
            ELSE '65+'
        END AS age_group,
        c.description,
        COUNT(DISTINCT c.patient) AS patient_count
    FROM conditions c
    JOIN patients p
        ON c.patient = p.id
    GROUP BY age_group, c.description
),
ranked_conditions AS (
    SELECT
        age_group,
        description,
        patient_count,
        ROW_NUMBER() OVER (
            PARTITION BY age_group
            ORDER BY patient_count DESC
        ) AS rank
    FROM condition_by_age
)
SELECT
    age_group,
    description,
    patient_count
FROM ranked_conditions
WHERE rank <= 3
ORDER BY age_group, rank;