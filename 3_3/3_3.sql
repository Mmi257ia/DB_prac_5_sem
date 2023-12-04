DROP FUNCTION IF EXISTS how_long_subscribed, traveled, subs_with_tariff;

/* Выводит по номеру человека общее время, в течение которого он является абонентом */
CREATE FUNCTION how_long_subscribed(bigint)
RETURNS interval
AS $$
DECLARE
    beginning date;
    ending date;
    result interval := 0;
	flag boolean := false;
    tc_cursor CURSOR (number bigint) FOR
        SELECT date_of_connection, date_of_disconnection FROM tariff_connection WHERE tariff_connection.numb = number;
BEGIN
    FOR time_bounds IN tc_cursor($1) LOOP
		flag = true;
        beginning := time_bounds.date_of_connection;
        ending := COALESCE(time_bounds.date_of_disconnection, now());
        result := result + (ending::timestamp with time zone - beginning::timestamp with time zone);
    END LOOP;
	IF NOT flag THEN
        RAISE EXCEPTION 'subcriber with number % does not exist', $1;
    END IF;
    RETURN date_trunc('days', justify_days(result));
EXCEPTION
    WHEN datetime_field_overflow THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;

/* Выводит суммарное расстояние (в км) между последовательными сотовыми вышками, с которых ловили
   сигнал звонящий и принимающий звонок. Можно использовать как очень грубую оценку пройденного
   людьми за время звонка расстояния */
CREATE FUNCTION traveled(bigint, OUT caller_traveled real, OUT receiver_traveled real)
AS $$
DECLARE
    c_tower_ids integer[] := (SELECT caller_cell_tower FROM calling WHERE calling_id = $1);
    r_tower_ids integer[] := (SELECT receiver_cell_tower FROM calling WHERE calling_id = $1);
    c_towers point[];
    r_towers point[];
    t_id integer;
    trav real := 0;
    cos_d numeric;
BEGIN
    IF c_tower_ids IS NULL THEN
        RAISE EXCEPTION 'seems that calling with id % is not recorded in database =(', $1;
    END IF;

    /* собираем вышки */
    FOREACH t_id IN ARRAY c_tower_ids LOOP
        c_towers := array_append(c_towers, (SELECT coordinates FROM cell_tower WHERE tower_id = t_id));
    END LOOP;
    FOREACH t_id IN ARRAY r_tower_ids LOOP
        r_towers := array_append(r_towers, (SELECT coordinates FROM cell_tower WHERE tower_id = t_id));
    END LOOP;

    /* caller */
    FOR i IN 2..cardinality(c_towers) LOOP
        /* cos(d) = sin(φА)·sin(φB) + cos(φА)·cos(φB)·cos(λА − λB) */
        /* угол между вышками - d, φ - широты ([1]), λ - долготы ([0]) */
        cos_d := sin((c_towers[i-1])[1]) * sin((c_towers[i])[1]) +
                 cos((c_towers[i-1])[1]) * cos((c_towers[i])[1]) * cos((c_towers[i-1])[0] - (c_towers[i])[0]);
        /* L = d * R, R = 6371 км (радиус Земли) */
        trav := trav + 6371 * acos(cos_d);
    END LOOP;
    $2 := trav;
	trav := 0;

    /* receiver */
    FOR i IN 2..cardinality(r_towers) LOOP
        /* cos(d) = sin(φА)·sin(φB) + cos(φА)·cos(φB)·cos(λА − λB) */
        /* угол между вышками - d, φ - широты ([1]), λ - долготы ([0]) */
        cos_d := sin((r_towers[i-1])[1]) * sin((r_towers[i])[1]) +
                 cos((r_towers[i-1])[1]) * cos((r_towers[i])[1]) * cos((r_towers[i-1])[0] - (r_towers[i])[0]);
        /* L = d * R, R = 6371 км (радиус Земли) */
        trav := trav + 6371 * acos(cos_d);
    END LOOP;
    $3 := trav;
END;
$$ LANGUAGE plpgsql;

/* Выводит список людей с распакованным json, имеющих сейчас некий тариф */
CREATE FUNCTION subs_with_tariff(IN varchar(50), OUT number bigint, OUT addr text, OUT surname text, OUT name text, OUT patronymic text, OUT birth_date date, OUT benefit boolean)
RETURNS SETOF record/*TABLE(numb bigint, address text, surname text, name text, patronymic text, birth_date date, benefit boolean)*/
AS $$
DECLARE
	t_id integer := (SELECT tariff_id FROM tariff WHERE tariff.name = $1);
	sub_cursor CURSOR (id bigint) FOR
		SELECT  numb,
				address,
				info->>'surname' AS surname,
				info->>'name' AS name,
				info->>'patronymic' AS patronymic,
				info->>'birth_date' AS birth_date,
				(info->>'benefit')::boolean AS benefit,
				date_of_disconnection AS disc
		FROM tariff_connection JOIN subscriber USING (numb) WHERE tariff_id = id;
BEGIN
	IF t_id IS NULL THEN
		RAISE EXCEPTION 'seems that tariff % does not exists', $1;
	END IF;
	FOR subscriber_tuple IN sub_cursor(t_id) LOOP
		IF subscriber_tuple.disc IS NULL THEN
			number := subscriber_tuple.numb;
			addr := subscriber_tuple.address;
			surname := subscriber_tuple.surname;
			name := subscriber_tuple.name;
			patronymic := subscriber_tuple.patronymic;
			birth_date := subscriber_tuple.birth_date;
			benefit := subscriber_tuple.benefit;
			RETURN NEXT;
		END IF;
	END LOOP;
	RETURN;
END;
$$ LANGUAGE plpgsql;


SELECT numb, how_long_subscribed(numb) FROM subscriber LIMIT 10;

SELECT caller_cell_tower, t.caller_traveled, receiver_cell_tower, t.receiver_traveled
FROM calling, traveled(calling_id) AS t LIMIT 10;

SELECT * FROM subs_with_tariff('Звонки поминутно M') LIMIT 10;
/* Пояснение: Теймур из этого всего принял только вторую функцию (ловко подметив, что само её существование говорит о
плохом проектировании базы) и заставил писать функцию из соседнего файла */