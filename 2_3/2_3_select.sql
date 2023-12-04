/* 1) Имена людей, звонивших кому-либо в течение лета 2022 года */
SELECT DISTINCT full_name
FROM calling
	JOIN tariff_connection ON tariff_connection_id = caller_tariff_connection_id
	JOIN subscriber USING (code, numb)
	JOIN person USING (passport)
WHERE beginning >= TIMESTAMP WITH TIME ZONE '01.06.2022 00:00:00+03' AND beginning <= TIMESTAMP WITH TIME ZONE '31.08.2022 23:59:59+03';
	
/* 2) Продолжительность звонков внутри регионов */
SELECT ending - beginning AS duration
FROM calling
	JOIN cell_tower AS caller_ct ON caller_ct.tower_id = caller_cell_tower
	JOIN cell_tower AS receiver_ct ON receiver_ct.tower_id = receiver_cell_tower
WHERE caller_ct.region_id = receiver_ct.region_id;

/* 3) Сколько звонков с некими тарифами принято не в своём регионе */
SELECT name, count(*) AS count
FROM calling
	JOIN tariff_connection ON receiver_tariff_connection_id = tariff_connection_id
	JOIN subscriber USING (code, numb)
	JOIN person USING (passport)
	JOIN cell_tower ON receiver_cell_tower = tower_id
	JOIN tariff USING (tariff_id)
WHERE cell_tower.region_id != person.region_id
GROUP BY name
ORDER BY count DESC NULLS LAST;

/* 4) Сколько абонентов в каком регионе живут */
/* (под абонентом подразумевается телефонный номер, то есть, человек может являться несколькими абонентами сразу) */
SELECT name, count(*) AS count
FROM subscriber
	JOIN person USING (passport)
	JOIN region USING (region_id)
GROUP BY name
ORDER BY count DESC NULLS LAST;
