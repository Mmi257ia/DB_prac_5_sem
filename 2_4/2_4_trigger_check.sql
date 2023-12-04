/* Покажем проверку на insert */

/* tcid = 2: с 08.08.2008 до 06.07.2009; tcid = 10: с 24.09.2009 до 04.07.2021 */
/*INSERT INTO calling VALUES
	(DEFAULT, 2, 10,  	timestamp with time zone '01.01.2007 00:00:00+03', 
						timestamp with time zone '01.01.2007 00:01:00+03', 1, 1);
SELECT * FROM calling WHERE beginning = timestamp with time zone '01.01.2007 00:00:00+03';*/

/*INSERT INTO calling VALUES
	(DEFAULT, 2, 10,  	timestamp with time zone '09.08.2008 00:00:00+03', 
						timestamp with time zone '09.08.2008 00:01:00+03', 1, 1);
SELECT * FROM calling WHERE beginning = timestamp with time zone '09.08.2008 00:00:00+03';*/

/*INSERT INTO calling VALUES
	(DEFAULT, 2, 10,  	timestamp with time zone '09.08.2010 00:00:00+03', 
						timestamp with time zone '09.08.2010 00:01:00+03', 1, 1);
SELECT * FROM calling WHERE beginning = timestamp with time zone '09.08.2010 00:00:00+03'*/

/*INSERT INTO calling VALUES
	(DEFAULT, 10, 2,  	timestamp with time zone '09.08.2010 00:00:00+03', 
						timestamp with time zone '09.08.2010 00:01:00+03', 1, 1);
SELECT * FROM calling WHERE beginning = timestamp with time zone '09.08.2010 00:00:00+03';*/

/* А это - проходит */
/*INSERT INTO calling VALUES
	(DEFAULT, 3, 10,  	timestamp with time zone '09.08.2010 00:00:00+03', 
						timestamp with time zone '09.08.2010 00:01:00+03', 1, 1);
SELECT * FROM calling WHERE beginning = timestamp with time zone '09.08.2010 00:00:00+03'*/


/* То же самое - на update */

/* tcid = 3: с 06.07.2009; tcid = 13: с 05.06.2005 до 20.12.2013 */
/*UPDATE calling SET beginning = timestamp with time zone '01.01.2007 00:00:00+03' WHERE caller_tariff_connection_id = 3;
SELECT * FROM calling WHERE beginning = timestamp with time zone '01.01.2007 00:00:00+03';*/

/*UPDATE calling SET beginning = timestamp with time zone '01.01.2007 00:00:00+03' WHERE receiver_tariff_connection_id = 3;
SELECT * FROM calling WHERE beginning = timestamp with time zone '01.01.2007 00:00:00+03';*/

/*UPDATE calling SET beginning = timestamp with time zone '01.01.2014 00:00:00+03' WHERE caller_tariff_connection_id = 13;
SELECT * FROM calling WHERE beginning = timestamp with time zone '01.01.2014 00:00:00+03';*/

/*UPDATE calling SET beginning = timestamp with time zone '01.01.2014 00:00:00+03' WHERE receiver_tariff_connection_id = 13;
SELECT * FROM calling WHERE beginning = timestamp with time zone '01.01.2014 00:00:00+03';*/

/* А это - проходит */
/*UPDATE calling SET beginning = timestamp with time zone '01.01.2010 00:00:00+03' WHERE caller_tariff_connection_id = 13;
SELECT * FROM calling WHERE beginning = timestamp with time zone '01.01.2010 00:00:00+03';*/


/* Откат транзакции (вводить команды по одной) */
BEGIN;
	/* Триггер сработает в конце транзакции перед COMMIT */
	SET CONSTRAINTS check_tariff_connection_time DEFERRED;
	/* Действие, не вызывающее срабатывание ограничения */
	UPDATE calling SET beginning = timestamp with time zone '01.01.2021 00:00:00+03' WHERE caller_tariff_connection_id = 1;
	/* Действие, вызывающее срабатывание ограничения */
	UPDATE calling SET beginning = timestamp with time zone '01.01.2014 00:00:00+03' WHERE receiver_tariff_connection_id = 13;
	/* Триггер не стриггерило, в таблице пока что некорректные данные */
	SELECT * FROM calling WHERE receiver_tariff_connection_id = 13;
COMMIT;
/* Видим, что у звонков, начатых с tcid = 1, начало - НЕ 01.01.2021 */
SELECT * FROM calling WHERE caller_tariff_connection_id = 1;