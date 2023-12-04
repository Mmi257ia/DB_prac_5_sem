/* Создаём роль */
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM test;
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM test;
DROP ROLE test;

CREATE ROLE test WITH LOGIN;


/* Наделяем её правами */
GRANT SELECT, INSERT, UPDATE
ON TABLE public.cell_tower
TO test;

GRANT USAGE
ON SEQUENCE public.cell_tower_tower_id_seq
TO test;

GRANT SELECT (address, info), UPDATE (address, info)
ON TABLE public.subscriber
TO test;

GRANT SELECT
ON TABLE public.tariff
TO test;

/* после добавления представлений */
GRANT SELECT
ON TABLE public.calling_numbs
TO test;

GRANT SELECT
ON TABLE public.person
TO test;


/* Создаём роль-группу, включаем туда первую роль и наделяем группу правами */
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM test2;
DROP ROLE test2;

CREATE ROLE test2;
GRANT test2 TO test;

GRANT SELECT, UPDATE (address)
ON TABLE public.subscriber_unpacked
TO test2;