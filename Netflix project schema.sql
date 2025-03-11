-- Netflix Project Schema

create table netflix 
(
	show_id varchar(8),
	show_type varchar(15),
	title varchar(150),
	director varchar(210),
	casts varchar(1000),
	country varchar(150),
	date_added varchar(30),
	release_year INT,
	rating varchar(10),
	duration varchar(15),
	listed_in varchar(100),
	description varchar(270)
);
