/* 	Версия через массивы. caller_cell_tower и receiver_cell_tower меняются на массивы integer,
содержащие сотовые вышки в порядке подключения к ним. Наличие соответствующего tower_id в
cell_tower проверяется триггером check_cell_tower. Новая таблица - calling_new.
	Для работы старых приложений используется представление calling, которое берёт из новой
таблицы все неизменившиеся столбцы, на место caller_cell_tower и receiver_cell_tower подставляет
первые элементы соответствующих массивов. Можно использовать INSERT, UPDATE и DELETE с представлением,
для этого реализован триггер calling_changing_to_calling_new, срабатывающий на INSTEAD OF INSERT OR
UPDATE OR DELETE.
	Считаю денормализацию в виде добавления массивов обоснованной, потому что не вижу в ней минусов:
в случае частой фильтрации в запросах по значениям идентификаторов сотовой вышки можно создать
gin-индекс по этим столбцам, тогда фильтрация будет очень быстрой. Избыточности информации нет,
лишних расходов на хранение - тоже. */

/* Переделывание таблицы */
ALTER TABLE calling RENAME COLUMN caller_cell_tower TO caller_cell_tower_old;
ALTER TABLE calling RENAME COLUMN receiver_cell_tower TO receiver_cell_tower_old;
ALTER TABLE calling ADD COLUMN caller_cell_tower integer[];
ALTER TABLE calling ADD COLUMN receiver_cell_tower integer[];

UPDATE calling
SET caller_cell_tower[1] = caller_cell_tower_old,
	receiver_cell_tower[1] = receiver_cell_tower_old;

ALTER TABLE calling DROP COLUMN caller_cell_tower_old;
ALTER TABLE calling DROP COLUMN receiver_cell_tower_old;


ALTER TABLE calling RENAME TO calling_new;
/* Представление, маскирующееся под старую таблицу calling */
CREATE OR REPLACE VIEW calling AS
SELECT  calling_id,
		caller_tariff_connection_id,
		receiver_tariff_connection_id,
		beginning,
		ending,
		caller_cell_tower[1] AS caller_cell_tower,
		receiver_cell_tower[1] AS receiver_cell_tower
FROM calling_new;


/* Триггер проверяет, все ли сотовые вышки, указанные в очередной записи в calling_new, существуют */
CREATE OR REPLACE FUNCTION check_cell_tower_func()
RETURNS trigger
AS $func$
DECLARE
	cell_towers integer[] :=
		(SELECT array_agg(tower_id)
		 FROM cell_tower);
BEGIN
	IF NOT NEW.caller_cell_tower <@ cell_towers THEN
		RAISE EXCEPTION 'Invalid caller cell towers array: %', NEW.caller_cell_tower;
	END IF;
	IF NOT NEW.receiver_cell_tower <@ cell_towers THEN
		RAISE EXCEPTION 'Invalid receiver cell towers array: %', NEW.receiver_cell_tower;
	END IF;
	RETURN NULL;
END;
$func$ LANGUAGE plpgsql;
   
CREATE CONSTRAINT TRIGGER check_cell_tower
	AFTER INSERT OR UPDATE OF caller_cell_tower, receiver_cell_tower ON calling_new
	DEFERRABLE INITIALLY IMMEDIATE
	FOR EACH ROW
	EXECUTE FUNCTION check_cell_tower_func();


/* Триггер позволяет менять calling_new через представление calling */
CREATE OR REPLACE FUNCTION calling_changing_to_calling_new_func()
RETURNS trigger
AS $func$
BEGIN
	CASE TG_OP
	WHEN 'INSERT' THEN
		IF NEW.calling_id IS NULL THEN
			INSERT INTO calling_new VALUES
				(DEFAULT, NEW.caller_tariff_connection_id, NEW.receiver_tariff_connection_id,
				NEW.beginning, NEW.ending, ARRAY[NEW.caller_cell_tower], ARRAY[NEW.receiver_cell_tower]);	
		ELSE
			INSERT INTO calling_new VALUES
				(NEW.calling_id, NEW.caller_tariff_connection_id, NEW.receiver_tariff_connection_id,
				NEW.beginning, NEW.ending, ARRAY[NEW.caller_cell_tower], ARRAY[NEW.receiver_cell_tower]);
		END IF;
	WHEN 'UPDATE' THEN
		IF NEW.calling_id IS NULL THEN
			UPDATE calling_new
			SET calling_id = DEFAULT,
				caller_tariff_connection_id = NEW.caller_tariff_connection_id,
				receiver_tariff_connection_id = NEW.receiver_tariff_connection_id,
				beginning = NEW.beginning,
				ending = NEW.ending,
				caller_cell_tower = ARRAY[NEW.caller_cell_tower],
				receiver_cell_tower = ARRAY[NEW.receiver_cell_tower]
			WHERE calling_id = OLD.calling_id;
		ELSE
			UPDATE calling_new
			SET calling_id = NEW.calling_id,
				caller_tariff_connection_id = NEW.caller_tariff_connection_id,
				receiver_tariff_connection_id = NEW.receiver_tariff_connection_id,
				beginning = NEW.beginning,
				ending = NEW.ending,
				caller_cell_tower = ARRAY[NEW.caller_cell_tower],
				receiver_cell_tower = ARRAY[NEW.receiver_cell_tower]
			WHERE calling_id = OLD.calling_id;
		END IF;
	WHEN 'DELETE' THEN
		DELETE FROM calling_new WHERE calling_new.calling_id = OLD.calling_id;
	END CASE;
	RETURN NULL;
END;
$func$ LANGUAGE plpgsql;
   
CREATE TRIGGER calling_changing_to_calling_new
	INSTEAD OF INSERT OR UPDATE OR DELETE ON calling
	FOR EACH ROW
	EXECUTE FUNCTION calling_changing_to_calling_new_func();

/* 
	pg_column_size говорит, что вся строчка целиком в доптаблицах в нормализованной версии весит 36 байт;
в таблице calling_new - 64 байт;
	вся строчка целиком в calling_new с массивами - 114 + 4 за каждый элемент массива после первого. (106 без элементов, значит)
итого, 36х + 64 = 106 + 4x => x < 2. А две башни есть всегда - одна caller, другая receiver => массивы всегда выгоднее по памяти
(это без учёта заголовочной информации таблиц в нормализованной версии!)
*/

/* Пояснение дорогим детям
Это допзадание от Теймура. Задача: нам понадобилось отслежить сразу несколько сотовых вышек в одном звонке, а программист,
писавший приложение. работающее с БД, уволился. Надо реализовать эти изменения так, чтобы старое приложение не падало. */