DROP VIEW public.calling_numbs;
DROP VIEW public.person;
DROP VIEW public.subscriber_unpacked;

/* Звонки с подставленными номерами вместо tariff_connection и без данных о сотовых вышках */
CREATE OR REPLACE VIEW public.calling_numbs AS
SELECT  calling_id,
		caller.numb AS caller_numb,
		receiver.numb AS receiver_numb,
		beginning,
		ending,
		price
FROM 	 calling
	JOIN tariff_connection AS caller ON caller_tariff_connection_id = caller.tariff_connection_id
	JOIN tariff_connection AS receiver ON receiver_tariff_connection_id = receiver.tariff_connection_id;

/* Люди со списком имевшихся у них тарифов и распакованным json */
CREATE OR REPLACE VIEW public.person AS
SELECT 	numb,
		address,
		info->>'surname' AS surname,
		info->>'name' AS name,
		info->>'patronymic' AS patronymic,
		info->>'birth_date' AS birth_date,
		(info->>'benefit')::boolean AS benefit,
		array_agg (name) AS tariffs
FROM 	 subscriber
	JOIN tariff_connection USING (numb)
	JOIN tariff USING (tariff_id)
GROUP BY numb;

/* Люди с распакованным json */
CREATE OR REPLACE VIEW public.subscriber_unpacked AS
SELECT 	numb,
		address,
		info->>'surname' AS surname,
		info->>'name' AS name,
		info->>'patronymic' AS patronymic,
		info->>'birth_date' AS birth_date,
		(info->>'benefit')::boolean AS benefit
FROM subscriber;