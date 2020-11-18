-- pomocné selekty
select distinct country from covid19_basic_differences ; -- where country = "czechia";
select * from countries; -- where country = "czech republic";
select * from covid19_tests; where iso = "CZE";
select * from lookup_table where province is null; -- lt where country = "czechia";
select * from economies where  `year` = 2019; -- e2 where country = "czech republic";
select * from life_expectancy; -- le where country = "czech republic";
select * from religions where country = "czech republic" and `year` = 2020;
select * from religions;
select * from weather;
select DISTINCT `date` from weather w ;
describe covid19_tests ;


-- zaèátek projektu
select cov.`date`, case when WEEKDAY(cov.`date`) in (5,6) then 1 else 0 end as is_weekend, 
    case when month (cov.`date`) in (1,2,3) then 0 
         when month (cov.`date`) in (4,5,6) then 1
         when month (cov.`date`) in (7,8,9) then 2
         else 3 end as season,
    cov.country, cov.confirmed , tes.tests_performed, tes.population,
    cou.surface_area, cou.median_age_2018,  
    round(eco.GDP/1000000) as GDP_mil, eco.gini, eco.mortaliy_under5,
    round(lif.life_expectancy_difference_2015_1965,2) as "life_expectancy_difference_2015_1965",
    rel.buddhism, rel.christianity, rel.folk_religions, rel.hinduism, rel.islam, rel.judaism, rel.other_religions, rel.unaffiliated_religions,
    wea.avg_daily_temp, wea.rainy_hours, wea.max_gust
from covid19_basic_differences as cov 
left join 
    (select l.country, c.`date`, c.tests_performed, l.population from covid19_tests as c
    left join
        (select country, iso3, population from lookup_table where province is null) as l
    on c.ISO =l.iso3 ) as tes
on cov.country = tes.country and cov.`date` = tes.`date` 
left join 
    (select l.country as "country_cov", c.country as "country_cou", c.surface_area, c.median_age_2018 from countries as c
    left join 
    (select country, iso3 from lookup_table where province is null) as l
    on c.iso3 = l.iso3 ) as cou
on  cov.country = cou.country_cov  
left join
    (select country, GDP, gini, mortaliy_under5 from economies where  `year` = 2019) as eco
    on cou.country_cou = eco.country
left join
    (select le2015.country, le2015.life_expectancy-le1965.life_expectancy as "life_expectancy_difference_2015_1965" from 
    (select country, life_expectancy from life_expectancy where `year` = 2015) as le2015
    left join
    (select country, life_expectancy from life_expectancy where `year` = 1965) as le1965
    on le2015.country = le1965.country) as lif
on cou.country_cou = lif.country
left join
    (select country, 
        round(sum(if ( religion = "Buddhism", population, Null))/sum(population)*100, 2) as "buddhism", 
        round(sum(if ( religion = "Christianity", population, Null))/sum(population)*100, 2) as "christianity", 
        round(sum(if ( religion = "Folk Religions", population, Null))/sum(population)*100, 2) as "folk_religions", 
        round(sum(if ( religion = "Hinduism", population, Null))/sum(population)*100, 2) as "hinduism", 
        round(sum(if ( religion = "Islam", population, Null))/sum(population)*100, 2) as "islam", 
        round(sum(if ( religion = "Judaism", population, Null))/sum(population)*100, 2) as "judaism", 
        round(sum(if ( religion = "Other Religions", population, Null))/sum(population)*100, 2) as "other_religions", 
        round(sum(if ( religion = "Unaffiliated Religions", population, Null))/sum(population)*100, 2) as "unaffiliated_religions"
    from religions where country <> "All Countries" and `year` = 2020 
    group by country) as rel
on cou.country_cou = rel.country
left join
    (select w.`date`, l.country, w.avg_daily_temp, w.rainy_hours, w.max_gust from
    (select `date`, city, sum(if(hour in (6, 9, 12, 15), temp, Null)) / 4 as "avg_daily_temp" , sum(if(rain <> 0, 3, 0)) as "rainy_hours", max(gust) as "max_gust"
    from weather as w
    where "2020-01-21" < `date` -- 2020-01-22 is first day in incovid19_basic_differences table
    group by `date`, city ) as w
   left join 
    (select capital_city, iso3 from countries) c 
    on w.city = c.capital_city
   left join 
    (select iso3, country from lookup_table lt where province is null) l
    on c.iso3 = l.iso3 ) as wea
on cov.`date` = wea.`date` and cov.country = wea.country 
--  where cov.country = "czechia"            -- "czechia" "United kingdom"
;order by cov.`date`


