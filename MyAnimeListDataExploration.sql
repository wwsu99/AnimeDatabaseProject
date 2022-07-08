---Leftover cleaning in SQL to check that everything from Excel imported correctly
select *
from Anime.Dbo.Genre
where Mal_id = 23427
;

---Hundreds of Anime have special symbols in their names that were unreadable by Microsoft SQL and converted into accented unicode characters, so this query was used to detect any of those characters unable to be typed out on a traditional keyboard.  
select *
from Anime.Dbo.Genre
where name like '%[^a-Z0-9 :;!@#$%&*()-_/?".''~]%'
;

---This is another query to filter out the listed characters specifically in order to make sure that the previous query was working for all required cases.  
select *
from Anime.Dbo.Genre
where name like '%[â™¡]%'
;

---Looking at the highest rated Anime, and what genres typically populated the highest scored Anime.  
select *
from Anime.Dbo.Genre
order by score DESC
;

---Importing error caused the year column to concatenate with unused columns in the original Excel file.  Used this query to make sure that when I updated the year column, the resulting rows would be correct.  
select left(Year, 4) as Year2
from Anime.Dbo.Genre
;

---Created a new column filled with the 'year' values I had wanted originally.  
alter table Anime.Dbo.Genre
add Year2 int 
;

---Updated the new 'year2' columnn instead of the original 'year' column, so that if I made a mistake I could roll it back by deleting the column and starting over from step one.
update anime.dbo.genre
set Year2 = left(Year, 4)
;

---Testing to see if the cells were populated correctly.
select Year2
from Anime.Dbo.Genre
;

---The cells were populated correctly, so now I replace the original 'year' column with the new 'year2' column.  I then went into the object explorer in SSMS, and changed 'year2' into 'year'.  
Alter table anime.dbo.genre
drop column year
;

---Double checking to see if the update went well.  After double checking the new 'year' column, I moved on to explore the data using various queries.  
Select year
from anime.dbo.genre
;

---Looking at total views across genres.  Views in this case refers to people who have an account on MyAnimeList.com, and have added the Anime to their watch list.  This means that they have already watched the Anime.
---Used an inner join so that only Anime found in both the genre and studio tables would be returned in the query. 
select sum(S.Views) AS TotalViews, G.Genres
from Anime.Dbo.Studio as S
inner join Anime.Dbo.Genre as G
	on S.Mal_id = G.Mal_id
group by G.Genres
order by TotalViews DESC
;

---Looking at average views across genres.
---Would average or total views be a better predictor a possible success for the adaptation of an Anime?  Can we predict what genres tend to be more successful towards different markets throughout the world based on existing viewer trends?
select avg(S.Views) AS AverageViews, G.Genres
from Anime.Dbo.Studio as S
join Anime.Dbo.Genre as G
	on S.Mal_id = G.Mal_id
group by G.Genres
order by AverageViews DESC
;

---Looking at the highest viewed genre (comedy) and a genre that had a surprisingly high average amount of views (vampire).  
select G.Mal_id, G.Genres, G.Name, S.Views, S.Favorites
from Anime.Dbo.Studio as S
inner join Anime.Dbo.Genre as g
	on S.Mal_id = G.Mal_id
where G.Genres = 'comedy'
order by S.Views desc
select G.Mal_id, G.Genres, G.Name, S.Views, S.Favorites
from Anime.Dbo.Studio as S
inner join Anime.Dbo.Genre as G
	on S.Mal_id = G.Mal_id
where G.Genres = 'vampire'
order by S.Views DESC
;

---Comparing the number of vampire vs comedy Anime
---Was 'vampire' chosen as a genre on the MyAnimeList website due to general popularity of top vampire Anime, or are these Anime popular because they have vampires?
---Because there is a small amount of Anime out, it is possible the data is more likely to be skewed with a smaller number of outliers compared to a larger genre such as 'comedy.'
select count(G.Genres) as GenreCount, G.Genres
from Anime.Dbo.Genre as G
where G.Genres = 'vampire' or G.Genres = 'comedy'
group by G.Genres
;

---Further exploring why 'comedy' has as low average view count per anime compared to 'vampire'.
---Having a high number of anime doesn't explain the whole story, so I came up with a query to find a column called 'lowviewpercentage' where it counts the number of anime that have less than 100,000 views.  I then grouped then by genre 
---I hypothesized there could be a possible correlation between the number of Anime a genre has, and the average views these Anime get. As 'AnimeCount' gets higher, the 'AverageAnimeViews' also becomes more skewed, which leads to genres having less Anime tend to have either the highest or lowest amount of average Anime views due to the lack of Anime in these specific genres compared to genres that have more Anime.
---So, I ran a linear regression test to see if there was a significant, linear relationship between # of anime (AnimeCount) and the average amount of views a genre of Anime typically get (AverageAnimeViews).  
---H0: β1 = 0, HA: β1 ≠ 0, and we are running this with a p-value of .05.  What this is saying is that we are looking for one of two things in our statistic test: the null hypothsis (H0); the alternative hypothesis (HA).  Either there is a statistically significant relationship between AnimeCount and AverageAnimeViews (HA), or there isn't one (H0).  We can tell if there is a significant relationship is if the p-value (in this case, the percent chance that the number of Anime didn't influence the average amount of views a certain genre received) is less than 5%, or .05. 
---I then ran the following query and imported the data into an Excel file with the 'DataAnalysis.pak' and ran a linear regression test with AverageAnimeViews as the dependent variable, and AnimeCount as the independent variable.  
---The resulting p-value was .5878, which is higher than the .05 value that we have assigned to this test, meaning there was a 58.78% chance that AverageAnimeViews happened entirely by chance, and not due to AnimeCount.
---In summary, we fail to reject the null hypothesis.  There is no statistically significant relationship between number of Anime in a given genre, and the average amount of views a genre of Anime get.  
select AnimeCount, LowAnimeCount, (cast(LowAnimeCount as float)/cast(AnimeCount as float))*100 as LowViewPercentage, AverageAnimeViews, TempTable.genres
from
	(
	select G.Genres, count(s.views) as AnimeCount, count(case when views < 100000 then 1 else null end) as LowAnimeCount, avg(s.views) as AverageAnimeViews
	from Anime.Dbo.Genre as G
	inner join Anime.Dbo.Studio as S
		on G.Mal_id = S.Mal_id
	group by G.Genres
	) as TempTable
order by AnimeCount DESC
;

---Looking at the most viewed Anime.
select distinct G.Name, S.Views, S.Favorites
from Anime.Dbo.Studio as S
inner join Anime.Dbo.Genre as G
	on S.Mal_id = G.Mal_id
order by S.Views DESC
;

---Most favorited anime.  Favorites in this case refers to an anime that is within a user's "Top 10 Anime."  This means that if a user favorited the Anime, they are more likely to financially support the show by buying merchandise, going to a movie screening, etc.  So a higher favorite rate is, in some cases, more desirable for an Anime than higher view rate.  
select distinct G.Name, S.Views, S.Favorites
from Anime.Dbo.Studio as S
inner join Anime.Dbo.Genre as G
	on S.Mal_id = G.Mal_id
order by S.Favorites DESC
;

---Creating a new column called 'FavoritePercentage' where we calculate the rate of favorites based on the number of views an Anime has.  We are looking for the Anime that have the highest % chance of being in a user's top 10 list. 
select DISTINCT g.name, s.views, s.favorites, (s.favorites/s.views)*100 as favoritepercentage
from Anime.Dbo.Studio as S
inner join anime.dbo.genre as G
	on S.Mal_id = G.Mal_id
where S.Views > 10000
order by FavoritePercentage DESC
;

---'PopularityRanking' is the rank assigned to an anime based on the number of views they have, with "1" being the highest rank.  I am using this to determine which genre has the highest average popularity ranking, and well as the highest average score.  
select avg(S.PopularityRanking) as AverageRanking, avg(cast(G.Score as float)) as AverageScore, G.Genres
from Anime.Dbo.Studio as S
inner join Anime.Dbo.Genre as G
	on S.Mal_id = G.Mal_id
group by G.Genres
order by AverageRanking
;

---Looking at the total view count for two of the top trending Anime of the year using a union.  
with Summary (Name, Views, Favorites, Score) as 
(
	select distinct G.Name, S.Views, S.Favorites, G.score
	from Anime.Dbo.Studio as S
	inner join Anime.Dbo.Genre as G
		on S.Mal_id = G.Mal_id
)
select sum(Views) as TotalViews, 'Attack on Titan'
from Summary
where name like '%Shingeki no Kyojin%'
UNION 
select sum(Views), 'One Piece'
from Summary
where name like '%One Piece%'
;

---Comparing again, but with the results in different columns so that I can use them in different functions if needed.  
with Summary (Name, Views, Favorites, Score) as 
(
	select G.Name, S.Views, S.Favorites, G.Score
	from Anime.Dbo.Studio as S
	inner join Anime.Dbo.Genre as G
		on S.Mal_id = G.Mal_id
)
Select sum(AOT.Views) as AttackOnTitanTotalViews, sum(OP.Views) as OnePieceTotalViews
From 
	(
	select (Table1.views), ROW_NUMBER() over (order by views) as rn
		from (select distinct views
			from summary
			where name like '%Shingeki no Kyojin%') as Table1
	) as AOT
FULL OUTER JOIN 
	(
	select (Table2.views), ROW_NUMBER() over (order by views) as rn
	from (select distinct views
		from summary
		where name like '%One Piece%') as Table2
	) as OP
ON AOT.rn = OP.rn
;

---Looking at which source material has the highest chance for success for an Anime's popularity.  
select sum(Views) as TotalViews, sum(Favorites) as TotalFavorites, avg(Views) as AverageViews, avg(Favorites) as AverageFavorites, max(Views) as HighestViews, max(Favorites) as HighestFavorite, Source
from Anime.Dbo.Studio
group by Source
order by sum(Views) DESC
;

---Looking at total and average views across seasons to determine which season has the highest views.  
---Anime tend to get released on a seasonal schedule where all Anime studios have an unoffical agreement to release Anime roughly around the same time in different "seasons" in order to maintain a consistent premiering schedule.
---By not following this trend, they run the risk of destroying their employees' work flow, because each Anime is a large scale project where a lot of money and timer are invested in each one, and most animation companies cannot afford for an Anime to flop.  
with SeasonalViews as 
(
select Views, 
(CASE
	when Premiered like '%Spring%' then 'Spring'
	when Premiered like '%Fall%' then 'Fall'
	when Premiered like '%Summer%' then 'Summer'
	when Premiered like '%Winter%' then 'Winter'
	else null
END) as Season
from Anime.Dbo.Studio as S
inner join Anime.Dbo.Genre as G
	on S.Mal_id = G.Mal_id
)
select sum(Views) as TotalViews, avg(Views) as AverageViews, Season
from SeasonalViews
group by Season
;

---Using the previous case function, I figured I could improve on the previously used union function in order to make adding in new Anime much easier.   
with Summary as 
(
	select distinct G.Name, S.Views, S.Favorites, G.Score, 
		(CASE
			when G.Name like '%One Piece%' then 'One Piece'
			when G.Name like '%Shingeki no Kyojin%' then 'Attack on Titan'
			else Null
		END) as EnglishName
	from Anime.Dbo.Studio as S
	inner join Anime.Dbo.Genre as G
		on S.Mal_id = G.Mal_id
)
select sum(Summary.Views) as TotalViews, EnglishName
from Summary
where EnglishName is not null
group by EnglishName