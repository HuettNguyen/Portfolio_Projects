/*
Covid 19 Vaccination Data Exploration

Skills used: Converting Data Types, Aggregate Functions, CTEs, Nested Subqueries, Joins, Windows Functions, Temp Tables
*/


-- percentage of population receiving at least one dose of the COVID-19 vaccine by country
-- & percentage of population fully vaccinated by country
-- countries ranked by percentage of population receiving at least one dose

with vac_country as
(
select 
location as country, 
max(convert(date, getdate(), 23)) as date, 
max(cast(people_vaccinated_per_hundred as numeric)) as people_vaccinated_per_hundred, 
max(cast(people_fully_vaccinated_per_hundred as numeric)) as people_fully_vaccinated_per_hundred
from portfolio_project..covid_vaccination
where location not like '%income%' -- exclude income groups from 'location'
group by location
)
select *,
rank() over(order by people_vaccinated_per_hundred desc) as country_rank
from vac_country
order by country_rank;


-- vaccination rank of a country (eg. Vietnam), using multiple CTEs

with vac_country as
(
select 
location as country, 
max(convert(date, getdate(), 23)) as date, 
max(cast(people_vaccinated_per_hundred as numeric)) as people_vaccinated_per_hundred, 
max(cast(people_fully_vaccinated_per_hundred as numeric)) as people_fully_vaccinated_per_hundred
from portfolio_project..covid_vaccination
where location not like '%income%' -- exclude income groups from 'location'
group by location
),
vac_country_rank as
(
select *,
rank() over(order by people_vaccinated_per_hundred desc) as country_rank
from vac_country
)
select *
from vac_country_rank
where country = 'Vietnam';


-- vaccination rank of a country (eg. Vietnam), using nested subqueries

select *
from 
(
select *,
rank() over(order by people_vaccinated_per_hundred desc) as country_rank
from 
(
select 
location as country, 
max(convert(date, getdate(), 23)) as date, 
max(cast(people_vaccinated_per_hundred as numeric)) as people_vaccinated_per_hundred, 
max(cast(people_fully_vaccinated_per_hundred as numeric)) as people_fully_vaccinated_per_hundred
from portfolio_project..covid_vaccination
where location not like '%income%' -- exclude income groups from 'location'
group by location
) as vac_country
) as vac_country_rank
where country = 'Vietnam';


-- percentage of population partially vaccinated

drop table if exists people_vaccinated;
with vac1 as
(
select 
cas.continent,
vac.location, 
max(convert(date, getdate(), 23)) as date, 
max(cast(vac.people_vaccinated_per_hundred as numeric)) as people_vaccinated_per_hundred, 
max(cast(vac.people_fully_vaccinated_per_hundred as numeric)) as people_fully_vaccinated_per_hundred
from
portfolio_project..covid_case_death as cas
join
portfolio_project..covid_vaccination as vac
on
cas.location = vac.location
and cas.date = vac.date
group by cas.continent, vac.location
)
select *,
(people_vaccinated_per_hundred - people_fully_vaccinated_per_hundred) as people_partially_vaccinated_per_hundred
into people_vaccinated
from vac1;


-- content of the table created in previous query

select *
from people_vaccinated
order by people_vaccinated_per_hundred desc;


-- vaccination progress vs income groups

select
location, date, people_vaccinated_per_hundred, people_fully_vaccinated_per_hundred, people_partially_vaccinated_per_hundred
from people_vaccinated
where location like '%income%'
order by people_vaccinated_per_hundred desc;


-- vaccination progress vs continents
select
continent, 
ceiling(avg(people_vaccinated_per_hundred)) as avg_people_vaccinated_per_hundred, 
ceiling(avg(people_fully_vaccinated_per_hundred)) as avg_people_fully_vaccinated_per_hundred,
ceiling(avg(cast(people_partially_vaccinated_per_hundred as numeric))) as avg_people_partially_vaccinated_per_hundred
from people_vaccinated
where continent is not null
group by continent
order by avg_people_vaccinated_per_hundred desc;


-- full vaccination rate
select 
	continent, location, 
	ceiling(people_vaccinated_per_hundred) as people_vaccinated_per_hundred, 
	ceiling(people_fully_vaccinated_per_hundred) as people_fully_vaccinated_per_hundred, 
	ceiling(((cast(people_fully_vaccinated_per_hundred as numeric))/nullif(cast(people_vaccinated_per_hundred as numeric), 0))*100) as percent_full_vaccinated_vs_vaccinated
from people_vaccinated;