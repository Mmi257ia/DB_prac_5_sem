/* 1) Обычный запрос к одной таблице */
EXPLAIN ANALYZE
SELECT calling_id,
	   beginning,
	   ending,
	   caller_cell_tower,
	   receiver_cell_tower,
	   price
FROM calling
WHERE beginning BETWEEN timestamp with time zone '01.12.2021 00:00:00+0300' AND timestamp with time zone '31.12.2021 23:59:59+0300'
	AND (array_length(caller_cell_tower, 1) >= 3 OR array_length(receiver_cell_tower, 1) >= 3);
/* No indexes:
                                                                                                                         QUERY PLAN                                                                                                                         
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..2709284.92 rows=684425 width=80) (actual time=5.232..19414.725 rows=214431 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   ->  Parallel Seq Scan on calling  (cost=0.00..2639842.42 rows=285177 width=80) (actual time=1.791..19379.747 rows=71477 loops=3)
         Filter: ((beginning >= '01.12.2021 00:00:00 MSK'::timestamp with time zone) AND (beginning <= '31.12.2021 23:59:59 MSK'::timestamp with time zone) AND ((array_length(caller_cell_tower, 1) >= 3) OR (array_length(receiver_cell_tower, 1) >= 3)))
         Rows Removed by Filter: 34679676
 Planning Time: 0.691 ms
 Execution Time: 19423.199 ms
*/


CREATE INDEX IF NOT EXISTS calling_beginning_index ON calling (beginning ASC); /* Создаётся около минуты */

/* With index:
                                                                              QUERY PLAN                                                                               
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=27003.22..2676187.71 rows=684419 width=80) (actual time=123.158..1780.729 rows=214431 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   ->  Parallel Bitmap Heap Scan on calling  (cost=26003.22..2606745.81 rows=285175 width=80) (actual time=117.860..1753.334 rows=71477 loops=3)
         Recheck Cond: ((beginning >= '01.12.2021 00:00:00 MSK'::timestamp with time zone) AND (beginning <= '31.12.2021 23:59:59 MSK'::timestamp with time zone))
         Rows Removed by Index Recheck: 15178555
         Filter: ((array_length(caller_cell_tower, 1) >= 3) OR (array_length(receiver_cell_tower, 1) >= 3))
         Rows Removed by Filter: 344093
         Heap Blocks: exact=10443 lossy=233136
         ->  Bitmap Index Scan on calling_beginning_index  (cost=0.00..25832.12 rows=1231955 width=0) (actual time=116.675..116.675 rows=1246709 loops=1)
               Index Cond: ((beginning >= '01.12.2021 00:00:00 MSK'::timestamp with time zone) AND (beginning <= '31.12.2021 23:59:59 MSK'::timestamp with time zone))
 Planning Time: 0.171 ms
 Execution Time: 1787.032 ms
*/

/* 2) Запрос с соединением двух таблиц (и с фильтром по выражению) */

/* Без этой функции при создании индекса postgres просит пометить используемую функцию как IMMUTABLE. */
CREATE OR REPLACE FUNCTION get_bdate(IN jsonb)
RETURNS date
IMMUTABLE
AS $$
BEGIN
RETURN ($1->>'birth_date')::date;
END;
$$ LANGUAGE plpgsql;


EXPLAIN ANALYZE
SELECT q.*
FROM (SELECT info->>'surname' AS surname,
	   		 info->>'name' AS "name",
	   		 info->>'patronymic' AS patronymic,
	   		 get_bdate(info) AS birth_date,
	   		 sum(ending-beginning) AS total_called
	  FROM subscriber
		JOIN tariff_connection USING (numb)
		JOIN calling ON caller_tariff_connection_id = tariff_connection_id
	  WHERE beginning >= timestamp with time zone '01.01.2020 00:00:00+0300'
	  	AND get_bdate(info) < '01.01.1943'::date
	  GROUP BY numb) AS q
WHERE total_called > interval '80 hours';
/* No indexes:
                                                                                      QUERY PLAN                                                              
                        
--------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------
 Subquery Scan on q  (cost=5375435.71..5540764.55 rows=111012 width=116) (actual time=34812.051..35184.737 rows=717 loops=1)
   ->  Finalize GroupAggregate  (cost=5375435.71..5539654.43 rows=111012 width=124) (actual time=34812.049..35184.623 rows=717 loops=1)
         Group Key: subscriber.numb
         Filter: (sum((calling.ending - calling.beginning)) > '80:00:00'::interval)
         Rows Removed by Filter: 45330
         ->  Gather Merge  (cost=5375435.71..5528830.76 rows=666072 width=182) (actual time=34811.944..35173.009 rows=55364 loops=1)
               Workers Planned: 2
               Workers Launched: 2
               ->  Partial GroupAggregate  (cost=5374435.69..5450949.51 rows=333036 width=182) (actual time=34778.550..34976.002 rows=18455 loops=3)
                     Group Key: subscriber.numb
                     ->  Sort  (cost=5374435.69..5392731.55 rows=7318346 width=182) (actual time=34778.533..34868.331 rows=797397 loops=3)
                           Sort Key: subscriber.numb
                           Sort Method: external merge  Disk: 155496kB
                           Worker 0:  Sort Method: external merge  Disk: 149192kB
                           Worker 1:  Sort Method: external merge  Disk: 154584kB
                           ->  Parallel Hash Join  (cost=116900.03..2588942.31 rows=7318346 width=182) (actual time=29990.911..34325.202 rows=797397 loops=3)
                                 Hash Cond: (calling.caller_tariff_connection_id = tariff_connection.tariff_connection_id)
                                 ->  Parallel Seq Scan on calling  (cost=0.00..2096845.75 rows=21955038 width=20) (actual time=0.182..25716.702 rows=17308707 loops=3)
                                       Filter: (beginning >= '01.01.2020 00:00:00 MSK'::timestamp with time zone)
                                       Rows Removed by Filter: 17442445
                                 ->  Parallel Hash  (cost=109210.17..109210.17 rows=208309 width=170) (actual time=1423.504..1423.507 rows=23008 loops=3)
                                       Buckets: 32768  Batches: 32  Memory Usage: 736kB
                                       ->  Parallel Hash Join  (cost=81893.46..109210.17 rows=208309 width=170) (actual time=1381.390..1414.826 rows=23008 loops=3)
                                             Hash Cond: (tariff_connection.numb = subscriber.numb)
                                             ->  Parallel Seq Scan on tariff_connection  (cost=0.00..16319.26 rows=624926 width=12) (actual time=0.204..129.210 rows=499941 loops=3)
                                             ->  Parallel Hash  (cost=76905.90..76905.90 rows=138765 width=166) (actual time=1198.748..1198.749 rows=15349 loops=3)
                                                   Buckets: 32768  Batches: 32  Memory Usage: 576kB
                                                   ->  Parallel Seq Scan on subscriber  (cost=0.00..76905.90 rows=138765 width=166) (actual time=40.742..1190.588 rows=15349 loops=3)
                                                         Filter: (((info ->> 'birth_date'::text))::date < '01.01.1943'::date)
                                                         Rows Removed by Filter: 317984
 Planning Time: 1.356 ms
 Execution Time: 35202.572 ms

*/


CREATE INDEX IF NOT EXISTS subscriber_birth_date_index ON subscriber(get_bdate(info) ASC); /* Создаётся 2 сек */

/* With index:
                                                                                         QUERY PLAN                                                                                         
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Subquery Scan on q  (cost=10991654.89..11289004.20 rows=111111 width=116) (actual time=31105.936..31632.593 rows=717 loops=1)
   ->  GroupAggregate  (cost=10991654.89..11287893.09 rows=111111 width=124) (actual time=31105.935..31632.503 rows=717 loops=1)
         Group Key: subscriber.numb
         Filter: (sum((calling.ending - calling.beginning)) > '80:00:00'::interval)
         Rows Removed by Filter: 45330
         ->  Sort  (cost=10991654.89..11035564.97 rows=17564030 width=182) (actual time=31105.652..31336.142 rows=2392190 loops=1)
               Sort Key: subscriber.numb
               Sort Method: external merge  Disk: 459192kB
               ->  Hash Join  (cost=335608.73..4195563.57 rows=17564030 width=182) (actual time=429.126..30057.710 rows=2392190 loops=1)
                     Hash Cond: (calling.caller_tariff_connection_id = tariff_connection.tariff_connection_id)
                     ->  Seq Scan on calling  (cost=0.00..2857027.20 rows=52692091 width=20) (actual time=0.018..19726.757 rows=51926122 loops=1)
                           Filter: (beginning >= '01.01.2020 00:00:00 MSK'::timestamp with time zone)
                           Rows Removed by Filter: 52327336
                     ->  Hash  (cost=317153.47..317153.47 rows=499941 width=170) (actual time=428.737..428.739 rows=69024 loops=1)
                           Buckets: 32768  Batches: 32  Memory Usage: 702kB
                           ->  Hash Join  (cost=265687.19..317153.47 rows=499941 width=170) (actual time=82.750..413.878 rows=69024 loops=1)
                                 Hash Cond: (tariff_connection.numb = subscriber.numb)
                                 ->  Seq Scan on tariff_connection  (cost=0.00..25068.23 rows=1499823 width=12) (actual time=0.020..113.589 rows=1499823 loops=1)
                                 ->  Hash  (cost=253707.53..253707.53 rows=333333 width=166) (actual time=82.386..82.387 rows=46047 loops=1)
                                       Buckets: 32768  Batches: 32  Memory Usage: 541kB
                                       ->  Bitmap Heap Scan on subscriber  (cost=6243.76..253707.53 rows=333333 width=166) (actual time=13.344..71.196 rows=46047 loops=1)
                                             Recheck Cond: (get_bdate(info) < '01.01.1943'::date)
                                             Heap Blocks: exact=25523
                                             ->  Bitmap Index Scan on subscriber_birth_date_index  (cost=0.00..6160.42 rows=333333 width=0) (actual time=10.521..10.521 rows=46047 loops=1)
                                                   Index Cond: (get_bdate(info) < '01.01.1943'::date)
 Planning Time: 0.802 ms
 Execution Time: 31690.417 ms
*/

/* Отдельно заметим, что тут запрос включает достаточно много побочных действий. Если сравнивать именно те части, которые мы оптимизировали индексом,
а именно - самую нижнюю часть выводимого EXPLAIN дерева, то можно заметить, что прогнозируемая стоимость запроса в обращениях к страницам упала
более чем в 12 раз (76905 -> 6160) а фактическое время исполнения - более чем в 100 раз (1190 -> 10.5) */

/* 3) Запрос с использованием массива */
EXPLAIN ANALYZE
SELECT * FROM calling WHERE ARRAY[500000] <@ caller_cell_tower;

/* No indexes:
                                                           QUERY PLAN                                                            
---------------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..2098367.05 rows=5213 width=88) (actual time=1801.740..22894.796 rows=149 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   ->  Parallel Seq Scan on calling  (cost=0.00..2096845.75 rows=2172 width=88) (actual time=802.150..22885.069 rows=50 loops=3)
         Filter: ('{500000}'::integer[] <@ caller_cell_tower)
         Rows Removed by Filter: 34751103
 Planning Time: 0.093 ms
 Execution Time: 22894.837 ms
*/

CREATE INDEX IF NOT EXISTS calling_caller_cell_tower_gin_index ON calling USING gin (caller_cell_tower); /* Создаётся примерно 11 минут */
CREATE INDEX IF NOT EXISTS calling_receiver_cell_tower_gin_index ON calling USING gin (receiver_cell_tower); /* Не создавал, так как долго, а суть та же */

/* With index:
                                                                    QUERY PLAN                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on calling  (cost=72.40..20053.81 rows=5213 width=88) (actual time=0.027..0.121 rows=149 loops=1)
   Recheck Cond: ('{500000}'::integer[] <@ caller_cell_tower)
   Heap Blocks: exact=149
   ->  Bitmap Index Scan on calling_caller_cell_tower_gin_index  (cost=0.00..71.10 rows=5213 width=0) (actual time=0.016..0.016 rows=149 loops=1)
         Index Cond: ('{500000}'::integer[] <@ caller_cell_tower)
 Planning Time: 0.047 ms
 Execution Time: 0.134 ms
*/
/* Ускорение в 170 000 раз! */

/* 4) Запрос с фильтрацией по JSON */
EXPLAIN ANALYZE
SELECT date_trunc('year', justify_interval(now() - get_bdate(info))) AS age
FROM subscriber
WHERE '{"benefit": true}'::jsonb <@ "info";

/* No indexes:
                                                    QUERY PLAN                                                     
-------------------------------------------------------------------------------------------------------------------
 Seq Scan on subscriber  (cost=0.00..81342.50 rows=1000 width=16) (actual time=0.078..488.605 rows=199969 loops=1)
   Filter: ('{"benefit": true}'::jsonb <@ info)
   Rows Removed by Filter: 800031
 Planning Time: 0.103 ms
 Execution Time: 493.881 ms
*/


CREATE INDEX IF NOT EXISTS subscriber_info_gin_indexo ON subscriber USING gin ("info"); /* Создаётся 9 сек */

/* With index:
                                                                  QUERY PLAN                                                                  
----------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on subscriber  (cost=43.75..3932.29 rows=1000 width=16) (actual time=55.944..331.844 rows=199969 loops=1)
   Recheck Cond: ('{"benefit": true}'::jsonb <@ info)
   Heap Blocks: exact=34323
   ->  Bitmap Index Scan on subscriber_info_gin_indexo  (cost=0.00..43.50 rows=1000 width=0) (actual time=50.982..50.982 rows=199969 loops=1)
         Index Cond: ('{"benefit": true}'::jsonb <@ info)
 Planning Time: 0.139 ms
 Execution Time: 336.747 ms
*/

/* 5) Полнотекстовый поиск */
EXPLAIN ANALYZE
SELECT numb,
	   address,
	   surname,
	   name,
	   patronymic,
	   birth_date,
	   benefit
FROM person WHERE to_tsvector('russian', address) @@ to_tsquery('russian', 'Самарский & Ширяево');

/* No indexes:
                                                                                  QUERY PLAN                                                                                  
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Subquery Scan on person  (cost=196916.43..196921.13 rows=25 width=212) (actual time=2432.557..2457.090 rows=13228 loops=1)
   ->  Finalize GroupAggregate  (cost=196916.43..196920.88 rows=25 width=244) (actual time=2432.555..2455.693 rows=13228 loops=1)
         Group Key: subscriber.numb
         ->  Gather Merge  (cost=196916.43..196920.12 rows=30 width=241) (actual time=2432.547..2444.695 rows=13277 loops=1)
               Workers Planned: 2
               Workers Launched: 2
               ->  Partial GroupAggregate  (cost=195916.41..195916.63 rows=15 width=241) (actual time=2424.793..2426.823 rows=4426 loops=3)
                     Group Key: subscriber.numb
                     ->  Sort  (cost=195916.41..195916.45 rows=15 width=241) (actual time=2424.786..2425.343 rows=6614 loops=3)
                           Sort Key: subscriber.numb
                           Sort Method: quicksort  Memory: 3313kB
                           Worker 0:  Sort Method: quicksort  Memory: 3616kB
                           Worker 1:  Sort Method: quicksort  Memory: 3467kB
                           ->  Hash Join  (cost=177956.35..195916.12 rows=15 width=241) (actual time=2307.967..2421.559 rows=6614 loops=3)
                                 Hash Cond: (tariff_connection.tariff_id = tariff.tariff_id)
                                 ->  Parallel Hash Join  (cost=177955.12..195914.83 rows=15 width=245) (actual time=2307.798..2419.841 rows=6614 loops=3)
                                       Hash Cond: (tariff_connection.numb = subscriber.numb)
                                       ->  Parallel Seq Scan on tariff_connection  (cost=0.00..16319.26 rows=624926 width=12) (actual time=0.037..37.334 rows=499941 loops=3)
                                       ->  Parallel Hash  (cost=177955.00..177955.00 rows=10 width=241) (actual time=2307.305..2307.306 rows=4409 loops=3)
                                             Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 4248kB
                                             ->  Parallel Seq Scan on subscriber  (cost=0.00..177955.00 rows=10 width=241) (actual time=3.626..2224.080 rows=4409 loops=3)
                                                   Filter: (to_tsvector('russian'::regconfig, address) @@ '''самарск'' & ''ширяев'''::tsquery)
                                                   Rows Removed by Filter: 328924
                                 ->  Hash  (cost=1.10..1.10 rows=10 width=4) (actual time=0.055..0.056 rows=10 loops=3)
                                       Buckets: 1024  Batches: 1  Memory Usage: 9kB
                                       ->  Seq Scan on tariff  (cost=0.00..1.10 rows=10 width=4) (actual time=0.023..0.028 rows=10 loops=3)
 Planning Time: 0.737 ms
 Execution Time: 2457.738 ms
*/


CREATE INDEX IF NOT EXISTS subscriber_address_index ON subscriber USING gin (to_tsvector('russian', address)); /* Создаётся 9 сек */

/* With index:
                                                                                      QUERY PLAN                                                                                       
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Subquery Scan on person  (cost=19098.94..19103.64 rows=25 width=212) (actual time=111.723..125.470 rows=13228 loops=1)
   ->  Finalize GroupAggregate  (cost=19098.94..19103.39 rows=25 width=244) (actual time=111.721..124.696 rows=13228 loops=1)
         Group Key: subscriber.numb
         ->  Gather Merge  (cost=19098.94..19102.63 rows=30 width=241) (actual time=111.716..118.978 rows=13276 loops=1)
               Workers Planned: 2
               Workers Launched: 2
               ->  Partial GroupAggregate  (cost=18098.92..18099.15 rows=15 width=241) (actual time=104.681..105.967 rows=4425 loops=3)
                     Group Key: subscriber.numb
                     ->  Sort  (cost=18098.92..18098.96 rows=15 width=241) (actual time=104.677..105.016 rows=6614 loops=3)
                           Sort Key: subscriber.numb
                           Sort Method: quicksort  Memory: 3636kB
                           Worker 0:  Sort Method: quicksort  Memory: 3373kB
                           Worker 1:  Sort Method: quicksort  Memory: 3388kB
                           ->  Hash Join  (cost=138.86..18098.63 rows=15 width=241) (actual time=32.540..102.869 rows=6614 loops=3)
                                 Hash Cond: (tariff_connection.tariff_id = tariff.tariff_id)
                                 ->  Hash Join  (cost=137.64..18097.34 rows=15 width=245) (actual time=32.454..101.924 rows=6614 loops=3)
                                       Hash Cond: (tariff_connection.numb = subscriber.numb)
                                       ->  Parallel Seq Scan on tariff_connection  (cost=0.00..16319.26 rows=624926 width=12) (actual time=0.020..25.816 rows=499941 loops=3)
                                       ->  Hash  (cost=137.32..137.32 rows=25 width=241) (actual time=32.345..32.345 rows=13228 loops=3)
                                             Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 4014kB
                                             ->  Bitmap Heap Scan on subscriber  (cost=32.19..137.32 rows=25 width=241) (actual time=6.526..27.775 rows=13228 loops=3)
                                                   Recheck Cond: (to_tsvector('russian'::regconfig, address) @@ '''самарск'' & ''ширяев'''::tsquery)
                                                   Heap Blocks: exact=11050
                                                   ->  Bitmap Index Scan on subscriber_address_index  (cost=0.00..32.19 rows=25 width=0) (actual time=5.215..5.215 rows=13228 loops=3)
                                                         Index Cond: (to_tsvector('russian'::regconfig, address) @@ '''самарск'' & ''ширяев'''::tsquery)
                                 ->  Hash  (cost=1.10..1.10 rows=10 width=4) (actual time=0.034..0.034 rows=10 loops=3)
                                       Buckets: 1024  Batches: 1  Memory Usage: 9kB
                                       ->  Seq Scan on tariff  (cost=0.00..1.10 rows=10 width=4) (actual time=0.013..0.016 rows=10 loops=3)
 Planning Time: 1.222 ms
 Execution Time: 126.069 ms
*/

/* 6) Секционирование таблицы calling по столбцу beginning */
CREATE TABLE calling_partitioned
(LIKE calling INCLUDING CONSTRAINTS)
PARTITION BY RANGE(beginning);

CREATE INDEX IF NOT EXISTS calling_part_beginning_index ON calling_partitioned(beginning ASC);

CREATE TABLE calling_part_2022_06
PARTITION OF calling_partitioned
FOR VALUES FROM ('01.06.2022 00:00:00+0300') TO ('01.07.2022 00:00:00+0300');
CREATE TABLE calling_part_2022_07
PARTITION OF calling_partitioned
FOR VALUES FROM ('01.07.2022 00:00:00+0300') TO ('01.08.2022 00:00:00+0300');
CREATE TABLE calling_part_2022_08
PARTITION OF calling_partitioned
FOR VALUES FROM ('01.08.2022 00:00:00+0300') TO ('01.09.2022 00:00:00+0300');
CREATE TABLE calling_part_2022_09
PARTITION OF calling_partitioned
FOR VALUES FROM ('01.09.2022 00:00:00+0300') TO ('01.10.2022 00:00:00+0300');
CREATE TABLE calling_part_2022_10
PARTITION OF calling_partitioned
FOR VALUES FROM ('01.10.2022 00:00:00+0300') TO ('01.11.2022 00:00:00+0300');
CREATE TABLE calling_part_2022_11
PARTITION OF calling_partitioned
FOR VALUES FROM ('01.11.2022 00:00:00+0300') TO ('01.12.2022 00:00:00+0300');
CREATE TABLE calling_part_2022_12
PARTITION OF calling_partitioned
FOR VALUES FROM ('01.12.2022 00:00:00+0300') TO ('01.01.2023 00:00:00+0300');

/* Техническая работа... */
INSERT INTO calling_partitioned
SELECT * FROM calling
	WHERE beginning BETWEEN timestamp with time zone '01.06.2022 00:00:00+0300' AND timestamp with time zone '31.12.2022 23:59:59+0300';
DELETE FROM calling WHERE beginning > timestamp with time zone '31.12.2022 23:59:59+0300';
DELETE FROM calling WHERE beginning BETWEEN timestamp with time zone '01.06.2022 00:00:00+0300' AND timestamp with time zone '31.12.2022 23:59:59+0300';

/* Присоединяем calling к разбиению */
ALTER TABLE calling_partitioned
ATTACH PARTITION calling FOR VALUES FROM (MINVALUE) TO ('01.06.2022 00:00:00+0300'); /* Аттачилось минуту */


/* До того, как я всё испортил: */
EXPLAIN ANALYZE
SELECT calling_id,
	   beginning,
	   ending,
	   caller_cell_tower,
	   receiver_cell_tower,
	   price
FROM calling
WHERE beginning BETWEEN timestamp with time zone '12.08.2022 00:00:00+0300' AND timestamp with time zone '09.09.2022 23:59:59+0300';
/*
                                                                         QUERY PLAN                                                                          
-------------------------------------------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..2254309.80 rows=1369969 width=80) (actual time=6.584..25214.087 rows=1266318 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   ->  Parallel Seq Scan on calling  (cost=0.00..2116312.90 rows=570820 width=80) (actual time=2.057..25051.419 rows=422106 loops=3)
         Filter: ((beginning >= '12.08.2022 00:00:00 MSK'::timestamp with time zone) AND (beginning <= '09.09.2022 23:59:59 MSK'::timestamp with time zone))
         Rows Removed by Filter: 29535192
 Planning Time: 0.162 ms
 Execution Time: 25257.877 ms
*/ /* Почему-то seq scan, но да ладно */

/* После: */
EXPLAIN ANALYZE
SELECT calling_id,
	   beginning,
	   ending,
	   caller_cell_tower,
	   receiver_cell_tower,
	   price
FROM calling_partitioned
WHERE beginning BETWEEN timestamp with time zone '12.08.2022 00:00:00+0300' AND timestamp with time zone '09.09.2022 23:59:59+0300';
/*
                                                                              QUERY PLAN                                                                               
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Append  (cost=0.00..82083.98 rows=1261652 width=80) (actual time=0.026..292.462 rows=1266318 loops=1)
   ->  Seq Scan on calling_part_2022_08  (cost=0.00..40133.65 rows=863052 width=80) (actual time=0.025..143.793 rows=869607 loops=1)
         Filter: ((beginning >= '12.08.2022 00:00:00 MSK'::timestamp with time zone) AND (beginning <= '09.09.2022 23:59:59 MSK'::timestamp with time zone))
         Rows Removed by Filter: 472436
   ->  Bitmap Heap Scan on calling_part_2022_09  (cost=9742.08..35642.08 rows=398600 width=80) (actual time=20.894..101.801 rows=396711 loops=1)
         Recheck Cond: ((beginning >= '12.08.2022 00:00:00 MSK'::timestamp with time zone) AND (beginning <= '09.09.2022 23:59:59 MSK'::timestamp with time zone))
         Heap Blocks: exact=19921
         ->  Bitmap Index Scan on calling_part_2022_09_beginning_idx  (cost=0.00..9642.43 rows=398600 width=0) (actual time=18.981..18.981 rows=396711 loops=1)
               Index Cond: ((beginning >= '12.08.2022 00:00:00 MSK'::timestamp with time zone) AND (beginning <= '09.09.2022 23:59:59 MSK'::timestamp with time zone))
 Planning Time: 0.632 ms
 Execution Time: 317.962 ms
*/

CREATE INDEX IF NOT EXISTS calling_caller_tcid_index ON calling(caller_tariff_connection_id ASC);