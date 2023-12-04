DROP TABLE IF EXISTS subscriber, tariff, cell_tower, tariff_connection, calling;
DROP TYPE IF EXISTS tariff_type;

ALTER DATABASE cell_network_analytics SET DateStyle TO 'German', 'DMY';

CREATE TABLE subscriber (
	numb bigint PRIMARY KEY,
	address text,
	info jsonb
);

CREATE TYPE tariff_type AS ENUM ('monthly', 'per_minute'); /* Тип тарифа - ежемесячный платёж или поминутная плата */

CREATE TABLE tariff (
	tariff_id serial PRIMARY KEY,
	name varchar(50),
	fee real NOT NULL,
	type tariff_type NOT NULL
);

CREATE TABLE cell_tower (
	tower_id serial PRIMARY KEY,
	coordinates point /* Долгота и широта */
);

CREATE TABLE tariff_connection (
	tariff_connection_id serial PRIMARY KEY,
	numb bigint REFERENCES subscriber ON DELETE SET NULL ON UPDATE CASCADE,
	tariff_id integer REFERENCES tariff ON DELETE SET NULL ON UPDATE CASCADE,
	date_of_connection date NOT NULL,
	date_of_disconnection date
);

CREATE TABLE calling (
	calling_id bigserial PRIMARY KEY,
	caller_tariff_connection_id integer REFERENCES tariff_connection ON DELETE SET NULL ON UPDATE CASCADE,
	receiver_tariff_connection_id integer REFERENCES tariff_connection ON DELETE SET NULL ON UPDATE CASCADE,
	beginning timestamp with time zone NOT NULL,
	ending timestamp with time zone NOT NULL CHECK (ending >= beginning),
	caller_cell_tower integer[],
	receiver_cell_tower integer[],
	price real
);