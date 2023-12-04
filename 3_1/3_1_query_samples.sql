---SELECT * FROM calling LIMIT 10;
---SELECT * FROM calling WHERE array_length(caller_cell_tower, 1) >= 5 AND array_length(receiver_cell_tower, 1) >= 5;
---SELECT sum(price) FROM calling; /* 19 sec */
/*SELECT sum(EXTRACT(minutes from ending - beginning) * fee)
FROM calling
	JOIN tariff_connection ON caller_tariff_connection_id = tariff_connection_id
	JOIN tariff USING (tariff_id)
WHERE type = 'per_minute';*/ /* 68 sec */