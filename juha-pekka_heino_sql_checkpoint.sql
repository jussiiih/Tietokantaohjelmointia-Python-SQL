--TASK 1

--1.1
DROP VIEW IF EXISTS employees_list_all;
DROP TABLE IF EXISTS employees;

CREATE TABLE IF NOT EXISTS employees
	(emp_id SERIAL PRIMARY KEY,
	 emp_name VARCHAR (50) NOT NULL,
	 emp_salary INTEGER NOT NULL CHECK (emp_salary > 0),
	 hire_date DATE NOT NULL,
	 emp_address VARCHAR (50)
	);

--1.2
INSERT INTO employees (emp_name, emp_salary, hire_date, emp_address) VALUES
('Pekka Virtanen', 30000, '2020-01-01', 'Helsingintie 10'),
('Maija Korhonen', 35000, '2023-07-15', 'Turuntie 5'),
('Matti Nieminen', 40000, '2019-10-04', 'Tampreentie 10'),
('Maija Nieminen', 40000, '2019-10-04', 'Tampreentie 10'),
('Liisa Heinonen', 32000, '2024-01-01', 'Kuopiontie 8'),
('Otto Kangas', 500, '2023-01-01', 'Lohjantie 8'),
('Kalevi Metsälä', 45000, '2010-01-04', null);

--1.3
SELECT * FROM employees;

--1.4
CREATE VIEW employees_list_all AS SELECT * FROM employees;

--TASK 2

--2.1.
SELECT * FROM employees WHERE emp_address IS NULL;

--2.2
SELECT * FROM employees WHERE emp_salary > 1000;

--2.3
SELECT * FROM employees WHERE emp_address IS NOT NULL;

--2.4
SELECT * FROM employees WHERE emp_salary > 32000 ORDER BY hire_date DESC;

--2.5.
SELECT EXTRACT (YEAR FROM hire_date), COUNT (*)
FROM employees
GROUP BY EXTRACT (YEAR FROM hire_date);


--2.6
SELECT * FROM employees WHERE emp_salary >
(SELECT AVG(emp_salary) FROM employees);

--2.7 doesn't work!
/*
WITH salary_per_hire_date AS
(SELECT EXTRACT (YEAR FROM hire_date) AS year, EXTRACT (MONTH FROM hire_date) AS month, SUM(emp_salary) AS total
FROM employees
GROUP BY EXTRACT (YEAR FROM hire_date), EXTRACT (MONTH FROM hire_date)
ORDER BY year, month)


SELECT (EXTRACT(YEAR FROM a.hire_date)) AS year, EXTRACT (MONTH FROM a.hire_date), (SUM(b.total))
FROM salary_per_hire_date a, salary_per_hire_date b

WHERE b.month <= a.month AND b.year <= a.year
		
GROUP BY EXTRACT (YEAR FROM a.hire_date), EXTRACT (MONTH FROM a.hire_date)
;

AS month, SUM(emp_salary) AS total
FROM employees
GROUP BY EXTRACT (YEAR FROM hire_date), EXTRACT (MONTH FROM hire_date)
;
*/
--2.8
DELETE FROM employees WHERE emp_address IS NULL;
