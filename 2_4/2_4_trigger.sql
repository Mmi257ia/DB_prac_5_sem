/* Триггер проверяет согласованность времени начала звонка и времени
   начала/конца действия указанных tariff_connection у звонящего и принимающего */

DROP FUNCTION IF EXISTS check_tariff_connection_time_func CASCADE;

CREATE OR REPLACE FUNCTION check_tariff_connection_time_func()
	RETURNS trigger
	AS $$
	DECLARE
		caller_tcid_conn timestamp with time zone :=
			(SELECT date_of_connection
			 FROM tariff_connection
			 WHERE NEW.caller_tariff_connection_id = tariff_connection_id);
		receiver_tcid_conn timestamp with time zone :=
			(SELECT date_of_connection
			 FROM tariff_connection
			 WHERE NEW.receiver_tariff_connection_id = tariff_connection_id);
		caller_tcid_disc timestamp with time zone :=
			(SELECT date_of_disconnection
			 FROM tariff_connection
			 WHERE NEW.caller_tariff_connection_id = tariff_connection_id);
		receiver_tcid_disc timestamp with time zone :=
			(SELECT date_of_disconnection
			 FROM tariff_connection
			 WHERE NEW.receiver_tariff_connection_id = tariff_connection_id);
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