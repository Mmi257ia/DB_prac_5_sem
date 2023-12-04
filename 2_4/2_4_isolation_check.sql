/* Это всё надо делать в PSQL Tool, потому что здесь пишет только то,
   что возвращает последний оператор, а COMMIT ничего не возвращает, очев */
/* READ (un)COMMITTED (совпадают в postgre) (не допускает грязные чтения, допускает неповторяющиеся чтения) */
START TRANSACTION ISOLATION LEVEL READ COMMITTED READ ONLY;

	SELECT beginning FROM calling WHERE calling_id = 1; /* 2020-05-30 23:59:54+03 */
	/* Параллельно исполним в соседнем окне: */
	/* SET AUTOCOMMIT = OFF */
	/* UPDATE calling SET beginning = beginning + '1 year' WHERE calling_id = 1; */
	SELECT beginning FROM calling WHERE calling_id = 1; /* 2020-05-30 23:59:54+03. Грязного чтения нет */
	/* COMMIT; */
	SELECT beginning FROM calling WHERE calling_id = 1; /* 2021-05-30 23:59:54+03. Неповторяющееся чтение есть */

COMMIT;

/* REPEATABLE READ (не допускает ни неповторяющихся чтений, ни фантомных чтений (именно в postgre!)) */
START TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY;

	SELECT beginning FROM calling WHERE calling_id = 1; /* 2020-05-30 23:59:54+03 */
	/* Параллельно исполним в соседнем окне: */
	/* UPDATE calling SET beginning = beginning + '1 year' WHERE calling_id = 1; */
	SELECT beginning FROM calling WHERE calling_id = 1; /* 2020-05-30 23:59:54+03. Неповторяющегося чтения нет */
	/* DELETE FROM calling WHERE calling_id = 1; */
	SELECT beginning FROM calling WHERE calling_id = 1; /* 2020-05-30 23:59:54+03. Фантомного чтения нет */

COMMIT;

/* SERIALIZABLE (не допускает аномалий сериализации) */
/* В одном окне вводим это (до commit) */
START TRANSACTION ISOLATION LEVEL SERIALIZABLE;

	SELECT beginning FROM calling WHERE caller_tariff_connection_id = 1;
	INSERT INTO calling VALUES (DEFAULT, 3, 1, timestamp with time zone '01.01.2015 00:00:00+03',
								timestamp with time zone '01.01.2015 00:01:00+03', 1, 1);

COMMIT;
/* Во втором окне вводим это (до commit) */
START TRANSACTION ISOLATION LEVEL SERIALIZABLE;

	SELECT beginning FROM calling WHERE caller_tariff_connection_id = 3;
	INSERT INTO calling VALUES (DEFAULT, 1, 3, timestamp with time zone '01.01.2015 00:00:00+03',
								timestamp with time zone '01.01.2015 00:01:00+03', 1, 1);

COMMIT;