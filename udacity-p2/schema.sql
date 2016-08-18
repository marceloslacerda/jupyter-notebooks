create table if not exists salaries (
  yearID int, -- Year
  teamID text, -- Team
  lgID text, --League
  playerID text, --Player ID code
  salary int --Salary
);

create table if not exists awardsplayers (
  playerID text, --       Player ID code
  awardID text, --        Name of award won
  yearID int, --         Year
  lgID text, --           League
  tie text, --            Award was a tie (Y or N)
  notes text --          Notes about the award
);

\copy salaries from '/home/msl09/documents/jupyter-notebooks/udacity-p2/baseballdatabank-master/core/Salaries.csv' with csv header ;
\copy awardsplayers from '/home/msl09/documents/jupyter-notebooks/udacity-p2/baseballdatabank-master/core/AwardsPlayers.csv' with csv header ;

create temp table awardwinningplayers_salary as (
select *
from salaries
where playerid in (select distinct playerid from awardsplayers));

--first year that each player received an award
select playerid, min(yearid) as yearid
from awardwinningplayers_salary
where awardid is not null
group by playerid;

--the salaries of each player on that year

select playerid, yearid, salary
from awardwinningplayers_salary
natural join (
     select playerid, min(yearid) as yearid
     from awardwinningplayers_salary
     where awardid is not null
     group by playerid
) as tmp
group by playerid, yearid, salary;

--Let's make sure that each row has only one playerid
select playerid, count
from (
  select playerid, count(*)
  from (
    select playerid, yearid, salary
    from awardwinningplayers_salary
    natural join (
      select playerid, min(yearid) as yearid
      from awardwinningplayers_salary
      where awardid is not null
      group by playerid
    ) as tmp
    group by playerid, yearid, salary
  ) as tmp2
  group by playerid
) as tmp3
where count > 1;

--Create table for first award that each player received
create temp table firstaward as (select playerid, yearid, salary
from awardwinningplayers_salary
natural join (
     select playerid, min(yearid) as yearid
     from awardwinningplayers_salary
     where awardid is not null
     group by playerid
) as tmp
group by playerid, yearid, salary);


--get average salaries before the award
select playerid, avg(p1.salary)
from awardwinningplayers_salary as p1 join fistaward as fa
on p1.playerid = fa.playerid
where p1.yearid < fa.yearid
group by playerid;


--We can see here that the number of unique pairs of years and playerids don't appear in both tables.
select count(*) as pairs from (
  (select playerid, yearid from salaries group by playerid, yearid)
  except
  (select playerid, yearid from awardsplayers group by playerid, yearid)
) as tmp;
-- pairs
-- -----
-- 24097
/*That not all records from salaries appear in awardsplayers is expected,
because not all players are expected to win awards and players aren't expected to win awards on every year they receive a salary.*/

select count(*) as pairs from (
  (select playerid, yearid from awardsplayers group by playerid, yearid)
  except
  (select playerid, yearid from salaries group by playerid, yearid)
) as tmp;
-- pairs
-- -----
-- 2242
/*However, there are also some years that a player received an award but didn't appear in the awards table.*/

select playerid,
  (select t2.playerid, avg(salary)
  from salaries as t2
  where t2.playerid=t1.playerid and t1.yearid > t2.yearid)
  as averagebefore,
  (select t2.playerid, avg(salary)
  from salaries as t2
  where t2.playerid=t1.playerid and t1.yearid < t2.yearid)
  as averageafter
from awardwinningplayers_salary as t1;
