DROP FUNCTION IF EXISTS check_tariff_connection_time_func, check_cell_tower_func, set_price_func CASCADE;


/* Триггер проверяет согласованность времени начала звонка и времени
   начала/конца действия указанных tariff_connection у звонящего и принимающего */
CREATE OR REPLACE FUNCTION check_tariff_connection_time_func()
	RETURNS trigger
	AS $$
	DECLARE
		caller_tcid_conn timestamp with time zone :=
			(SELECT date_of_connection
			 FROM tariff_connection
			 WHERE tariff_connection_id = NEW.caller_tariff_connection_id);
		receiver_tcid_conn timestamp with time zone :=
			(SELECT date_of_connection
			 FROM tariff_connection
			 WHERE tariff_connection_id = NEW.receiver_tariff_connection_id);
		caller_tcid_disc timestamp with time zone :=
			(SELECT date_of_disconnection
			 FROM tariff_connection
			 WHERE tariff_connection_id = NEW.caller_tariff_connection_id);
		receiver_tcid_disc timestamp with time zone :=
			(SELECT date_of_disconnection
			 FROM tariff_connection
			 WHERE tariff_connection_id = NEW.receiver_tariff_connection_id);
	BEGIN
		IF NEW.beginning < caller_tcid_conn THEN
			RAISE EXCEPTION 'Calling from tcid = % can''t begin at %, because that tariff_connection connected on %',
				NEW.caller_tariff_connection_id, NEW.beginning, caller_tcid_conn;
		END IF;
		IF NEW.beginning < receiver_tcid_conn THEN
			RAISE EXCEPTION 'Calling to tcid = % can''t begin at %, because that tariff_connection connected on %',
				NEW.receiver_tariff_connection_id, NEW.beginning, receiver_tcid_conn;
		END IF;
		IF caller_tcid_disc IS NOT NULL THEN
			IF NEW.beginning >= caller_tcid_disc THEN
				RAISE EXCEPTION 'Calling from tcid = % can''t begin at %, because that tariff_connection disconnected on %',
					NEW.caller_tariff_connection_id, NEW.beginning, caller_tcid_disc;
			END IF;
		END IF;
		IF receiver_tcid_disc IS NOT NULL THEN
			IF NEW.beginning >= receiver_tcid_disc THEN
				RAISE EXCEPTION 'Calling to tcid = % can''t begin at %, because that tariff_connection disconnected on %',
					NEW.receiver_tariff_connection_id, NEW.beginning, receiver_tcid_disc;
			END IF;
		END IF;
		RETURN NULL;
	END;
	$$ LANGUAGE plpgsql;
   
CREATE CONSTRAINT TRIGGER check_tariff_connection_time
	AFTER INSERT OR UPDATE ON calling
	DEFERRABLE INITIALLY IMMEDIATE
	FOR EACH ROW
	EXECUTE FUNCTION check_tariff_connection_time_func();


/* Триггер проверяет, все ли сотовые вышки, указанные в очередной записи в calling, существуют */
CREATE OR REPLACE FUNCTION check_cell_tower_func()
	RETURNS trigger
	AS $$
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
	$$ LANGUAGE plpgsql;
   
CREATE CONSTRAINT TRIGGER check_cell_tower
	AFTER INSERT OR UPDATE OF caller_cell_tower, receiver_cell_tower ON calling
	DEFERRABLE INITIALLY IMMEDIATE
	FOR EACH ROW
	EXECUTE FUNCTION check_cell_tower_func();


/* Триггер устанавливает стоимость звонка */
CREATE OR REPLACE FUNCTION set_price_func()
	RETURNS trigger
	AS $$
	DECLARE
		caller_tariff integer :=
			(SELECT tariff_id
			 FROM tariff_connection
			 WHERE tariff_connection_id = NEW.caller_tariff_connection_id);
		caller_tariff_type tariff_type :=
			(SELECT type
			 FROM tariff
			 WHERE caller_tariff = tariff_id);
		caller_fee real :=
			(SELECT fee
			 FROM tariff
			 WHERE caller_tariff = tariff_id);
		duration integer :=
			EXTRACT(minutes from (NEW.ending - NEW.beginning));
		caller_benefits boolean :=
			(SELECT info->>'benefits'
			 FROM subscriber JOIN tariff_connection USING (numb)
			 WHERE tariff_connection_id = NEW.caller_tariff_connection_id);
	BEGIN
		IF caller_tariff_type = 'monthly' THEN
			 NEW.price := 0;
			 RETURN NEW;
		END IF;
		NEW.price := duration * caller_fee;
		IF caller_benefits = true THEN
			 NEW.price := NEW.price * 0.8;
		END IF;
		RETURN NEW;
	END;
	$$ LANGUAGE plpgsql;
	
CREATE TRIGGER set_price
	BEFORE INSERT OR UPDATE ON calling
	FOR EACH ROW
	EXECUTE FUNCTION set_price_func();