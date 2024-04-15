--1.

SELECT c.name, a.name, COUNT(a.name) AS times_readed
FROM customer c
JOIN article_reads ar ON c.id = ar.customer_id
JOIN article a ON a.id = ar.article_id
GROUP BY c.name, a.name
ORDER BY c.name, a.name
;

--2
SELECT customer, COUNT(article) as distinct_article_read FROM

(SELECT DISTINCT c.name AS customer, a.name AS article
FROM customer c
JOIN article_reads ar ON c.id = ar.customer_id
JOIN article a ON a.id = ar.article_id
)
GROUP BY customer
ORDER BY COUNT(article) DESC
LIMIT 10
;

--3


SELECT a.customer, a.distinct_article_read

FROM

(SELECT customer, customer_id, COUNT(article) as distinct_article_read FROM
(SELECT DISTINCT c.name  AS customer, c.id AS customer_id, a.name AS article
FROM customer c
JOIN article_reads ar ON c.id = ar.customer_id
JOIN article a ON a.id = ar.article_id
)
GROUP BY customer, customer_id
ORDER BY COUNT(article) DESC) a

JOIN paper_subscription ps ON a.customer_id = ps.customer_id
WHERE ps.status = 'Inactive' AND a.distinct_article_read > 200
ORDER BY a.distinct_article_read DESC
;

--4
SELECT c.country, ar.article_id,  COUNT (c.name) AS total_reads
FROM article_reads ar
JOIN customer c ON ar.customer_id = c.id
GROUP BY c.country, ar.article_id
;

--5

SELECT country, article_id, MAX (total_reads)FROM

(SELECT c.country, ar.article_id,  COUNT (c.name) AS total_reads
FROM article_reads ar
JOIN customer c ON ar.customer_id = c.id
GROUP BY c.country, ar.article_id)

GROUP BY
country
;
