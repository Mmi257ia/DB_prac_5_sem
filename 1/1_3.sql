/* 3) Сколько суммарно мест разных классов продано на рейсы, вылетевшие в последние сутки из Шереметьева */
SELECT 	fare_conditions AS "class",
		count(*)
FROM flights
	JOIN ticket_flights USING (flight_id)
WHERE 	(status = 'Departed' OR status = 'Arrived') AND
		departure_airport = 'SVO' AND
		actual_departure > (bookings.now() - (INTERVAL '1 DAY'))
GROUP BY (fare_conditions);