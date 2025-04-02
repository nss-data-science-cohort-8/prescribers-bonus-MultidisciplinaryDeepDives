--EDA: 


--Q1:

SELECT 
	specialty_description, 
    SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
  USING(npi)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY specialty_description
ORDER BY specialty_description
;


--Q2:

SELECT 
	specialty_description, 
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
  USING(npi)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY specialty_description
UNION
SELECT 
	'Total' AS specialty_description, 
    SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
  USING(npi)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
;



 
--Q3:

SELECT 
  CASE 
    WHEN specialty_description IS NULL THEN 'Total'
    ELSE specialty_description
  END AS specialty_description,
  SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
  USING(npi)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY GROUPING SETS (
  (specialty_description),
  ()
)
ORDER BY 
  CASE 
    WHEN specialty_description = 'Total' THEN 2
    ELSE 1
  END,
  specialty_description
;

--For close comparison:

SELECT 
  CASE 
    WHEN specialty_description IS NULL THEN 'Total'
    ELSE specialty_description
  END AS specialty_description,
  SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
  USING(npi)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY specialty_description;




--Q4:


SELECT 
  CASE 
    WHEN specialty_description IS NULL AND opioid_drug_flag IS NULL THEN 'Total'
    ELSE specialty_description
  END AS specialty_description,
  CASE 
    WHEN opioid_drug_flag IS NULL AND specialty_description IS NOT NULL THEN 'Subtotal'
    ELSE opioid_drug_flag
  END AS opioid_drug_flag,
  SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
  USING(npi)
INNER JOIN drug
  USING(drug_name)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY GROUPING SETS (
  (),                              -- Grand total
  (opioid_drug_flag),              -- Subtotal by opioid flag
  (specialty_description),         -- Subtotal by specialty
  (specialty_description, opioid_drug_flag)  -- Detail level (optional)
)
--optional section for ordering:
ORDER BY 
  CASE
    WHEN specialty_description = 'Total' THEN 1
    WHEN specialty_description IS NULL THEN 2
	ELSE 3
  END,
  specialty_description,
  CASE
    WHEN opioid_drug_flag IS NULL THEN 1
    WHEN opioid_drug_flag = 'Subtotal' THEN 2
    ELSE 3
  END,
  opioid_drug_flag DESC;





--Q5:

SELECT 
  CASE 
    WHEN specialty_description IS NULL AND opioid_drug_flag IS NULL THEN 'Total'
    ELSE specialty_description
  END AS specialty_description,
  opioid_drug_flag,
  SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
  USING(npi)
INNER JOIN drug
  USING(drug_name)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY ROLLUP(opioid_drug_flag, specialty_description)
--optional section for ordering:
ORDER BY 
  CASE
    WHEN specialty_description = 'Total' THEN 1
    WHEN specialty_description IS NULL THEN 2
    ELSE 3
  END,
  specialty_description,
  CASE
    WHEN opioid_drug_flag IS NULL THEN 1
    WHEN opioid_drug_flag = 'Subtotal' THEN 2
	ELSE 3
  END,
  opioid_drug_flag DESC
;


--Q6:



SELECT 
  CASE 
    WHEN specialty_description IS NULL AND opioid_drug_flag IS NULL THEN 'Total'
    ELSE specialty_description
  END AS specialty_description,
  opioid_drug_flag,
  SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
  USING(npi)
INNER JOIN drug
  USING(drug_name)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY ROLLUP(specialty_description, opioid_drug_flag)
ORDER BY 
  CASE
    WHEN specialty_description IS NULL AND opioid_drug_flag IS NULL THEN 1
    WHEN opioid_drug_flag IS NULL THEN 2
    ELSE 3
  END,
  specialty_description,
  opioid_drug_flag;




--Q7:


SELECT 
  CASE 
    WHEN specialty_description IS NULL AND opioid_drug_flag IS NULL THEN 'Total'
    ELSE specialty_description
  END AS specialty_description,
  opioid_drug_flag,
  SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
  USING(npi)
INNER JOIN drug
  USING(drug_name)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY CUBE(specialty_description, opioid_drug_flag)
ORDER BY 
  CASE
    WHEN specialty_description IS NULL AND opioid_drug_flag IS NULL THEN 1
    WHEN specialty_description IS NULL THEN 2
    WHEN opioid_drug_flag IS NULL THEN 3
    ELSE 4
  END,
  specialty_description,
  opioid_drug_flag;



--Q8:


CREATE EXTENSION tablefunc;  --IN ORDER TO USE THE CROSSTAB func, one must (one time per database) run the command CREATE EXTENSION tablefunc;

 

SELECT * 
FROM crosstab(                          
'WITH opioid_labels AS (
	SELECT * 
	FROM
		(SELECT drug_name, generic_name,
			CASE 
				WHEN generic_name LIKE ''%HYDROCODONE%'' THEN ''HYDROCODONE''
				WHEN generic_name LIKE ''%OXYCODONE%'' THEN ''OXYCODONE''
				WHEN generic_name LIKE ''%OXYMORPHONE%'' THEN ''OXYMORPHONE''
				WHEN generic_name LIKE ''%MORPHINE%'' THEN ''MORPHINE''
				WHEN generic_name LIKE ''%CODEINE%'' THEN ''CODEINE''
				WHEN generic_name LIKE ''%FENTANYL%'' THEN ''FENTANYL''
			END AS label
		FROM drug) AS labels
		WHERE label IS NOT NULL
		ORDER BY drug_name
	)
 SELECT 
	nppes_provider_city AS city,   
	label, 
	SUM(total_claim_count)
 FROM prescription
 INNER JOIN opioid_labels
	USING (drug_name)
 INNER JOIN prescriber
	USING (npi)
 WHERE nppes_provider_city IN (''NASHVILLE'', ''MEMPHIS'', ''KNOXVILLE'', ''CHATTANOOGA'')
 GROUP BY label, city
 ORDER BY city, label') AS (     -- transform into pivot table: the outer SELECT's 3 terms -- SELECT rows, columns, values
	city text,
	CODEINE numeric,
	FENTANYL numeric,
	HYDROCODONE numeric,
	MORPHINE numeric,
	OXYCODONE numeric,
	OXYMORPHONE numeric
);