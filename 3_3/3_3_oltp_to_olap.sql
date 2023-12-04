DROP EXTENSION IF EXISTS dblink;
CREATE EXTENSION dblink;

DROP FUNCTION IF EXISTS oltp_to_olap;

CREATE FUNCTION oltp_to_olap()
RETURNS void
AS $func$
BEGIN
INSERT INTO public.subscriber
SELECT * FROM dblink('dbname=cell_network', $$
SELECT  (cell_network.public.subscriber.code::bigint*10000000 + cell_network.public.subscriber.numb) AS numb,
			cell_network.public.person.address,
			json_build_object('surname', split_part(cell_network.public.person.full_name, ' ', 1),
							  'name', split_part(cell_network.public.person.full_name, ' ', 2),
							  'patronymic', split_part(cell_network.public.person.full_name, ' ', 3),
							  'passport', cell_network.public.person.passport,
							  'birth_date', cell_network.public.person.date_of_birth::text)::jsonb
FROM cell_network.public.subscriber JOIN cell_network.public.person USING (passport)$$)
AS src(numb bigint, address text, info jsonb);

INSERT INTO public.tariff
SELECT * FROM dblink('dbname=cell_network', $$
SELECT * FROM cell_network.public.tariff$$)
AS src(tariff_id integer, name varchar(50), fee real, type tariff_type)
ON CONFLICT (tariff_id) DO UPDATE SET tariff_id = DEFAULT;

INSERT INTO public.cell_tower
SELECT * FROM dblink('dbname=cell_network', $$
SELECT cell_network.public.cell_tower.tower_id, cell_network.public.cell_tower.coordinates FROM cell_network.public.cell_tower $$)
AS src(tower_id integer, coordinates point)
ON CONFLICT (tower_id) DO UPDATE SET tower_id = DEFAULT;

INSERT INTO public.tariff_connection
SELECT * FROM dblink('dbname=cell_network', $$
SELECT  cell_network.public.tariff_connection.tariff_connection_id,
		(cell_network.public.tariff_connection.code::bigint*10000000 + cell_network.public.tariff_connection.numb) AS numb,
		cell_network.public.tariff_connection.tariff_id,
		cell_network.public.tariff_connection.date_of_connection,
		cell_network.public.tariff_connection.date_of_disconnection
FROM cell_network.public.tariff_connection $$)
AS src(tariff_connection_id integer, numb bigint, tariff_id integer, date_of_connection date, date_of_disconnection date)
ON CONFLICT (tariff_connection_id) DO UPDATE SET tariff_connection_id = DEFAULT;

INSERT INTO public.calling
SELECT * FROM dblink('dbname=cell_network', $$
SELECT  cell_network.public.calling.calling_id,
		cell_network.public.calling.caller_tariff_connection_id,
		cell_network.public.calling.receiver_tariff_connection_id,
		cell_network.public.calling.beginning,
		cell_network.public.calling.ending,
		ARRAY[cell_network.public.calling.caller_cell_tower],
		ARRAY[cell_network.public.calling.receiver_cell_tower]
FROM cell_network.public.calling $$)
AS src(calling_id bigint, caller_tariff_connection_id integer, receiver_tariff_connection_id integer,
	   beginning timestamp with time zone, ending timestamp with time zone,
	   caller_cell_tower integer[], receiver_cell_tower integer[])
ON CONFLICT (calling_id) DO UPDATE SET calling_id = DEFAULT;
END;
$func$ LANGUAGE plpgsql;

select oltp_to_olap();