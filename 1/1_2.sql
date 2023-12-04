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