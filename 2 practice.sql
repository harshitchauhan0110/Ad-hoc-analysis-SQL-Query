SELECT * FROM  movies order by release_year desc ;

select * from movies where release_year = 2022;

select * from movies where release_year > 2020;

select * from movies where release_year>2020 and imdb_rating >8;

select * FROM movies where studio in ("marvel studios","hombale films");

select title , release_year from movies where title like "%thor%" order by release_year asc;

select * from movies where studio != "marvel studios";