select * from athletes
select * from athlete_events

select distinct sport from athlete_events
select distinct games from athlete_events

/* SKILLS USED
1.Sub-Queries
2.Join
3.Windows functions
4.CTEs */

-- --1 which team has won the maximum gold medals over the years.

-- Method 1 

select top 1 team,count(medal) as cnt from athlete_events ae
inner join athletes a on ae.athlete_id=a.id
where medal='Gold'
group by team
order by cnt desc;


-- Method 2
with CTE1 as (select distinct event, team, COUNT (medal) as med_cnt from(
select * from athlete_events ae inner join athletes a on ae.athlete_id = a.id) as An

where medal = 'Gold'
group by event, team)
select top 1 team, sum(med_cnt) as tot from CTE1
group by team
order by tot desc;

-- Method 3

with CTE1 as (select A.*, B.team from (select athlete_id, COUNT(medal) as medal_count from athlete_events 
where medal = 'Gold'
group by athlete_id) A inner join athletes B on A.athlete_id = B.id )

select top 1 team, sum(medal_count) as t_medal from CTE1
group by  team
order by t_medal desc

--2 for each team print total silver medals and year in which they won maximum silver medal..output 3 columns
-- team,total_silver_medals, year_of_max_silver

-- Method 1

with CTE as (select a.team ,ae.year, ae.medal, COUNT(ae.medal) as cnt, RANK()over (partition by team order by  COUNT(ae.medal) desc) as rnnk   
from athlete_events ae inner join athletes a
on ae.athlete_id = a.id 
where medal = 'silver'
group by  a.team ,ae.year, ae.medal)
select team, SUM(cnt) as T_M_C, MIN(case when rnnk = 1 then year end) as year_max_medal from CTE 
group by team
order by T_M_C desc

-- Method 2

with CTE1 as (select ae.year, a.team,ae.medal, COUNT(ae.medal) as med_cnt from athlete_events ae inner join athletes a
on ae.athlete_id = a.id 
where medal = 'silver'
group by ae.year, a.team,ae.medal),
CTE2 as (select *, RANK() over (partition by team order by med_cnt desc) as rnk from CTE1)
select team, sum(med_cnt) as ts, min(case when rnk = 1 then year end) as tt from CTE2 
group by team
order by ts desc;

-- Method 3


with CTE1 as (select * from athlete_events ae inner join athletes a
on ae.athlete_id = a.id 
where medal = 'silver'),

CTE2 as (select team, YEAR, COUNT(1) as cnt from CTE1
group by team, year) ,

CTE3 as (select team,year, SUM(cnt) as tot_med from CTE2
group by team,year ),

CTE4 as (select *, RANK() over (partition by team order by tot_med desc) as rn  from CTE3 )

select team, SUM(tot_med) as total_silver_medals, MIN(case when rn=1 then YEAR end) as year_of_max_silver from CTE4
group by team
order by total_silver_medals desc;

--3 which player has won maximum gold medals  amongst the players 
--which have won only gold medal (never won silver or bronze) over the years

with CTE as (select name, medal from athlete_events ae inner join athletes a
on ae.athlete_id = a.id)
select top 1 name, COUNT(medal) as cnt_gold from CTE
where name not in (select name from CTE where medal in ('silver','bronze'))
and medal = 'gold'
group by name
order by cnt_gold desc

--Misc: which player has won maximum silver medals  amongst the players 
--which have won only silver medal (never won gold or bronze) over the years

with CTE as (select name, medal from athlete_events ae inner join athletes a
on ae.athlete_id = a.id)
select top 1 name, COUNT(medal) as cnt_silver from CTE
where name not in (select name from CTE where medal in ('gold','bronze'))
and medal = 'silver'
group by name
order by cnt_silver desc

--4 in each year which player has won maximum gold medal . Write a query to print year,player name 
--and no of golds won in that year . In case of a tie print comma separated player names.

-- METHOD 1

with CTE as (select YEAR, name, count(medal) as gld_cnt from athlete_events ae inner join athletes a
on ae.athlete_id=a.id 
where medal = 'gold'
group by YEAR, name),
CTE1 as (select *, RANK() over (partition by year order by gld_cnt desc) as rnk from CTE)
select YEAR, gld_cnt, STRING_AGG(name,',') as players from CTE1 
where rnk = 1
group by YEAR, gld_cnt;

-- METHOD 2

with cte as (
select ae.year,a.name,count(1) as no_of_gold
from athlete_events ae
inner join athletes a on ae.athlete_id=a.id
where medal='Gold'
group by ae.year,a.name)
select year,no_of_gold,STRING_AGG(name,',') as players from (
select *,
rank() over(partition by year order by no_of_gold desc) as rn
from cte) a where rn=1
group by year,no_of_gold


--5 in which event and year India has won its first gold medal,first silver medal and first bronze medal
--print 3 columns medal,year,sport

-- METHOD 1

with CTE as (select medal,sport, year, event,team  from athlete_events ae inner join athletes a
on ae.athlete_id=a.id
where team = 'india' and medal in ('gold','silver','bronze')
),
CTE1 as (select *, RANK()over (partition by medal order by year) as rnk from CTE)
select medal,YEAR,event from CTE1
where rnk =1
group by medal,YEAR,event;

-- METHOD 2

select distinct * from (
select medal,year,event,rank() over(partition by medal order by year) rn
from athlete_events ae
inner join athletes a on ae.athlete_id=a.id
where team='India' and medal != 'NA'
) A
where rn=1

-- --6 find players who won gold medal in summer and winter olympics both.

select name from athlete_events ae inner join athletes a
on ae.athlete_id =a.id
where medal = 'gold'
group by name
having count (distinct season) = 2

--7 find players who won gold, silver and bronze medal in a single olympics. print player name along with year.

select year,name from athlete_events ae inner join athletes a
on ae.athlete_id = a.id
where medal != 'NA'
group by year,name
having COUNT(distinct medal) = 3 ;

--8 find players who have won gold medals in consecutive 3 summer olympics in the same event . Consider only olympics 2000 onwards. 
--Assume summer olympics happens every 4 year starting 2000. print player name and event name.

-- METHOD 1

with CTE as (select name,year,event from athlete_events ae inner join athletes a
on ae.athlete_id=a.id
where year >= 2000 and medal = 'gold' and season = 'summer'
group by  name,year,event),

CTE1 as (select *, LEAD(year,1) over (partition by name,event order by year ) as next_year,
Lag(year,1) over (partition by name,event order by year ) as prev_year from CTE)
select * from CTE1
where  year=prev_year+4 and year=next_year-4

-- METHOD 2

with CTE as (select name,year,event from athlete_events ae inner join athletes a
on ae.athlete_id=a.id
where year >= 2000 and medal = 'gold' and season = 'summer'
group by  name,year,event)

select * from (select *, LEAD(year,1) over (partition by name,event order by year ) as next_year,
Lag(year,1) over (partition by name,event order by year ) as prev_year from CTE)
 A
where  year=prev_year+4 and year=next_year-4







 










