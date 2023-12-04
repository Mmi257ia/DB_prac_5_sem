INSERT INTO cell_tower (tower_id, coordinates) VALUES
	(DEFAULT, point(53.1855788, 50.0876248)),
	(DEFAULT, point(53.2590393, 50.2127928)),
	(DEFAULT, point(53.3801638, 49.6334141)),
	(DEFAULT, point(45.0461603, 38.9782134)),
	(DEFAULT, point(43.4045038, 39.9565190)),
	(DEFAULT, point(46.6992020, 38.2734624)),
	(DEFAULT, point(55.6970437, 37.5140941)),
	(DEFAULT, point(55.7520985, 37.6177293)),
	(DEFAULT, point(55.6496835, 37.3908627)),
	(DEFAULT, point(55.7865477, 38.4441789)),
	(DEFAULT, point(55.8141535, 38.9510500)),
	(DEFAULT, point(55.8888283, 37.4017699)),
	(DEFAULT, point(52.4840608, 48.0429983)),
	(DEFAULT, point(52.0896985, 47.9510307)),
	(DEFAULT, point(51.5286974, 46.0626510)),
	(DEFAULT, point(52.9399165, 52.0279348)),
	(DEFAULT, point(52.6442482, 52.8048527)),
	(DEFAULT, point(51.7537619, 55.1069847)),
	(DEFAULT, point(55.7981571, 49.1040909)),
	(DEFAULT, point(53.2590393, 50.2127928)),
	(DEFAULT, point(53.3801638, 49.6334141)),
	(DEFAULT, point(45.0461603, 38.9782134)),
	(DEFAULT, point(43.4045038, 39.9565190)),
	(DEFAULT, point(46.6992020, 38.2734624)),
	(DEFAULT, point(55.6970437, 37.5140941)),
	(DEFAULT, point(55.7520985, 37.6177293)),
	(DEFAULT, point(55.6496835, 37.3908627)),
	(DEFAULT, point(55.7865477, 38.4441789)),
	(DEFAULT, point(55.8141535, 38.9510500)),
	(DEFAULT, point(55.8888283, 37.4017699)),
	(DEFAULT, point(52.4840608, 48.0429983)),
	(DEFAULT, point(52.0896985, 47.9510307)),
	(DEFAULT, point(51.5286974, 46.0626510)),
	(DEFAULT, point(52.9399165, 52.0279348)),
	(DEFAULT, point(52.6442482, 52.8048527)),
	(DEFAULT, point(51.7537619, 55.1069847)),
	(DEFAULT, point(55.7981571, 49.1040909)),
	(DEFAULT, point(55.8888283, 37.4017699)),
	(DEFAULT, point(52.4840608, 48.0429983)),
	(DEFAULT, point(52.0896985, 47.9510307)),
	(DEFAULT, point(51.5286974, 46.0626510)),
	(DEFAULT, point(52.9399165, 52.0279348)),
	(DEFAULT, point(52.6442482, 52.8048527)),
	(DEFAULT, point(51.7537619, 55.1069847)),
	(DEFAULT, point(55.7981571, 49.1040909)),
	(DEFAULT, point(55.6940899, 52.2816074));

INSERT INTO tariff (tariff_id, name, fee, type) VALUES
	(DEFAULT, 'Звонки на месяц XS', 300, 'monthly'),
	(DEFAULT, 'Звонки на месяц S', 350, 'monthly'),
	(DEFAULT, 'Звонки на месяц M', 450, 'monthly'),
	(DEFAULT, 'Звонки на месяц L', 550, 'monthly'),
	(DEFAULT, 'Звонки на месяц XL', 700, 'monthly'),
	(DEFAULT, 'Звонки поминутно XS', 0.5, 'per_minute'),
	(DEFAULT, 'Звонки поминутно S', 0.75, 'per_minute'),
	(DEFAULT, 'Звонки поминутно M', 1, 'per_minute'),
	(DEFAULT, 'Звонки поминутно L', 1.5, 'per_minute'),
	(DEFAULT, 'Звонки поминутно XL', 2, 'per_minute');
	
INSERT INTO subscriber VALUES
	(8469505057, 'addr1', '{}'),
	(8486237838, 'addr2', '{"benefits":true}'),
	(9271276607, 'addr3', '{}'),
	(9373749078, 'addr4', '{}'),
	(4951035533, 'addr5', '{"benefits":false}'),
	(9254353445, 'addr6', '{"benefits":false}'),
	(8451968758, 'addr7', '{"benefits":false}'),
	(3531549788, 'addr8', '{}'),
	(9279873849, 'addr9', '{"benefits":true}'),
	(8434988469, 'addr10', '{}'),
	(8422721993, 'addr11', '{}'),
	(3416987466, 'addr12', '{}'),
	(8418761463, 'addr13', '{"benefits":true}'),
	(4914678676, 'addr14', '{}'),
	(9363467767, 'addr15', '{}'),
	(3474961381, 'addr16', '{}'),
	(8349794163, 'addr17', '{"benefits":true}'),
	(8129785627, 'addr18', '{}'),
	(8132776886, 'addr19', '{"benefits":true}'),
	(9381273879, 'addr20', '{}');
	
INSERT INTO tariff_connection (tariff_connection_id, numb, tariff_id, date_of_connection, date_of_disconnection) VALUES
	(DEFAULT, 8469505057, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц XS'), '05.06.2003', NULL),
	(DEFAULT, 8486237838, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц M'), '08.08.2008', '06.07.2009'),
	(DEFAULT, 8486237838, (SELECT tariff_id FROM tariff WHERE name = 'Звонки поминутно M'), '06.07.2009', NULL),
	(DEFAULT, 9271276607, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц XL'), '02.02.2010', NULL),
	(DEFAULT, 4951035533, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц XS'), '01.03.2022', NULL),
	(DEFAULT, 9373749078, (SELECT tariff_id FROM tariff WHERE name = 'Звонки поминутно XL'), '17.06.2018', NULL),
	(DEFAULT, 9254353445, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц L'), '25.12.2019', NULL),
	(DEFAULT, 8451968758, (SELECT tariff_id FROM tariff WHERE name = 'Звонки поминутно XS'), '09.01.2007', NULL),
	(DEFAULT, 3531549788, (SELECT tariff_id FROM tariff WHERE name = 'Звонки поминутно S'), '23.09.2009', NULL),
	(DEFAULT, 9279873849, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц L'), '24.09.2009', '04.07.2021'),
	(DEFAULT, 9279873849, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц M'), '04.07.2021', NULL),
	(DEFAULT, 8434988469, (SELECT tariff_id FROM tariff WHERE name = 'Звонки поминутно XL'), '16.03.2013', NULL),
	(DEFAULT, 8422721993, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц XS'), '05.06.2005', '20.12.2013'),
	(DEFAULT, 8422721993, (SELECT tariff_id FROM tariff WHERE name = 'Звонки поминутно XS'), '20.12.2013', NULL),
	(DEFAULT, 3416987466, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц M'), '09.02.2014', NULL),
	(DEFAULT, 8418761463, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц XS'), '05.06.2005', NULL),
	(DEFAULT, 4914678676, (SELECT tariff_id FROM tariff WHERE name = 'Звонки поминутно M'), '01.09.1999', NULL),
	(DEFAULT, 9363467767, (SELECT tariff_id FROM tariff WHERE name = 'Звонки поминутно L'), '24.02.2008', NULL),
	(DEFAULT, 3474961381, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц M'), '13.04.2020', '14.04.2020'),
	(DEFAULT, 3474961381, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц M'), '14.04.2020', NULL),
	(DEFAULT, 8349794163, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц XL'), '11.10.2009', NULL),
	(DEFAULT, 8129785627, (SELECT tariff_id FROM tariff WHERE name = 'Звонки поминутно S'), '24.11.2018', NULL),
	(DEFAULT, 8132776886, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц XL'), '26.04.2019', NULL),
	(DEFAULT, 9381273879, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц M'), '30.05.2020', NULL);
	
INSERT INTO calling (calling_id, caller_tariff_connection_id, receiver_tariff_connection_id,
					 beginning, ending, caller_cell_tower, receiver_cell_tower, price) VALUES
	(DEFAULT, 1, 4, 	TIMESTAMP WITH TIME ZONE '30.05.2020 23:59:54+03',
	 					TIMESTAMP WITH TIME ZONE '31.05.2020 00:01:55+03', '{13, 11}', '{14}', DEFAULT),
	(DEFAULT, 6, 10, 	TIMESTAMP WITH TIME ZONE '24.06.2021 07:25:30+03',
	 					TIMESTAMP WITH TIME ZONE '24.06.2021 07:27:45+03', '{23, 10}', '{10}', DEFAULT),
	(DEFAULT, 3, 7, 	TIMESTAMP WITH TIME ZONE '24.07.2022 14:45:58+03',
	 					TIMESTAMP WITH TIME ZONE '24.07.2022 15:14:34+03', '{7}', '{44}', DEFAULT),
	(DEFAULT, 17, 8, 	TIMESTAMP WITH TIME ZONE '23.08.2023 18:58:49+03',
	 					TIMESTAMP WITH TIME ZONE '23.08.2023 20:30:46+03', '{10}', '{39}', DEFAULT),
	(DEFAULT, 14, 10, 	TIMESTAMP WITH TIME ZONE '09.05.2021 20:20:20+03',
	 					TIMESTAMP WITH TIME ZONE '09.05.2021 20:54:17+03', '{16}', '{7}', DEFAULT),
	(DEFAULT, 15, 1, 	TIMESTAMP WITH TIME ZONE '13.10.2022 23:11:11+03',
	 					TIMESTAMP WITH TIME ZONE '13.10.2022 23:12:00+03', '{5}', '{24}', DEFAULT),
	(DEFAULT, 20, 6, 	TIMESTAMP WITH TIME ZONE '07.04.2023 03:45:34+03',
	 					TIMESTAMP WITH TIME ZONE '07.04.2023 03:45:50+03', '{10}', '{23}', DEFAULT),
	(DEFAULT, 21, 7, 	TIMESTAMP WITH TIME ZONE '01.02.2022 08:45:49+03',
	 					TIMESTAMP WITH TIME ZONE '01.02.2022 09:11:12+03', '{35}', '{16}', DEFAULT),
	(DEFAULT, 7, 8, 	TIMESTAMP WITH TIME ZONE '27.10.2022 08:23:56+03',
	 					TIMESTAMP WITH TIME ZONE '27.10.2022 08:24:58+03', '{33}', '{5}', DEFAULT),
	(DEFAULT, 8, 12, 	TIMESTAMP WITH TIME ZONE '13.02.2023 19:45:56+03',
	 					TIMESTAMP WITH TIME ZONE '13.02.2023 19:55:27+03', '{43}', '{13}', DEFAULT),
	(DEFAULT, 12, 18, 	TIMESTAMP WITH TIME ZONE '30.05.2022 16:56:38+03',
	 					TIMESTAMP WITH TIME ZONE '31.05.2022 17:56:38+03', '{41}', '{5}', DEFAULT),
	(DEFAULT, 13, 17, 	TIMESTAMP WITH TIME ZONE '31.12.2012 23:55:45+03',
	 					TIMESTAMP WITH TIME ZONE '01.01.2013 00:03:59+03', '{24}', '{4}', DEFAULT),
	(DEFAULT, 10, 13, 	TIMESTAMP WITH TIME ZONE '29.01.2011 16:28:53+03',
	 					TIMESTAMP WITH TIME ZONE '29.01.2011 16:29:34+03', '{29}', '{28}', DEFAULT),
	(DEFAULT, 6, 20, 	TIMESTAMP WITH TIME ZONE '05.07.2022 14:45:28+03',
	 					TIMESTAMP WITH TIME ZONE '05.07.2022 15:01:36+03', '{45}', '{34}', DEFAULT),
	(DEFAULT, 9, 21, 	TIMESTAMP WITH TIME ZONE '24.05.2022 17:46:23+03',
	 					TIMESTAMP WITH TIME ZONE '24.05.2022 18:01:12+03', '{4}', '{9}', DEFAULT),
	(DEFAULT, 3, 23, 	TIMESTAMP WITH TIME ZONE '31.08.2022 23:58:01+03',
	 					TIMESTAMP WITH TIME ZONE '31.08.2022 23:59:10+03', '{3}', '{21}', DEFAULT),
	(DEFAULT, 9, 14, 	TIMESTAMP WITH TIME ZONE '28.02.2023 15:35:58+03',
	 					TIMESTAMP WITH TIME ZONE '28.02.2023 16:25:40+03', '{28}', '{22}', DEFAULT),
	(DEFAULT, 17, 15, 	TIMESTAMP WITH TIME ZONE '14.09.2023 20:02:20+03',
	 					TIMESTAMP WITH TIME ZONE '14.09.2023 20:04:34+03', '{29}', '{38}', DEFAULT),
	(DEFAULT, 21, 6, 	TIMESTAMP WITH TIME ZONE '04.12.2022 19:09:56+03',
	 					TIMESTAMP WITH TIME ZONE '04.12.2022 19:11:05+03', '{13}', '{25}', DEFAULT),
	(DEFAULT, 22, 7, 	TIMESTAMP WITH TIME ZONE '18.01.2022 18:53:26+03',
	 					TIMESTAMP WITH TIME ZONE '18.01.2022 18:55:37+03', '{11}', '{24}', DEFAULT),
	(DEFAULT, 5, 3, 	TIMESTAMP WITH TIME ZONE '02.07.2023 09:40:27+03',
	 					TIMESTAMP WITH TIME ZONE '02.07.2023 10:05:36+03', '{10}', '{7}', DEFAULT),
	(DEFAULT, 4, 9, 	TIMESTAMP WITH TIME ZONE '04.06.2022 08:48:56+03',
	 					TIMESTAMP WITH TIME ZONE '04.06.2022 08:49:23+03', '{32}', '{33}', DEFAULT),
	(DEFAULT, 3, 17, 	TIMESTAMP WITH TIME ZONE '22.06.2023 17:45:39+03',
	 					TIMESTAMP WITH TIME ZONE '22.06.2023 19:29:29+03', '{26}', '{3}', DEFAULT),
	(DEFAULT, 6, 22, 	TIMESTAMP WITH TIME ZONE '07.11.2022 13:25:27+03',
	 					TIMESTAMP WITH TIME ZONE '07.11.2022 14:05:34+03', '{40}', '{41}', DEFAULT),
	(DEFAULT, 19, 14, 	TIMESTAMP WITH TIME ZONE '13.04.2020 22:23:24+03',
	 					TIMESTAMP WITH TIME ZONE '13.04.2020 23:24:25+03', '{1}', '{40}', DEFAULT),
	(DEFAULT, 5, 9, 	TIMESTAMP WITH TIME ZONE '10.10.2022 11:26:37+03',
	 					TIMESTAMP WITH TIME ZONE '10.10.2022 11:38:24+03', '{2}', '{39}', DEFAULT),
	(DEFAULT, 4, 3, 	TIMESTAMP WITH TIME ZONE '23.09.2022 16:59:48+03',
	 					TIMESTAMP WITH TIME ZONE '23.09.2022 17:03:45+03', '{8}', '{34}', DEFAULT),
	(DEFAULT, 19, 7, 	TIMESTAMP WITH TIME ZONE '13.04.2020 18:08:46+03',
	 					TIMESTAMP WITH TIME ZONE '13.04.2020 18:10:48+03', '{26}', '{17}', DEFAULT),
	(DEFAULT, 10, 6, 	TIMESTAMP WITH TIME ZONE '06.03.2021 20:34:24+03',
	 					TIMESTAMP WITH TIME ZONE '06.03.2021 20:35:37+03', '{27}', '{11}', DEFAULT),
	(DEFAULT, 11, 5, 	TIMESTAMP WITH TIME ZONE '14.12.2022 22:20:33+03',
	 					TIMESTAMP WITH TIME ZONE '14.12.2022 22:23:44+03', '{11}', '{12}', DEFAULT) RETURNING *;