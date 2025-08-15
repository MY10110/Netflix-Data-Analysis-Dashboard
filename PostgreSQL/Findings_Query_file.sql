-- 1. CREATE DATABASE.
Create database netflix_db;

-- Switch to the new database before running next commands
\c netflix_db;

-- 2. SCHEMAS of Netflix Table.
CREATE TABLE netflix
(
	id	VARCHAR(5),
	type    VARCHAR(10),
	title	VARCHAR(300),
	director VARCHAR(500),
	casts	VARCHAR(1000),
	country	VARCHAR(500),
	date_added	VARCHAR(50),
	release_year INT,
	rating	VARCHAR(20),
	duration	VARCHAR(20),
	listed_in	VARCHAR(200),
	description VARCHAR(500)
);

-- 3. DATA CLEANING & PREPARATION

-- Checking NULL values Counts for each column.
SELECT 
    COUNT(*) FILTER (WHERE show_id IS NULL) AS null_show_id,
    COUNT(*) FILTER (WHERE type IS NULL) AS null_type,
    COUNT(*) FILTER (WHERE title IS NULL) AS null_title,
    COUNT(*) FILTER (WHERE director IS NULL) AS null_director,
    COUNT(*) FILTER (WHERE casts IS NULL) AS null_casts,
    COUNT(*) FILTER (WHERE country IS NULL) AS null_country,
    COUNT(*) FILTER (WHERE date_added IS NULL) AS null_date_added,
    COUNT(*) FILTER (WHERE release_year IS NULL) AS null_release_year,
    COUNT(*) FILTER (WHERE rating IS NULL) AS null_rating,
    COUNT(*) FILTER (WHERE duration IS NULL) AS null_duration,
    COUNT(*) FILTER (WHERE listed_in IS NULL) AS null_listed_in,
    COUNT(*) FILTER (WHERE description IS NULL) AS null_description
FROM netflix;

-- Replace NULLs with placeholders.
Update netflix 
set director = 'Unknown'
where director is null;

Update netflix
set casts = 'Unknown'
where casts is null;

Update netflix 
set country = 'Unknown'
where country is null;

/* Set missing data_added to placeholder '2000-01-01'
to indicate missing information while keeping column as Date Type. */
Update netflix
set date_added = 'January 01, 2001'
where date_added is null;

Update netflix
set rating = 'Not Rated'
where rating is null;

Update netflix 
set duration = 'Not Available'
where duration is null;

-- 4. ANALYSIS QUERIES.

-- 1, Total number of titles
Select count(*) as Total_Titles from netflix;

-- 2, Count movies VS shows
Select type, count(*) AS total, 
Round(Count(*) * 100.0 / (select count(*) from netflix), 2) as percentage
from netflix
group by type
order by total DESC;

-- 3, Top 10 countries with most titles
Select country, count(*) as total
from netflix
where country != 'Unknown'
group by country
order by total DESC
limit 10;

-- 4, Most common ratings
Select rating, count(rating) as total 
from netflix
group by rating
order by total DESC;

-- 5, List all TV shows with more than 5 seasons
Select title from netflix
where duration > '5 Season';

-- 6, Find All Children's Movies/TV Shows
Select * from netflix
where listed_in Like '%Children%'
or listed_in LIKE '%Family Movies%'
or listed_in Like '%Kids';

-- 7, Top 10 Directors of Children's Content
Select director,
count(*) as content_count
from netflix
where listed_in like '%Children%' 
and director != 'Unknown'
group by director 
order by content_count DESC
limit 10;

-- 8, Releses per year
Select release_year, count(*) as total 
from netflix
group by release_year
order by release_year DESC;

-- 9, Top 10 directors with most titles
Select director, count(*) as total_titles
from netflix
where director != 'Unknown'
group by director 
order by total_titles DESC
limit 10;

-- 10, Top 10 actors with most appearances
select actor, count(*) as Total_Appearances
from (Select unnest(String_to_array(casts, ',')) as actor
from netflix) as actors_list
where actor != 'Unknown' 
group by actor 
order by total_appearances DESC
limit 10;

-- 11, Top 10 genres/listed_in
Select genres, count(*) as total
from (Select unnest(string_to_array(listed_in, ','))as genres
from netflix) as genres_list
group by genres
order by total DESC
limit 10;

-- 12, Average movie duration (in minutes) - only for Movies
Select Avg(cast(REGEXP_REPLACE(duration, '\D', '', 'g') as INT)) as avg_movie_minutes
from netflix
Where type = 'Movie' and duration != 'Not Available';
  
-- 13, Distribution of TV show seasons
Select duration as seasons, count(*) as total_shows
from netflix
where type = 'TV Show'
group by duration
order by total_shows DESC;

-- 14, Movies with duration more than 2 hours
SELECT title, duration
FROM netflix
WHERE type = 'Movie' and duration != 'Not Available' AND CAST(split_part(duration, ' ', 1) AS INT) > 120
order by duration DESC;

-- 15, Longest and Shortest movie
With movie_duration as (
select title, CAST(NULLIF(REGEXP_REPLACE(duration, '\D', '', 'g'), '') AS INT) AS minutes
from netflix
where type = 'Movie' and duration != 'Not Available'
)
(Select title, minutes, 'Longest' as category
from movie_duration
order by minutes DESC
limit 1
)
union all
(Select title, minutes, 'Shortest' as category
from movie_duration
order by minutes ASC
limit 1
);

-- 16, Avg. Yearly Releases in India (Top 5 Years)
SELECT release_year,
       COUNT(*)::NUMERIC / COUNT(DISTINCT release_year) AS avg_content
FROM netflix
WHERE country = 'India'
GROUP BY release_year
ORDER BY avg_content desc
LIMIT 5;

-- 17, List all movies that are documentaries
SELECT *
FROM netflix
WHERE type = 'Movie' AND listed_in LIKE '%Documentaries%';

-- 18, Find how many movies actor 'Salman Khan', 'Aamir Khan', 'Tom Cruise' appeared in last 10 years
Select count(case when casts like '%Salman Khan%' then 1 end) as Salman_Khan_Movies,
count(case when casts like '%Aamir Khan%' then 1 end) as aamir_Khan_Movies,
count(case when casts like '%Tom Cruise%' then 1 end) as tom_curise_Movies
from netflix
where type = 'Movie';

-- 19, Top 10 Indian Movie Actors
Select trim(actor) as actor, count(*) as total_appearances
from (select unnest(STRING_TO_ARRAY(casts, ',')) as actor
from netflix
where type = 'Movie' and country ILIKE '%India%' and casts != 'Unknown'
) as actors_list
group by actor
order by total_appearances DESC
limit 10;

-- 20, Content Classification: Good vs Bad
Select 
case when description ILIKE '%kill%' or description ILIKE '%violence%' then 'Bad'
else 'Good'
end as category,
count(*) as total_count
from netflix
group by category;




