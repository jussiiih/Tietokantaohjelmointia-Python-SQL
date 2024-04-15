DROP TABLE IF EXISTS loan, member, item, book, author;

CREATE TABLE IF NOT EXISTS author (
	id SERIAL PRIMARY KEY,
	first_name TEXT NOT NULL,
	last_name TEXT NOT NULL);

CREATE TABLE IF NOT EXISTS book 
	(id SERIAL PRIMARY KEY,
	 title TEXT NOT NULL,
	 isbn_no TEXT CHECK (isbn_no LIKE '___-___-_____-_-_'),
	 author_id INT NOT NULL REFERENCES author(id));

CREATE TABLE IF NOT EXISTS city (
	id SERIAL PRIMARY KEY,
	name TEXT NOT NULL,
	areacode TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS item
	(id SERIAL PRIMARY KEY,
	 book_id INT REFERENCES book(id),
	 copy_no INTEGER,
	 media_type TEXT NOT NULL
);
	 
CREATE TABLE IF NOT EXISTS member
	(id SERIAL PRIMARY KEY,
	first_name TEXT NOT NULL,
	last_name TEXT NOT NULL,
	city_id INT REFERENCES city(id),
	address TEXT
);

CREATE TABLE IF NOT EXISTS loan (
	id SERIAL,
	member_id INT REFERENCES member NOT NULL,
	item_id INT REFERENCES item NOT NULL,
	due_date DATE NOT NULL
);

