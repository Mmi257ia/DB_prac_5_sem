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