--1. Count the number of Movies vs TV Shows

select show_type , count(*)
from netflix n 
group by 1

-- 2. Find the most common rating for movies and TV shows

with rating_count as 
(
select show_type ,rating ,count(*) as rate_count
from netflix
group by 1,2
order by 1,2)
,
rating_rank as 
(
select *, dense_rank() over (partition by show_type order by rate_count desc) as rnk
from rating_count)

select show_type, rating as common_rating
from rating_rank
where rnk=1


-- 3. List all movies released in a specific year (e.g., 2020)

	---- 1st approach if specific year is not mentioned and all titles need to be in one row
	select release_year , string_agg(title,' , ') 
	from netflix n
	where show_type ='Movie'
	group by 1
	order by 1 desc

	--- 2nd straight forwd, filtering on show_type and release_year and listing down all titles
	select release_year ,title 
	from netflix n 
	where show_type ='Movie' and release_year =2020
	

	
-- 4. Find the top 5 countries with the most content on Netflix

--	select coalesce(nullif(country,''),'NULL') as country , count(title) as content_count
--	from netflix n
--	group by 1
--	order by content_count desc
--	limit 5

	select trim(unnest(string_to_array(country,','))) as new_country, count(title)
	from netflix n 
	group by 1
	order by 2 desc
	limit 5
	

-- 5. Identify the longest movie
	
	select show_type ,title ,duration , coalesce( nullif(substring(duration,0, position(' ' in duration)),''),'0')::integer as new_duration
	from netflix n 
	where show_type ='Movie'
	order by 4 desc
	limit 1

	
-- 6. Find content added in the last 5 years

	with new_date as 
	(
	SELECT *,CAST(NULLIF(TRIM(date_added), '') AS DATE) AS date_added_new,
	max(CAST(NULLIF(TRIM(date_added), '') AS DATE)) over () as max_date
	FROM netflix
	)

	select title,date_added_new
--	date_added_new, max_date, date_part('year',max_date) - date_part('year',date_added_new)
	from new_date
	where date_part('year',max_date) - date_part('year',date_added_new) <= 5
	
	
-- 7. Find all the movies/TV shows by director 'Rajiv Chilaka'!
	
	select show_type ,title ,director 
	from netflix n 
	where director like '%Rajiv Chilaka%'
	
-- 8. List all TV shows with more than 5 seasons
	
	select show_type ,title ,duration 
	from netflix n 
	where show_type ='TV Show' and split_part(duration,' ',1)::integer >=5
	order by split_part(duration,' ',1)::integer desc
--	and coalesce( nullif(substring(duration,0, position(' ' in duration)),''),'0')::integer >=5
--	order by coalesce( nullif(substring(duration,0, position(' ' in duration)),''),'0')::integer desc
	
			
--9. Count the number of content items in each genre
	
	select trim(unnest(string_to_array(listed_in,','))) as genre ,count(title) 
	from netflix n 
	group by 1
	order by count(title) desc
	
	
--10.Find each year and the average numbers of content release in India on netflix. 
	--return top 5 year with highest avg content release!
	
	--1st approach by release year
	with unnest_country as 
	(
	select *, trim(unnest(string_to_array(country,','))) as new_country
	from netflix n )
	
	select release_year, count( title),
	(count(title)::numeric / 
	(select count(*) from unnest_country where new_country='India')::numeric) * 100.00 as avg_title_each_year
	from unnest_country
	where new_country='India'
	group by 1
	order by avg_title_each_year desc
	
	--2nd approach by date_added year

	with temp_table as 
	(
	select trim(unnest(string_to_array(country,','))) as new_country,
	extract(year from cast(nullif(date_added,'') as date)) as dete_add_year,
	*
	from netflix n )
	
	select dete_add_year, count(*),
	round((count(*)::numeric 
	/
	(select count(*) from temp_table where new_country='India')::numeric) *100.00,1) as avg_title_per_year
	from temp_table
	where new_country = 'India'
	group by 1
	order by avg_title_per_year desc
	
	
	
	
--11. List all movies that are documentaries
	
	select *
	from netflix n 
	where listed_in ilike '%Documentaries%' and show_type ='Movie'
	
		
--12. Find all content without a director
	
	select title
	from (
	select *,nullif(director,'') as director_n
	from netflix n )a
	where director_n is null
	
	
--13. Find how many movies actor 'Salman Khan' appeared in last 10 years!
	
	with new_date as 
	(
	SELECT *,CAST(NULLIF(TRIM(date_added), '') AS DATE) AS date_added_new,
	max(CAST(NULLIF(TRIM(date_added), '') AS DATE)) over () as max_date
	FROM netflix
	)

	select title,casts
--	date_added_new, max_date, date_part('year',max_date) - date_part('year',date_added_new)
	from new_date
	where date_part('year',max_date) - date_part('year',date_added_new) <=10
	and show_type='Movie'
	and
	casts ilike '%Salman Khan%'
	
--14. Find the top 10 actors who have appeared in the highest number of movies produced in India.
	
	with actor_rank as 
	(
	select trim(unnest(string_to_array(casts,','))) as new_casts, count(title)as no_of_movies,
	dense_rank() over ( order by count(title)desc ) as ranks
	from netflix n
	where country= 'India' and show_type ='Movie'
	group by 1
	)
	
	select new_casts,no_of_movies
	from actor_rank
	where ranks <=10
	
--15.Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
--the description field. Label content containing these keywords as 'Bad' and all other 
--content as 'Good'. Count how many items fall into each category.
	
	with content_categorized as 
	(
	select *,
	case when description ilike '%kill%' or description ilike '%violence%' then 'Bad'
	else 'Good'
	end as content_quality
	from netflix n 
	)
	
	select content_quality, count(*)
	from content_categorized
	group by 1
	