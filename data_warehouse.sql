DROP TABLE IF EXISTS contact, telephone, email, fax, skype, instagram, title, organization, city;

CREATE TABLE contact (
	contact_id SERIAL PRIMARY KEY,
	first_name TEXT NOT NULL,
	last_name TEXT NOT NULL,
	address TEXT,
	postal_code TEXT
);

CREATE TABLE telephone (
	contact_id INTEGER REFERENCES contact (contact_id),
	phone_type TEXT,
	telephone_number TEXT,
	PRIMARY KEY (contact_id, phone_type)
);

CREATE TABLE email (
	contact_id INTEGER REFERENCES contact (contact_id),
	email_type TEXT,
	email_address TEXT,
	PRIMARY KEY (contact_id, email_type)
);

CREATE TABLE fax (
	contact_id INTEGER REFERENCES contact (contact_id),
	fax_address TEXT,
	PRIMARY KEY (contact_id)
);

CREATE TABLE skype (
	contact_id INTEGER REFERENCES contact (contact_id),
	skype_name TEXT,
	PRIMARY KEY (contact_id)
);

CREATE TABLE instagram (
	contact_id INTEGER REFERENCES contact (contact_id),
	instagram_account TEXT,
	PRIMARY KEY (contact_id)
);

CREATE TABLE title (
	contact_id INTEGER REFERENCES contact (contact_id),
	title_name TEXT,
	PRIMARY KEY (contact_id)
);

CREATE TABLE organization (
	contact_id INTEGER REFERENCES contact (contact_id),
	organization_name TEXT,
	PRIMARY KEY (contact_id)
);

CREATE TABLE city (
	postal_code TEXT,
	city_name TEXT NOT NULL,
	PRIMARY KEY (postal_code)
);


ALTER TABLE contact ADD FOREIGN KEY (postal_code) REFERENCES city(postal_code);

INSERT INTO city (postal_code, city_name)
VALUES
('01003', 'Helsinki'),
('04430', 'Järvenpää');

INSERT INTO contact (first_name, last_name, address, postal_code)
VALUES
('Hanna', 'Niemi', 'Eteläkatu 35', '01003'),
('Juha-Pekka', 'Heino', 'Pohjoiskatu 35', '04430');


INSERT INTO telephone VALUES
(1, 'private', '+3589678901'),
(2, 'work', '+3581234567');

INSERT INTO email VALUES
(1,' work', 'hanna.kinnunen@ssvhelsinki.fi'),
(1, 'private', 'hanna.kinnunen@gmail.com'),
(2, 'work', 'juhapekka.heino@brightstraining.com');


INSERT INTO instagram VALUES
(1,'@hanna.kinnunen'),
(2, '@juhapekka.heino');

INSERT INTO title VALUES
(1,'Chairman'),
(2, 'Data Engineer');

INSERT INTO organization VALUES
(1,'SSV Helsinki'),
(2, 'Academic Work');

INSERT INTO fax VALUES
(1,'+35847895451'),
(2, '+35878556');

INSERT INTO skype VALUES
(1,'hanna.niemi'),
(2, 'juha.pekka.heino');



SELECT * FROM contact FULL JOIN
telephone USING (contact_id) FULL JOIN
email USING (contact_id) FULL JOIN
fax USING (contact_id) FULL JOIN
skype USING (contact_id) FULL JOIN
instagram USING (contact_id) FULL JOIN
title USING (contact_id) FULL JOIN
organization USING (contact_id)FULL JOIN
city USING (postal_code)
;




