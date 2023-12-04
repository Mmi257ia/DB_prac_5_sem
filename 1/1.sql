/* 1) 3 самых дешёвых рейса из Казани */
SELECT 	flight_no,
		arrival_airport,
		airport_name,
		city,
		min_amount AS price
FROM (	SELECT 	flight_id,
				MIN(amount) AS min_amount
		FROM ticket_flights
		GROUP BY flight_id) AS s
	JOIN flights USING (flight_id)
	JOIN airports ON (airports.airport_code = arrival_airport)
WHERE departure_airport = 'KZN'
GROUP BY (flight_no, arrival_airport, airport_name,	city, min_amount)
ORDER BY price ASC
LIMIT 3;

/* 2) Средняя цена проданного билета в различные аэропорты из Внукова в эконом-классе */
SELECT	arrival_airport,
		city,
		ROUND(AVG(amount)) as price
FROM ticket_flights
		JOIN flights USING (flight_id)
		JOIN airports ON (arrival_airport = airport_code)
WHERE departure_airport = 'VKO' AND fare_conditions = 'Economy'
GROUP BY (arrival_airport, city)
ORDER BY price;

/* 3) Сколько суммарно мест разных классов продано на рейсы, вылетевшие в последние сутки из Шереметьева */
SELECT 	fare_conditions AS "class",
		count(*)
FROM flights
	JOIN ticket_flights USING (flight_id)
WHERE 	(status = 'Departed' OR status = 'Arrived') AND
		departure_airport = 'SVO' AND
		actual_departure > (bookings.now() - (INTERVAL '1 DAY'))
GROUP BY (fare_conditions);

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
