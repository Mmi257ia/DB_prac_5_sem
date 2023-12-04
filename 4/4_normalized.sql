/* 	Нормализованная версия. caller_cell_tower и receiver_cell_tower меняются на одноимённые
таблицы, реализующие связь многие-ко-многим. Новая таблица для звонков - calling_new.
    Каждая из новых таблиц содержит три поля - calling_id, tower_id и number. В поле number -
номер сотовой вышки по порядку подключения к ним по ходу звонка. Первые два поля ссылаются на
одноимённые поля в таблицах calling_new и cell_tower соответственно. Составные первичные ключи
состоят из всех столбцов этих таблиц.
	Для работы старых приложений используется представление calling, которое берёт из новой
таблицы все неизменившиеся столбцы, на место caller_cell_tower и receiver_cell_tower подставляет
первые из соответствующих сотовых вышек в таблицах caller_cell_tower и receiver_cell_tower.
Можно использовать INSERT, UPDATE и DELETE с представлением, для этого реализован триггер
calling_changing_to_calling_new, срабатывающий на INSTEAD OF INSERT OR UPDATE OR DELETE.
    Считаю это неоправданно сложной реализацией, так как создаётся информация, хранения которой
можно было бы избежать, используя массивы. Зато тут формально всё нормализовано. */


/* Создание новых таблиц */
CREATE TABLE caller_cell_tower (
    calling_id integer REFERENCES calling ON DELETE CASCADE ON UPDATE CASCADE,
    tower_id integer REFERENCES cell_tower ON DELETE SET NULL ON UPDATE CASCADE,
    number integer DEFAULT -1, /* Counting from 1 */
    PRIMARY KEY (calling_id, tower_id, number)
);

CREATE TABLE receiver_cell_tower (
    calling_id integer REFERENCES calling ON DELETE CASCADE ON UPDATE CASCADE,
    tower_id integer REFERENCES cell_tower ON DELETE SET NULL ON UPDATE CASCADE,
    number integer DEFAULT -1, /* Counting from 1 */
    PRIMARY KEY (calling_id, tower_id, number)
);

/* Перенос информации */
INSERT INTO caller_cell_tower
SELECT calling_id, caller_cell_tower, 1 FROM calling;

INSERT INTO receiver_cell_tower
SELECT calling_id, receiver_cell_tower, 1 FROM calling;

ALTER TABLE calling DROP COLUMN caller_cell_tower;
ALTER TABLE calling DROP COLUMN receiver_cell_tower;


ALTER TABLE calling RENAME TO calling_new;
/* Представление, маскирующееся под старую таблицу calling */
CREATE OR REPLACE VIEW calling AS
SELECT  calling_id,
		caller_tariff_connection_id,
		receiver_tariff_connection_id,
		beginning,
		ending,
		caller_cell_tower,
		receiver_cell_tower
FROM calling_new JOIN
    (SELECT c.calling_id, c.tower_id AS caller_cell_tower, r.tower_id AS receiver_cell_tower
     FROM caller_cell_tower AS c
     JOIN receiver_cell_tower AS r USING (calling_id)
     WHERE c.number = 1 AND r.number = 1) AS t USING (calling_id);


/* Автоматическая вставка порядкового номера подключения к сотовой вышке */
CREATE OR REPLACE FUNCTION set_cell_tower_connection_number_func()
RETURNS trigger
AS $func$
BEGIN
    IF TG_ARGV[0] = 'caller' THEN
        NEW.number :=  (SELECT COALESCE(max(number), 0) + 1
                        FROM caller_cell_tower
                        WHERE calling_id = NEW.calling_id);
    ELSEIF TG_ARGV[0] = 'receiver' THEN
        NEW.number :=  (SELECT COALESCE(max(number), 0) + 1
                        FROM receiver_cell_tower
                        WHERE calling_id = NEW.calling_id);
    END IF;
    RETURN NEW;
END;
$func$ LANGUAGE plpgsql;

CREATE TRIGGER set_cell_tower_connection_number_caller
    BEFORE INSERT ON caller_cell_tower
    FOR EACH ROW
    WHEN (NEW.number = -1)
    EXECUTE FUNCTION set_cell_tower_connection_number_func('caller');

CREATE TRIGGER set_cell_tower_connection_number_receiver
    BEFORE INSERT ON receiver_cell_tower
    FOR EACH ROW
    WHEN (NEW.number = -1)
    EXECUTE FUNCTION set_cell_tower_connection_number_func('receiver');


/* Триггер позволяет менять calling_new через представление calling */
CREATE OR REPLACE FUNCTION calling_changing_to_calling_new_func()
RETURNS trigger
AS $func$
DECLARE
    id integer;
BEGIN
	CASE TG_OP
	WHEN 'INSERT' THEN
		IF NEW.calling_id IS NULL THEN
			INSERT INTO calling_new VALUES
				(DEFAULT, NEW.caller_tariff_connection_id, NEW.receiver_tariff_connection_id,
				NEW.beginning, NEW.ending);
            id := lastval();
		ELSE
			INSERT INTO calling_new VALUES
				(NEW.calling_id, NEW.caller_tariff_connection_id, NEW.receiver_tariff_connection_id,
				NEW.beginning, NEW.ending);
            id := NEW.calling_id;
		END IF;
        INSERT INTO caller_cell_tower VALUES (id, NEW.caller_cell_tower, 1);
        INSERT INTO receiver_cell_tower VALUES (id, NEW.receiver_cell_tower, 1);
	WHEN 'UPDATE' THEN
		IF NEW.calling_id IS NULL THEN
			UPDATE calling_new
			SET calling_id = DEFAULT,
				caller_tariff_connection_id = NEW.caller_tariff_connection_id,
				receiver_tariff_connection_id = NEW.receiver_tariff_connection_id,
				beginning = NEW.beginning,
				ending = NEW.ending
			WHERE calling_id = OLD.calling_id;
            id := lastval();
		ELSE
			UPDATE calling_new
			SET calling_id = NEW.calling_id,
				caller_tariff_connection_id = NEW.caller_tariff_connection_id,
				receiver_tariff_connection_id = NEW.receiver_tariff_connection_id,
				beginning = NEW.beginning,
				ending = NEW.ending
			WHERE calling_id = OLD.calling_id;
            id := NEW.calling_id;
		END IF;

        UPDATE caller_cell_tower
        SET tower_id = NEW.caller_cell_tower
        WHERE calling_id = id; /* ON UPDATE CASCADE makes calling_id changing */

        UPDATE receiver_cell_tower
        SET tower_id = NEW.receiver_cell_tower
        WHERE calling_id = id; /* ON UPDATE CASCADE makes calling_id changing */

	WHEN 'DELETE' THEN /* ON DELETE CASCADE in caller_ and receiver_cell_tower does all the job */
		DELETE FROM calling_new WHERE calling_new.calling_id = OLD.calling_id;
	END CASE;
	RETURN NULL;
END;
$func$ LANGUAGE plpgsql;
   
CREATE TRIGGER calling_changing_to_calling_new
	INSTEAD OF INSERT OR UPDATE OR DELETE ON calling
	FOR EACH ROW
	EXECUTE FUNCTION calling_changing_to_calling_new_func();