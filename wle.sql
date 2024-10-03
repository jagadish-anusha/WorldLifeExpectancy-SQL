#Import the csv file from wizard or use the SQL file 
use projects;

#Describe the data colums
desc worldlifexpectancy;

#Get the data
SELECT * FROM worldlifexpectancy;

#Get the total number of rows in the data
SELECT COUNT(*)
FROM worldlifexpectancy;

#STEP 1 - DATA CLEANING

#For every combination of Country and Year the row should be unique
SELECT country, year , CONCAT(country,' ',year), COUNT(CONCAT(country,' ',year))  AS duplicates
FROM worldlifexpectancy
GROUP BY country, year, CONCAT(country,' ',year)
HAVING COUNT(CONCAT(country,' ',year)) >1;

SELECT *
FROM(
		SELECT row_id, CONCAT(country,' ',year),ROW_NUMBER() OVER(PARTITION BY CONCAT(country,' ',year) ORDER BY 	CONCAT(country,' ',year) ) AS duplicates
		FROM worldlifexpectancy
) AS Row_Num
WHERE duplicates>1
;

#Delete the duplicates
DELETE FROM worldlifexpectancy 
WHERE row_ID  IN 
		(
		SELECT row_id
		FROM(
				SELECT row_id, CONCAT(country,' ',year),ROW_NUMBER() OVER(PARTITION BY CONCAT(country,' ',year) ORDER BY 	CONCAT(country,' ',year) ) AS duplicates
				FROM worldlifexpectancy
		) AS Row_Num
		WHERE duplicates>1
	);
    
    
#Check again if there are any duplicates
SELECT *
FROM(
		SELECT row_id, CONCAT(country,' ',year),ROW_NUMBER() OVER(PARTITION BY CONCAT(country,' ',year) ORDER BY 	CONCAT(country,' ',year) ) AS duplicates
		FROM worldlifexpectancy
) AS Row_Num
WHERE duplicates>1
;



#Update the Null values - So there are no null values instead there are blank values

#Update Status column - because some rows are Blank
SELECT country,status,year
FROM worldlifexpectancy
WHERE status='';

SELECT country,status,year
FROM worldlifexpectancy 
WHERE status<>''
;

SELECT DISTINCT country
FROM worldlifexpectancy 
WHERE status='Developed';

SELECT DISTINCT country
FROM worldlifexpectancy 
WHERE status='Developing';

#Update the blank values
UPDATE worldlifexpectancy w1
JOIN worldlifexpectancy w2
ON w1.country = w2.country
SET w1.status = 'Developing'
WHERE w1.status = '' AND w2.status<>'' AND w2.status= 'Developing';

UPDATE worldlifexpectancy w1
JOIN worldlifexpectancy w2
ON w1.country = w2.country
SET w1.status = 'Developed'
WHERE w1.status = '' AND w2.status<>'' AND w2.status= 'Developed';

#Check again and confirm
SELECT country,status,year
FROM worldlifexpectancy
WHERE status='';

#Update Lifeexpectancy column 
SELECT country,year
FROM worldlifexpectancy
WHERE lifeexpectancy='';

#There are only 2 conuntries where lifeexpectancy is blank we will fill those with the average of previous and next year
SELECT country,year,Lifeexpectancy
FROM worldlifexpectancy
WHERE country IN ('Afghanistan','Albania') ;

SELECT w1.country,w1.year,w1.Lifeexpectancy,w2.country,w2.year,w2.Lifeexpectancy,w3.country,w3.year,w3.Lifeexpectancy, 
ROUND((w2.Lifeexpectancy+w3.Lifeexpectancy)/2,1)
FROM worldlifexpectancy w1
JOIN worldlifexpectancy w2
	ON w1.country = w2.country
	AND w1.year = w2.year-1
JOIN worldlifexpectancy w3
	ON w1.country = w3.country
	AND w1.year = w3.year+1
WHERE w1.Lifeexpectancy=''
;

#Update the column
UPDATE worldlifexpectancy w1
JOIN worldlifexpectancy w2
	ON w1.country = w2.country
	AND w1.year = w2.year-1
JOIN worldlifexpectancy w3
	ON w1.country = w3.country
	AND w1.year = w3.year+1
SET w1.Lifeexpectancy=ROUND((w2.Lifeexpectancy+w3.Lifeexpectancy)/2,1)
WHERE w1.Lifeexpectancy='' ;

#Check again
SELECT country,year
FROM worldlifexpectancy
WHERE lifeexpectancy='';



# STEP 2 - EXPLORATORY DATA ANALYSIS

# Q1 -  How much life expectancy has changed for each country over the years and which countries experienced the largest shifts in life expectancy?

SELECT country,MAX(Lifeexpectancy),MIN(Lifeexpectancy), ROUND(MAX(Lifeexpectancy) - MIN(Lifeexpectancy),2) AS change_currently
FROM worldlifexpectancy
GROUP BY country
HAVING MAX(Lifeexpectancy)<>0 AND MIN(Lifeexpectancy)<>0 
ORDER BY change_currently DESC;

# Q2 - How the average life expectancy for the entire world (across all countries) has changed over the years.
SELECT year, ROUND(AVG(Lifeexpectancy),1) AS AVG_Lifeexpectancy
FROM worldlifexpectancy
GROUP BY year;

# Q3 - Which countries have higher or lower GDP and how their life expectancy compares, allowing for analysis of the correlation between wealth (GDP) and life expectancy.
SELECT AVG(GDP), MAX(GDP), MIN(GDP)
FROM worldlifexpectancy;

SELECT country, ROUND(AVG(GDP),2) AS GDP, ROUND(AVG(Lifeexpectancy),2) AS Lifeexpectancy
FROM worldlifexpectancy
WHERE GDP<>0 AND Lifeexpectancy<>0
GROUP BY country
ORDER BY GDP DESC;

#Q4 - Compare life expectancy between high-GDP and low-GDP countries, whether richer countries have longer life expectancies than poorer ones
SELECT 
	SUM(CASE WHEN GDP>6342 THEN 1 ELSE 0 END) AS High_GDP,
    ROUND(AVG(CASE WHEN GDP>6342 THEN Lifeexpectancy ELSE NULL END),2) AS High_GDP_Lifeexpectancy,
    SUM(CASE WHEN GDP<6342 THEN 1 ELSE 0 END) AS Low_GDP,
	ROUND(AVG(CASE WHEN GDP<6342 THEN Lifeexpectancy ELSE NULL END),2) AS Low_GDP_Lifeexpectancy
FROM worldlifexpectancy;  


#Q5 - What is the average life expectancy for developed and developing countries, and how many distinct countries fall into each group?
SELECT status, COUNT(DISTINCT country) AS countries,ROUND(AVG(Lifeexpectancy),2) as Lifeexpectancy
FROM worldlifexpectancy
GROUP BY status;


#Q6 - How cumulative adult mortality over the years impacts life expectancy in the respective country
SELECT country,year,Lifeexpectancy,AdultMortality, SUM(AdultMortality) OVER(PARTITION BY country ORDER BY year) AS Rolling_AdultMortality
FROM worldlifexpectancy
;


SELECT country, AVG(infantdeaths) as d, AVG(Lifeexpectancy) AS Average_Life_Expectancy
FROM worldlifexpectancy
GROUP BY country
ORDER By d DESC;















