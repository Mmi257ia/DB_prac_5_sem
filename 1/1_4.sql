/* 4) Какая доля мест в различных самолётах относится к бизнес-классу */
SELECT 	aircraft_code,
		model,
		ROUND((sum(is_business)::NUMERIC / count(*))*100, 2) AS percent
FROM (	SELECT *, CASE fare_conditions
					WHEN 'Business' THEN 1
					ELSE 0
				END AS is_business
		FROM seats) AS seats
	JOIN aircrafts USING (aircraft_code)
GROUP BY (aircraft_code, model);