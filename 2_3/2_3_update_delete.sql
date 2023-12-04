/* 1) Повысить цены на все поминутные тарифы, которые дешевле, чем 1.1 руб/мин, на 20% */

UPDATE tariff
SET fee = fee * 1.2
WHERE type = 'per_minute' AND fee < 1.1;

/*SELECT * FROM tariff;*/

/* 2) Поменять код региона 495 на 095 */
/* В реальность такая смена (но наоборот) имела место в 2006 году */
/* Вызывает срабатывание ограничений целостности */

UPDATE phone_code
SET code = 095
WHERE code = 495;

/*SELECT * FROM tariff_connection;*/

/* 3) Удалить жителей Москвы из базы */
/* Вызывает срабатывание ограничений целостности */

DELETE FROM person
WHERE region_id = (SELECT region_id FROM region WHERE name = 'Москва');

/*SELECT * FROM subscriber;*/

/* 4) Удалить все тарифы с ежемесячной оплатой */
/* Вызывает срабатывание ограничений целостности */

DELETE FROM tariff
WHERE type = 'monthly';

/*SELECT * FROM tariff_connection;*/
