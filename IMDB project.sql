-- Using the database 
USE imdb;



--  Writing queries to see data values from all tables
SELECT * FROM director_mapping;
SELECT * FROM genre;
SELECT * FROM movie;
SELECT * FROM names;
SELECT * FROM ratings;
SELECT * FROM role_mapping;

-- Checking the null values
SELECT 
    COUNT(CASE
        WHEN title IS NULL THEN id
    END) AS title_nulls,
    COUNT(CASE
        WHEN year IS NULL THEN id
    END) AS year_nulls,
    COUNT(CASE
        WHEN duration IS NULL THEN id
    END) AS duration_nulls,
    COUNT(CASE
        WHEN date_published IS NULL THEN id
    END) AS date_published_nulls,
    COUNT(CASE
        WHEN country IS NULL THEN id
    END) AS country_nulls,
    COUNT(CASE
        WHEN worlwide_gross_income IS NULL THEN id
    END) AS worlwide_gross_income_nulls,
    COUNT(CASE
        WHEN languages IS NULL THEN id
    END) AS languages_nulls,
    COUNT(CASE
        WHEN production_company IS NULL THEN id
    END) AS prduction_company_nulls
FROM
    movie;
    
    
-- 1 Find the total number of movies released in each year.
SELECT 
	year,
    COUNT(*) AS number_of_movies
FROM 
	movie
GROUP BY year;
-- from the above querie we got to know that 2017 ha the highest number of movies followed by 2018 and 2019 repectively

-- 1.1 To get the month from date_published column
SELECT
    MONTH(date_published) as month_num,
    COUNT(*) AS number_of_movies
FROM
    movie
GROUP BY month_num
ORDER BY month_num ;
-- The highest number of movies is produced in the month of March.

-- 2 Which genre had the highest number of movies produced overall?
SELECT 
	genre,
    COUNT(movie_id) AS movie_count
FROM
	genre
GROUP BY genre
ORDER BY movie_count desc
LIMIT 1;
-- Drama has the highest number of the number of movies produced 

-- 2.1 How many movies belong to only one genre?
WITH movie_genre_summary AS
(
	SELECT 
        movie_id,
        COUNT(genre) AS genre_count
    FROM genre
    GROUP BY movie_id
)
SELECT 
    COUNT(DISTINCT movie_id) AS single_genre_movie_count
FROM movie_genre_summary
WHERE genre_count = 1;
-- There are more than three thousand movies which have only one genre associated with them. This is a significant number.

-- 2.3 What is the average duration of movies in each genre? 
SELECT 
	g.genre,
    AVG(m.duration) AS avg_duration
FROM 
	movie m
LEFT JOIN 
	genre g
ON
	m.id = g.movie_id
GROUP BY 
	g.genre;
-- Now we know that movies of genre 'Drama' (produced highest in number in 2019) have an average duration of 106.77 mins.

-- 2.4 Find the ranking of each genre based on the number of movies associated with it. 
SELECT 
	  genre,
	  COUNT(movie_id) AS movie_count,
	  RANK () OVER (ORDER BY COUNT(movie_id) DESC) AS genre_rank
FROM
	genre
GROUP BY genre;
-- Drama is the 1st in the rank followed by the comedy

-- 3 Find the minimum and maximum values for each column of the 'ratings' table except the movie_id column.
SELECT 
    MIN(avg_rating) AS min_avg_rating,
    MAX(avg_rating) AS max_avg_rating,
    MIN(total_votes) AS min_total_votes,
    MAX(total_votes) AS max_total_votes,
    MIN(median_rating) AS min_median_rating,
    MAX(median_rating) AS max_median_rating    
FROM
    ratings;
-- So, the minimum and maximum values in each column of the ratings table are in the expected range. 


-- 3.1 What are the top 10 movies based on average rating?
WITH top_movies AS
(
	SELECT 
		m.title,
		AVG(r.avg_rating) AS avg_rating,
        ROW_NUMBER() OVER (ORDER BY AVG(r.avg_rating) DESC) AS movie_rank
	FROM 
		movie m 
	LEFT JOIN 
		ratings r 
	ON
		m.id = r.movie_id
	GROUP BY 
		m.title
)
SELECT 
	*
FROM 
	top_movies;

-- 3.2 Which production house has produced the most number of hit movies (average rating > 8)?
WITH top_prod AS
(
SELECT 
	m.production_company,
    r.avg_rating
FROM 
	movie m
LEFT JOIN 
	ratings r 
ON
	r.movie_id = m.id
WHERE 
	m.production_company IS NOT NULL 
HAVING
	avg_rating > 8
)
SELECT 
	production_company,
    COUNT(*) AS movie_count,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS prod_company_rank
FROM
	top_prod
GROUP BY 
	production_company
ORDER BY 
	movie_count DESC;
    
-- Dream Warrior Pictures and National Theatre Live has the most number of hit movies

-- 3.3 Do German movies get more votes than Italian movies? 
WITH german_italy_vote_summary AS 
 (
	SELECT 
		COUNT(CASE WHEN LOWER(m.languages) LIKE '%german%' THEN m.id END) AS german_movie_count,
		SUM(CASE WHEN LOWER(m.languages) LIKE '%german%' THEN r.total_votes END) AS german_movie_votes, 
        COUNT(CASE WHEN LOWER(m.languages) LIKE '%italian%' THEN m.id END) AS italy_movie_count,
        SUM(CASE WHEN LOWER(m.languages) LIKE '%italian%' THEN r.total_votes END) AS italy_movie_votes
	FROM 
		movie m 
	INNER JOIN 
		ratings r 
	ON 
		m.id = r.movie_id
 )
 SELECT 
	ROUND(german_movie_votes / german_movie_count, 2) AS german_votes_per_movie,
    ROUND(italy_movie_votes / italy_movie_count, 2) AS italy_votes_per_movie
FROM 
	german_italy_vote_summary;
-- Answer is yes

-- 4 The top three directors in each of the top three genres whose movies have an average rating > 8
WITH top_rated_genres AS
(
SELECT
    genre,
    COUNT(m.id) AS movie_count,
	RANK () OVER (ORDER BY COUNT(m.id) DESC) AS genre_rank
FROM
    genre AS g
        LEFT JOIN
    movie AS m 
		ON g.movie_id = m.id
			INNER JOIN
		ratings AS r
			ON m.id=r.movie_id
WHERE avg_rating>8
GROUP BY genre
)
SELECT 
	n.name as director_name,
	COUNT(m.id) AS movie_count
FROM
	names AS n
INNER JOIN
	director_mapping AS d
ON 
	n.id=d.name_id
INNER JOIN
	movie AS m
ON d.movie_id = m.id
INNER JOIN
	ratings AS r
ON m.id=r.movie_id
INNER JOIN
	genre AS g
ON g.movie_id = m.id
WHERE g.genre IN (SELECT DISTINCT genre FROM top_rated_genres WHERE genre_rank<=3)
AND avg_rating>8
GROUP BY name
ORDER BY movie_count DESC
LIMIT 3;

-- 5 Who are the top two actors whose movies have a median rating >= 8?
WITH ActorMovieRatings AS (
    SELECT
        n.name AS actor_name,
        m.id AS movie_id,
        r.median_rating
    FROM
        names AS n
    INNER JOIN
        role_mapping AS rm ON n.id = rm.name_id
    INNER JOIN
        movie AS m ON rm.movie_id = m.id
    INNER JOIN
        ratings AS r ON m.id = r.movie_id
    WHERE
        rm.category = 'actor' AND r.median_rating >= 8
)
SELECT
    actor_name,
    COUNT(DISTINCT movie_id) AS movie_count
FROM
    ActorMovieRatings
GROUP BY
    actor_name
ORDER BY
    movie_count DESC
LIMIT 2;    



