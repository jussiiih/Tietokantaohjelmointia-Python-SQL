--1.List all actors first and last name whose first name is Christian
SELECT first_name, last_name FROM actor WHERE first_name = 'Christian';

--2.List all payments where the amount is greater than 8
SELECT * FROM payment WHERE amount > 8;

--3.List all payments where the amount is between 5 and 6
SELECT * FROM payment WHERE amount BETWEEN 5 AND 6;

--4.List all payments where the amount is less than 1 or greater than 10
SELECT * FROM payment WHERE amount > 10 OR amount < 1;

--5.List all films and actors of the films where the replacement cost is higher than 25
SELECT f.title, a.first_name, a.last_name, f.replacement_cost FROM film f
JOIN film_actor fa USING (film_id)
JOIN actor a USING (actor_id)
WHERE f.replacement_cost > 25;

--Group comparison (subquery)

--6.List the 10 payments with highest amount. Ordered from lowest amount to highest.
SELECT * FROM payment
ORDER BY amount DESC
LIMIT 10;

--7.List all customers who have made at least one payment with amount 0. Using the EXISTS operator
SELECT c.first_name, c.last_name FROM customer c
WHERE EXISTS
(SELECT p.customer_id FROM payment p
 WHERE p.amount = 0 AND c.customer_id = p.customer_id)
;

--8.List all customers who have made at least one payment with amount 0. Using the IN operator
SELECT c.first_name, c.last_name FROM customer c
WHERE c.customer_id IN (SELECT p.customer_id FROM payment p
WHERE p.amount = 0);

--9.List all customers who have made at least one payment with amount 0. Using the ANY operator
SELECT c.first_name, c.last_name FROM customer c
WHERE c.customer_id = ANY
(SELECT p.customer_id FROM payment p
WHERE p.amount = 0);
--10.List all the movies that was rented between May 27th 05 and May 29th 05

SELECT f.title, r.rental_date FROM rental r
JOIN inventory i USING (inventory_id)
JOIN film f USING (film_id)
WHERE rental_date BETWEEN '2005-05-27 00:00:00' AND '2005-05-29 23:59:59';

--11.Get the movie title of movies that was rented between May 27th 05 and May 29th 05.

SELECT f.title, r.rental_date FROM rental r
JOIN inventory i USING (inventory_id)
JOIN film f USING (film_id)
WHERE rental_date BETWEEN '2005-05-27 00:00:00' AND '2005-05-29 23:59:59';

--12.List the average payment amount of each staff member.
SELECT s.first_name, s.last_name, AVG(p.amount) FROM staff s
JOIN payment p USING (staff_id)
GROUP BY s.first_name, s.last_name;


--13.List all payments where the payment amount is greater than the average amount of each staff member
SELECT p.payment_id, p.staff_id, p.amount, a.average FROM payment p

JOIN 
(SELECT s.staff_id as staffi, AVG(p.amount) as average FROM staff s
JOIN payment p USING (staff_id)
GROUP BY s.staff_id) a
ON a.staffi = p.staff_id

WHERE p.amount > a.average
;


--14.List the actors firstname and lastname where first name that starts with 'E'.
SELECT first_name, last_name FROM actor WHERE SUBSTRING(first_name, 1, 1) = 'E';

--15.List the actors where the first name contains an 'E'
SELECT first_name, last_name FROM actor WHERE first_name LIKE  '%E%' OR first_name LIKE  '%e%';

--16.List all films and the actors of the film where the film is in some way about a crocodile.
SELECT f.title, a.first_name, a.last_name FROM film f
LEFT JOIN film_actor ac USING (film_id)
LEFT JOIN actor a USING (actor_id)
WHERE lower(f.description) like '%croco%'; 

SELECT f.description FROM film f
WHERE (f.description) like '%Croco%'; 

SELECT title, fulltext FROM film
WHERE CAST(fulltext AS TEXT) like '%crocodile%' OR CAST(fulltext AS TEXT) like '%Crocodile%'; 

 
--17.List the staff who don't have a picture

SELECT * FROM staff WHERE picture IS NULL;

--18.List all rentals that are not returned.
SELECT * FROM rental WHERE return_date IS NULL;

--19.List the customers whose first name or last name is 'Kim'
SELECT first_name, last_name FROM customer WHERE first_name = 'Kim' OR last_name = 'Kim';

--20.List all films where the category is either 'Action' or 'Drama'



