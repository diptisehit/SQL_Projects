# Project3 - Sports Analytics */

/* Creating database and physical data model for sports analytics*/
create database project1;
use project1;

select * from country limit 5;
select * from country;
select count(*) from country;

select * from league limit 5;
select * from league;
select count(*) from league;
select * from matches limit 5;
select * from team limit 5;
select count(*) from team;

--    Creating primary key for all tables 
alter table country add primary key (id);
alter table league add primary key (id);
alter table matches add primary key (match_api_id);
alter table team add primary key (team_api_id);

--    Creating foreign key column
alter table league add foreign key(country_id) references country(id);
alter table matches add foreign key(home_team_api_id) references team(team_api_id);
alter table matches add foreign key(away_team_api_id) references team(team_api_id);
alter table matches add foreign key(league_id) references league(id);

# Identifying duplicate rows in TEAM table : 
-- 1st Method : group by the columns (except PK) and find count >1
select id,team_fifa_api_id,team_long_name,team_short_name
from team
group by id,team_fifa_api_id,team_long_name,team_short_name
having count(*)>1;
-- 2nd Method: partition by the columns(except PK) and give row number in each partition
select team_api_id,row_number() 
over (partition by id,team_fifa_api_id,team_long_name,team_short_name) as row_no 
from team; 

# Deleting duplicate rows in team table : 
-- 1st Method : partitioning the table by columns (except PK) and row numbering to find >1
delete from team where team_api_id in
( select team_api_id from	
    (	select team_api_id,row_number() 
		over (partition by id,team_fifa_api_id,team_long_name,team_short_name) as row_no 
		from team 
	) A
  where row_no>1
);
-- 2nd Method :
select name,count(*) namecount from country group by name having namecount>1;
delete from country where id in
(select id from 
	( select max(id) as id  from country 
	  group by name having count(*)>1
	)A
); 

# Identifying duplicates for country table :
select name from country
group by name
having count(*)>1;

# Identifying duplicates for league table :
select country_id,name from league
group by country_id,name
having count(*)>1;



# DATA TYPE MISMATCH AND TYPECASTING -
-- TO PERFORM DATE OPERATION WE NEED TO CONVERT DATE FROM TEXT TO DATETIME DATA TYPE
select * from matches limit 5;
-- str_to_date(column,"format") : convert the text format to date format
-- since date column is already in same format both the column will look same
select str_to_date(date,'%Y-%m-%d %H:%i:%s'),date from matches limit 5;
-- we need to first upadte the format of column and then alter the datatype of column
# STEP 1 : UPDATING THE DATE FORMAT
update matches set date=str_to_date(date,'%Y-%m-%D %H:%i:%s');
# STEP 2 : ALTERING THE DATATYPE OF DATE COLUMN
alter table matches modify column date timestamp;

# BUILD A VIEW
-- TO GET AGGREGATED TABLE ON CERTAIN COLUMNS
-- EVERYTIME WHEN WE CREATE THE TABLE USING SELECT COMMAND, CERTAIN MEMORY IS USED
-- VIEWS HELP TO HOLD AGGREGATE INFORMATION WITH HELP OF VIRTUAL MEMORY - IT WILL NOT OCCUPY ANY PHYSICAL MEMORY ON DISK
-- ANY CHANGES HAPPENING ON TABLE WILL BE QUICKLY REFRESHED AND REVIEWED ON VIEWS
-- VIEWS ARE ONLY MIRROR INFORMATION FROM THE ORIGINAL TABLE

# Here in matches table we have two teams - home team and away team
-- Home team is team which belongs to same country where match is happening (playing in home country)
-- Away team is a foregin team (not playing in home country) 
-- In a stadium, if home team is playing, we want to know the sum of goal of all the matches played by that home team
-- Create a view to have the count of goals made by home team and away team
-- Benefit : Predict whether Playing as home team is really benefical or not (let minimum count of goal be 2)
-- using join to know the long name of the home team api id from team table
create view home_team_goal_count as
select matches.home_team_api_id,team.team_long_name,sum(matches.home_team_goal) as goal_count
from matches 
join team
on matches.home_team_api_id=team.team_api_id
group by matches.home_team_api_id
having sum(matches.home_team_goal)>2; 
-- NOW QUERING THE VIEW 
select * from home_team_goal_count
order by goal_count desc;

# Away team goal count view
create view away_team_goal_count as
select matches.away_team_api_id,team.team_long_name,sum(matches.away_team_goal) as goal_count
from matches 
join team
on matches.away_team_api_id=team.team_api_id
group by matches.away_team_api_id
having sum(matches.away_team_goal)>2; 
-- NOW QUERING THE VIEW 
select * from away_team_goal_count
order by goal_count desc;


/* USE-CASE-1 : FIND THE TEAM WON BASED ON THE NUMBER OF GOALS THEY HAVE MADE ON THE DAY OF THE MATCH */
-- IN EACH MATCH ID WE HAVE HOME TEAM AND AWAY TEAM AND THEIR GOALS BUT WE DONT HAVE WINNING TEAM COLUMN
-- SO WE WILL ANALYSE THE HOME_TEAM_GOAL AND AWAY_TEAM_GOAL COLUMNS AND IDENTIFY WHICH IS THE WINNING TEAM
-- USAGE OF BACKQUOTES IN DATE COLUMN : mysql compiler will not treat date as keyword (date is keyword)
-- USAGE OF SUBQUERY FILTERS THE MATCH ID WITH TIE. ONLY MATCH WINNING TEAMS ID ARE REFLECTED
select match_api_id,match_date,winning_team_api_id,team_long_name,team_short_name 
from
(select match_api_id,`date` as match_date,
case when home_team_goal>away_team_goal then home_team_api_id
	 when away_team_goal>home_team_goal then away_team_api_id
     when home_team_goal=away_team_goal then "Tie"
end as winning_team_api_id
from matches
)A
join team
on A.winning_team_api_id=team.team_api_id;
-- WE CAN GET SAME DATE FOR MANY MATCHES BECAUSE IN EACH LEAGUE MATCHES ARE PLAYED AT DIFFERENT STAGE/STADIUM ON SAME DATE
# MODIFY THE QUERY TO GET THE TIE INFORMATION
select match_api_id,`date` as match_date,
case when home_team_goal=away_team_goal then "Tie"
end as match_result,
home_team.team_long_name as home_team_name, away_team.team_long_name as away_team_name
from matches
join team as home_team
on matches.home_team_api_id=home_team.team_api_id
join team as away_team
on matches.away_team_api_id=away_team.team_api_id
having match_result is not null;


/* USE-CASE-2 : LISTDOWN THE COUNTRY NAMES AND THE LEAGUES HAPPENED ON THOSE COUNTRIES */
select country.name as country_name,league.name as league_name
from league
join country
on country.id=league.country_id;

/* USE-CASE-3 : JOIN ALL TABLES TO GET COMPLETE DETAILS OF MATCHES WITH COUNTRY NAME, LEAGUE NAME AND TEAM NAMES */
-- AFTER INSPECTING SCHEME :
-- country and league can be joined with id and country_id
-- country,league and match can be combined through cntry_id,league_id from matches table
-- match and team tables can be joined through team_api_id and home_team/away_team
select country.name,league.name,
matches.season as season,matches.stage as stadium,matches.date,matches.match_api_id,
home_team.team_long_name as home_team_name, away_team.team_long_name as away_team_name, matches.home_team_goal,matches.away_team_goal
from country
join league
on country.id=league.country_id
join matches
on country.id=matches.country_id
and league.id=matches.league_id
join team as home_team
on matches.home_team_api_id=home_team.team_api_id
join team as away_team
on matches.away_team_api_id=away_team.team_api_id;


/* USE-CASE-4 : CALCULATE THE METRICS : 1. AVERAGE HOME TEAM GOALS  2. AVERAGE AWAY TEAM GOALS  3. AVERAGE GOAL DIFFERENCE
										4. AVERAGE SUM OF GOALS: SUM(HOME+AWAY)/NO. OF MATCHES  5. SUM OF GOALS: SUM(HOME+AWAY) */
select country.name as country_name,league.name as league_name,
matches.season,matches.stage,
avg(home_team_goal) as avg_home_team_goals,
avg(away_team_goal) as avg_away_team_goals,
avg(home_team_goal-away_team_goal) as avg_goal_diff,
avg(home_team_goal+away_team_goal) as avg_goal_sum,
sum(home_team_goal+away_team_goal) as total_goals
from country
join league
on country.id=league.country_id
join matches 
on country.id=matches.country_id
and league.id=matches.league_id
group by country.name,league.name,matches.season,matches.stage
order by total_goals desc;


/* DIFFERENCE BETWEEN FUNTIONS AND STORED PROCEDURE :
	1. FUNTIONS CAN RETURN ONLY 1 VALUE : MULTIPLE INPUTS BUT ONLY ONE OUTPUT FOR ONE RETURN VALUE
    2. STORED PROCEDURE CAN RETURN 2 OR MORE VALUES : MULTIPLE INPUTS AND MULTIPLE OUTPUTS TO RETURN MULTIPLE VALUES
    3. RUNTIME EXECUTION BECOMES SIMPLE USING STORED PROCEDURE */

/* USE-CASE-5 : SUPPLY A TEAM_API_ID TO A STORED PROCEDURE TO GET THE TOTAL GOALS TAKEN BY THAT TEAM AS A HOME TEAM AND AS AWAY TEAM */
delimiter |
create procedure team_goal_count(in team_api_id int, out home_team_goal_sum int, away_team_goal_sum int)
begin
	select
		sum(case when home_team_api_id=team_api_id then home_team_goal end) as home_team_goal_sum,
        sum(case when away_team_api_id=team_api_id then away_team_goal end) as away_team_goal_sum
	from matches;
end | 

-- RUNTIME ARGUMENT
set @team_api_id=10000;
call team_goal_count(@team_api_id,@home_team_goal_sum,@away_team_goal_sum);


/* USE-CASE-6 : FIND THE HIGHEST GOAL SCORE BY TEAM BY USING CTE.*/
-- CTE(COMMON TABLE EXPRESSIONS) ARE USED TO CREATE VIRTUAL TABLE LIKE VIEWS.
-- BUT THEY WILL NOT REFRESH IF ORIGINAL TABLE IS UPDATED BECAUSE THERESULTS OF QUERY ARE STORED IN TEPORARY TABLE
-- BENEFITS OF CTE : RIGHT AFTER CTE WE CAN QUERY THE TEMPORARY TABLE.
with highest_score as (
select league_id,match_api_id,home_team_api_id,away_team_api_id, home_team_goal+away_team_goal as total_goals
from matches )
select league.name as league_name, 
count(highest_score.match_api_id) as high_score_matches_count,sum(highest_score.total_goals) as totalscore,
avg(highest_score.total_goals) as average_high_score
from highest_score
join league
on highest_score.league_id=league.id
group by league_id
order by totalscore desc;


/* USE-CASE-7 : Rank the leagues based on the average total number of goals achieved in every league. */
select league.name as league_name, avg(home_team_goal+away_team_goal) as avg_goal,
rank() over(order by avg(home_team_goal+away_team_goal) desc) as league_rank
from matches
join league
on matches.league_id=league.id
group by league_name;


/* USE-CASE-8 : RUNNING TOTAL OF SCORE TEAM  (USING DATE COLUMN IN UNBOUNDED PRECEDING AND CURRENT ROW */
select matches.date, team.team_long_name as home_team_name, home_team_goal,
sum(home_team_goal) over (order by matches.date rows between unbounded preceding and current row) as running_total
from matches
join team
on team.team_api_id=matches.home_team_api_id
group by matches.home_team_api_id
order by matches.home_team_api_id,matches.date;

select matches.date, team.team_long_name as home_team_name, home_team_goal,
sum(home_team_goal) over (order by matches.date rows between unbounded preceding and current row) as running_total
from matches
join team
on team.team_api_id=matches.home_team_api_id
where matches.home_team_api_id=9987;



-- *****************END OF ANALYSIS***************************



select * from matches limit 5;
SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));










