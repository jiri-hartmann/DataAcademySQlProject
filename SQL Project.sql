-- Spojovací tabulka: t_jiri_hartmann_projekt_SQL_link
create or replace table t_jiri_hartmann_projekt_SQL_link (
    country_1 varchar(127) not null primary key,
    iso3 varchar(127),
    country_2 varchar(127),
    capital_city varchar(127),
    population integer
    )
as
(select distinct cov.country as "country_1", loo.iso3,
    case when cov.country = "Taiwan*" then "Taiwan"
         when cov.country = "Kosovo" then "Kosovo"
         else cou.country end as "country_2", 
    cou.capital_city, loo.population
from covid19_basic_differences as cov
left join 
    (select country, iso3, population from lookup_table where province is null) as loo
on cov.country = loo.country
left join
    (select country, capital_city, iso3 from countries) as cou
on loo.iso3 = cou.iso3
order by cov.country
);



-- Spojovací tabulka: t_jiri_hartmann_projekt_SQL_eco
create or replace table t_jiri_hartmann_projekt_SQL_eco (
    country varchar(127) not null primary key,
    gini float(5,2),
    GDP_mil integer,
    mortaliy_under5 float(5,2)
    )
as
(select lin.country_2 as "country", gin.gini, round(gdp.GDP/1000000) as "GDP_mil", mor.mortaliy_under5 from t_jiri_hartmann_projekt_SQL_link lin 
left join 
    (select country, first_value(gini) over (partition by country order by `year` ) as "gini" 
    from economies
    where gini is not NULL
    group by country ) as gin
on lin.country_2 = gin.country
left JOIN 
    (SELECT country, first_value(GDP) over (partition by country order by `year` ) as "GDP" 
    FROM economies
    where GDP is not NULL
    group by country ) as gdp
on lin.country_2 = gdp.country
left join 
    (SELECT country, first_value(mortaliy_under5) over (partition by country order by `year` ) as "mortaliy_under5",  `year` 
    FROM economies
    where mortaliy_under5 is not NULL
    group by country ) as mor
on lin.country_2 = mor.country
where lin.country_2 is not NULL 
order by lin.country_2
);



-- Náboženství: t_jiri_hartmann_projekt_SQL_religion
create or replace table t_jiri_hartmann_projekt_SQL_religion (
    country_1 varchar(127) not null primary key,
    buddhism float(5,2),
    christianity float(5,2),
    folk_religions float(5,2),
    hinduism float(5,2),
    islam float(5,2),
    judaism float(5,2),
    other_religions float(5,2),
    unaffiliated_religions float(5,2)
    ) 
as
(select lin.country_1, rel.buddhism, rel.christianity, rel.folk_religions,
       rel.hinduism, rel.islam, rel.judaism, rel.other_religions, rel.unaffiliated_religions
from
  (select country, 
    round(sum(if(religion = "Buddhism", population, Null))/sum(population)*100, 2) as "buddhism", 
    round(sum(if(religion = "Christianity", population, Null))/sum(population)*100, 2) as "christianity", 
    round(sum(if(religion = "Folk Religions", population, Null))/sum(population)*100, 2) as "folk_religions", 
    round(sum(if(religion = "Hinduism", population, Null))/sum(population)*100, 2) as "hinduism", 
    round(sum(if(religion = "Islam", population, Null))/sum(population)*100, 2) as "islam", 
    round(sum(if(religion = "Judaism", population, Null))/sum(population)*100, 2) as "judaism", 
    round(sum(if(religion = "Other Religions", population, Null))/sum(population)*100, 2) as "other_religions", 
    round(sum(if(religion = "Unaffiliated Religions", population, Null))/sum(population)*100, 2) as "unaffiliated_religions"
from religions where  `year` = 2020 and country in (select country_2 from t_jiri_hartmann_projekt_SQL_link)
group by country
) rel
left join t_jiri_hartmann_projekt_SQL_link as lin
on rel.country = lin.country_2 
order by lin.country_1 
);


-- Poèasí: t_jiri_hartmann_projekt_SQL_weather
create or replace table t_jiri_hartmann_projekt_SQL_weather (
    `date` date not null,
    country_1 varchar(127) not null,
    avg_daily_temp float(5,2),
    rainy_hours integer,
    max_gust integer,
    primary key (`date`, country_1)
    ) 
as
(select w.`date`, l.country_1 , w.avg_daily_temp, w.rainy_hours, w.max_gust from
    (select `date`, city, sum(if(`hour` in (6, 9, 12, 15), temp, Null)) / 4 as "avg_daily_temp", 
            sum(if(rain <> 0, 3, 0)) as "rainy_hours", max(gust) as "max_gust"
    from weather
    where "2020-01-21" < `date` -- 2020-01-22 is first day in incovid19_basic_differences table
    group by `date`, city ) as w
    left join t_jiri_hartmann_projekt_SQL_link as l 
    on w.city = l.capital_city
    where l.capital_city is not null
    order by w.`date`, l.country_1 
);  


-- Výsledná tabulka: t_jiri_hartmann_projekt_SQL_final
create or replace table t_jiri_hartmann_projekt_SQL_final (
    `date` date not null,
    country varchar(127) not null,
    confirmed integer,
    tests_performed integer,
    is_weekend integer,
    season integer,
    surface_area integer,
    median_age_2018 float(5,2),
    GDP_mil integer,
    gini float(5,2),
    mortaliy_under5 float(5,2),
    life_expectancy_difference_2015_1965 float(5,2),
    buddhism float(5,2),
    christianity float(5,2),
    folk_religions float(5,2),
    hinduism float(5,2),
    islam float(5,2),
    judaism float(5,2),
    other_religions float(5,2),
    unaffiliated_religions float(5,2),
    avg_daily_temp float(5,2),
    rainy_hours integer,
    max_gust integer,
    primary key (`date`, country)
    ) 
as
(select cov.`date`, cov.country, cov.confirmed, tes.tests_performed,
       case when WEEKDAY(cov.`date`) in (5,6) then 1 else 0 end as is_weekend, 
       case when month (cov.`date`) in (1,2,3) then 0 
            when month (cov.`date`) in (4,5,6) then 1
            when month (cov.`date`) in (7,8,9) then 2
            else 3 end as season,
    cou.surface_area, cou.median_age_2018,
    eco.GDP_mil, eco.gini, eco.mortaliy_under5,
    round(lif.life_expectancy_difference_2015_1965,2) as "life_expectancy_difference_2015_1965",
    rel.buddhism, rel.christianity, rel.folk_religions, rel.hinduism, rel.islam, rel.judaism, rel.other_religions, rel.unaffiliated_religions,
    wea.avg_daily_temp, wea.rainy_hours, wea.max_gust
from covid19_basic_differences as cov 
left join t_jiri_hartmann_projekt_SQL_link lin
on cov.country = lin.country_1 
left join 
    (select iso3, surface_area, median_age_2018 from countries) as cou
on lin.iso3 = cou.iso3
left join
    (select country, GDP_mil, gini, mortaliy_under5 from t_jiri_hartmann_projekt_SQL_eco ) as eco
on lin.country_2 = eco.country
left join
    (select le2015.iso3, le2015.life_expectancy-le1965.life_expectancy as "life_expectancy_difference_2015_1965" from 
    (select iso3, life_expectancy from life_expectancy where `year` = 2015) as le2015
    left join
    (select iso3, life_expectancy from life_expectancy where `year` = 1965) as le1965
    on le2015.iso3 = le1965.iso3) as lif
on lin.iso3 = lif.iso3
left join t_jiri_hartmann_projekt_SQL_religion rel
on cov.country = rel.country_1 
left join t_jiri_hartmann_projekt_SQL_weather wea
on cov.`date` = wea.`date` and cov.country = wea.country_1 
left join
    (select `date`, ISO, tests_performed from covid19_tests group by `date`, ISO) as tes
on lin.iso3 = tes.ISO and cov.`date` = tes.`date`
)
; 

