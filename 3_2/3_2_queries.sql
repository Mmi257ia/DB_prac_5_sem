SELECT * FROM calling; /* Нельзя */
SELECT * FROM subscriber; /* Нельзя */
SELECT * FROM cell_tower LIMIT 10; /* Можно */
SELECT address, jsonb_pretty(info) FROM subscriber LIMIT 10; /* Можно */
SELECT * FROM calling_numbs WHERE (ending - beginning) > interval '5 minutes' LIMIT 10; /* Можно */
SELECT * FROM subscriber_unpacked WHERE patronymic IS NOT NULL AND benefit LIMIT 10; /* Можно */
SELECT * FROM person WHERE patronymic IS NOT NULL AND benefit LIMIT 10; /* Можно */

INSERT INTO subscriber VALUES
	(9999999999, 'г. Актау, 12-34-55', '{}'); /* Нельзя */
UPDATE subscriber SET numb = 1 WHERE numb = 0; /* Нельзя */
UPDATE subscriber_unpacked SET numb = 1 WHERE numb = 0; /* Нельзя */
INSERT INTO cell_tower VALUES
	(DEFAULT, point(50, 51)); /* Можно */
UPDATE cell_tower SET coordinates = point(51, 52) WHERE coordinates::text = point(50, 51)::text; /* Можно */
UPDATE subscriber SET address = 'г. Москва, ул. Пушкина, дом Колотушкина' WHERE numb = 0; /* Можно */
UPDATE subscriber_unpacked SET address = 'г. Москва, ул. Колотушкина, дом Пушкина' WHERE numb = 0; /* Можно */