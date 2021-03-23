CREATE TABLE t_anna_riedlova_projekt_SQL_final
AS 

WITH t1 AS
#density, median, mortality, gini --> all in 2019 (there is not much data for 2020 in economies table and because most of our analysis 
#is driven by date related to COVID which is 2020-2021 we need to have as freshest option as possible
#of course if the client would prefer to have freshest data but in limited range, it is easily convertible
(SELECT
	c.country,
	c.capital_city ,
	c.population, 
	c.population_density,
	c.median_age_2018 ,
	ROUND((e.GDP/c.population),2) as GDP_head,
	e.year ,
	e.gini,
	e.mortaliy_under5
FROM economies as e 

CROSS JOIN countries as c
	on c.country=e.country 
WHERE 1=1
AND e.year="2019"
),
	t2 AS
#covid table - we have to driving keys - date and country and both are in economies table
#I also included confirmed/recovered and deaths ´cos that is object of analysis in the first place
#I also considered to aff info on tests but that is not consistent (different countries tested with different frequency --> limited value added)
(SELECT 	
	country,
	date,
	confirmed,
	recovered,
	deaths
FROM 
	covid19_basic cb 
),
	t3 AS
#binary for workday(0)/weekdend(1) and sign 0-3 for season (0-winter,1-spring,2-summer,3-autumn)
(SELECT 
	date,
	CASE 
		WHEN
			DAYOFWEEK(DATE) in (1,7)
			THEN 1
		ELSE
			0
	END AS binary_day,
	CASE 
		WHEN
			MONTH(DATE) in (12,1,2)
			THEN 0
		WHEN
			MONTH(DATE) In (2,3,4)
			THEN 1
		WHEN
			MONTH(DATE) In (5,6,7)
			THEN 2
		ELSE
			3
	END AS seasons_month
FROM covid19_basic_differences cbd 
group by date
),
	t4 AS
#life expectancy diff between years 1965 and 2015.
(SELECT a.country, a.life_exp_1965 , b.life_exp_2015,
   	b.life_exp_2015 - a.life_exp_1965 as life_exp_diff
FROM (
    SELECT le.country , le.life_expectancy as life_exp_1965
    FROM life_expectancy le 
    WHERE year = 1965
    ) a JOIN (
    SELECT le.country , le.life_expectancy as life_exp_2015
    FROM life_expectancy le 
    WHERE year = 2015
    ) b
    ON a.country = b.country),
    
	 t6 AS
#average temperature during day (not in night)
#only hours from 6-18 taken into consideration)
(SELECT 
	city,
	date,
	sum(temp)/4 as average_temp
from weather w 
WHERE 1=1
AND hour BETWEEN 6 and 15
GROUP by date,city
),
	t5 as 
#number of hours per day when there was no rain as rainless_hours
(SELECT city , date,count(hour)*3 AS rainless_hours
        FROM weather w
        WHERE rain=0
        GROUP BY date,city),
        
	t7 as 
#information on maximal winf per day as max_wind
(SELECT city , date , max(wind) as max_wind
        FROM weather w 
        GROUP BY date, city),
    t10 AS
 #for better mistakes follow-up all weather realated joined together here:
 #we could also create separate table from these 
 #weather table contains only european countries, for remaining countries no information accesible
(SELECT t6.city,t6.date,t6.average_temp,
t5.rainless_hours,t7.max_wind
FROM t6 
JOIN t5 ON t6.city=t5.city
	AND t6.date=t5.date
JOIN t7 ON t6.city=t7.city
	AND t6.date=t7.date),

	t8 as
#religion ratios - from separate table 
#reason for separate table is due to moving information from raws to collumns
#reason for this is eliminated doubleing the same raw only for purpose of assigning particular religion ratio to it
(SELECT 
country, 
sum(Islam) as Islam,
sum(Christianity) as Christianity,
sum(Unaffiliated_Religions) as Unaffiliated_Religions,
sum(Hinduism) as Hinduism, 
sum(Buddhism) as Buddhism, 
sum(Folk_Religions) as Folk_Religions, 
sum(Other_Religions) as Other_Religions,
sum(Judaism) AS Judaism
FROM t_anna_riedlova_sqlproject_religions
Group by country),

	t9 as
#all table joined together for permanent table creation
(Select t2.date, t2.country,
t1.capital_city,t1.population,
t2.confirmed,t2.recovered,t2.deaths,
t1.population_density,
t1.median_age_2018,t1.GDP_head,t1.gini,t1.mortaliy_under5,
t4.life_exp_diff,
t8.Islam,t8.Christianity,t8.Unaffiliated_Religions,
t8.Hinduism,t8.Buddhism,t8.Folk_Religions,t8.Other_Religions,t8.Judaism,
t3.seasons_month,t3.binary_day,
t10.average_temp,
t10.max_wind,
t10.rainless_hours
FROM t1 
JOIN t2 ON t2.country=t1.country
JOIN t3 ON t2.date=t3.date
JOIN t4 ON t2.country=t4.country
LEFT JOIN t10 ON t2.date=t10.date
AND t10.city=t1.capital_city
LEFT JOIN t8 ON t2.country=t8.country

)


SELECT * 
FROM t9

#table is ordered by country, so by scrolling you can see situation in the same state on the timeline, another option is to order it by date
#meaning that you will have the same date in first collumn but different contries in second --> with this view you can better compare --> it is up to needed view


