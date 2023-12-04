DROP TABLE IF EXISTS region, tariff, phone_code, cell_tower, person, subscriber, tariff_connection, calling;
DROP TYPE IF EXISTS tariff_type;

CREATE TABLE region (
	region_id serial PRIMARY KEY,
	name varchar(60) NOT NULL
);

CREATE TYPE tariff_type AS ENUM ('monthly', 'per_minute'); /*Тип тарифа - ежемесячный платёж или поминутная плата*/

CREATE TABLE tariff (
	tariff_id serial PRIMARY KEY,
	name varchar(50), 
	fee real CONSTRAINT fee_not_neg NOT NULL CHECK (fee > 0),
	type tariff_type NOT NULL
);

CREATE TABLE phone_code (
	code integer PRIMARY KEY,
	region_id integer REFERENCES region ON DELETE SET NULL ON UPDATE CASCADE /*NULL if the code isn't local*/
);

CREATE TABLE cell_tower (
	tower_id serial PRIMARY KEY,
	coordinates point, /*latitude, longtitude*/
	region_id integer REFERENCES region ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE person (
	passport bigint PRIMARY KEY,
	full_name varchar(100),
	date_of_birth date,
	address text,
	region_id integer REFERENCES region ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE subscriber (
	code integer REFERENCES phone_code ON DELETE SET NULL ON UPDATE CASCADE,
	numb integer NOT NULL,
	passport bigint REFERENCES person ON DELETE SET NULL ON UPDATE CASCADE,
	date_of_connection date,
	phone_imei bigint,
	PRIMARY KEY (code, numb)
);

CREATE TABLE tariff_connection (
	tariff_connection_id serial PRIMARY KEY,
	code integer,
	numb integer,
	tariff_id integer REFERENCES tariff ON DELETE SET NULL ON UPDATE CASCADE,
	date_of_connection date NOT NULL,
	date_of_disconnection date,
	FOREIGN KEY (code, numb) REFERENCES subscriber (code, numb) ON DELETE SET NULL ON UPDATE CASCADE
);

ALTER DATABASE cell_network SET DateStyle TO 'German', 'DMY';

CREATE TABLE calling (
	calling_id serial PRIMARY KEY,
	caller_tariff_connection_id integer REFERENCES tariff_connection ON DELETE SET NULL ON UPDATE CASCADE,
	receiver_tariff_connection_id integer REFERENCES tariff_connection ON DELETE SET NULL ON UPDATE CASCADE,
	beginning timestamp with time zone NOT NULL,
	ending timestamp with time zone,
	caller_cell_tower integer REFERENCES cell_tower ON DELETE SET NULL ON UPDATE CASCADE,
	receiver_cell_tower integer REFERENCES cell_tower ON DELETE SET NULL ON UPDATE CASCADE
);

INSERT INTO region (region_id, name) VALUES
	(DEFAULT, 'Самарская область'),
	(DEFAULT, 'Краснодарский край'),
	(DEFAULT, 'Москва'),
	(DEFAULT, 'Московская область'),
	(DEFAULT, 'Саратовская область'),
	(DEFAULT, 'Оренбургская область'),
	(DEFAULT, 'Республика Татарстан'),
	(DEFAULT, 'Ульяновская область'),
	(DEFAULT, 'Удмуртская Республика'),
	(DEFAULT, 'Пензенская область'),
	(DEFAULT, 'Рязанская область'),
	(DEFAULT, 'Республика Башкортостан'),
	(DEFAULT, 'Республика Мордовия'),
	(DEFAULT, 'Санкт-Петербург'),
	(DEFAULT, 'Ленинградская область');

INSERT INTO phone_code (code, region_id) VALUES
	(846, (SELECT region_id FROM region WHERE name = 'Самарская область')),
	(848, (SELECT region_id FROM region WHERE name = 'Самарская область')),
	(861, (SELECT region_id FROM region WHERE name = 'Краснодарский край')),
	(862, (SELECT region_id FROM region WHERE name = 'Краснодарский край')),
	(495, (SELECT region_id FROM region WHERE name = 'Москва')),
	(499, (SELECT region_id FROM region WHERE name = 'Москва')),
	(496, (SELECT region_id FROM region WHERE name = 'Московская область')),
	(498, (SELECT region_id FROM region WHERE name = 'Московская область')),
	(845, (SELECT region_id FROM region WHERE name = 'Саратовская область')),
	(353, (SELECT region_id FROM region WHERE name = 'Оренбургская область')),
	(843, (SELECT region_id FROM region WHERE name = 'Республика Татарстан')),
	(855, (SELECT region_id FROM region WHERE name = 'Республика Татарстан')),
	(842, (SELECT region_id FROM region WHERE name = 'Ульяновская область')),
	(341, (SELECT region_id FROM region WHERE name = 'Удмуртская Республика')),
	(841, (SELECT region_id FROM region WHERE name = 'Пензенская область')),
	(491, (SELECT region_id FROM region WHERE name = 'Рязанская область')),
	(347, (SELECT region_id FROM region WHERE name = 'Республика Башкортостан')),
	(834, (SELECT region_id FROM region WHERE name = 'Республика Мордовия')),
	(812, (SELECT region_id FROM region WHERE name = 'Санкт-Петербург')),
	(813, (SELECT region_id FROM region WHERE name = 'Ленинградская область')),
	(925, NULL),
	(926, NULL),
	(927, NULL),
	(928, NULL),
	(935, NULL),
	(936, NULL),
	(937, NULL),
	(938, NULL);
	
INSERT INTO cell_tower (tower_id, coordinates, region_id) VALUES
	(DEFAULT, point(53.1855788, 50.0876248), (SELECT region_id FROM region WHERE name = 'Самарская область')),
	(DEFAULT, point(53.2590393, 50.2127928), (SELECT region_id FROM region WHERE name = 'Самарская область')),
	(DEFAULT, point(53.3801638, 49.6334141), (SELECT region_id FROM region WHERE name = 'Самарская область')),
	(DEFAULT, point(45.0461603, 38.9782134), (SELECT region_id FROM region WHERE name = 'Краснодарский край')),
	(DEFAULT, point(43.4045038, 39.9565190), (SELECT region_id FROM region WHERE name = 'Краснодарский край')),
	(DEFAULT, point(46.6992020, 38.2734624), (SELECT region_id FROM region WHERE name = 'Краснодарский край')),
	(DEFAULT, point(55.6970437, 37.5140941), (SELECT region_id FROM region WHERE name = 'Москва')),
	(DEFAULT, point(55.7520985, 37.6177293), (SELECT region_id FROM region WHERE name = 'Москва')),
	(DEFAULT, point(55.6496835, 37.3908627), (SELECT region_id FROM region WHERE name = 'Москва')),
	(DEFAULT, point(55.7865477, 38.4441789), (SELECT region_id FROM region WHERE name = 'Московская область')),
	(DEFAULT, point(55.8141535, 38.9510500), (SELECT region_id FROM region WHERE name = 'Московская область')),
	(DEFAULT, point(55.8888283, 37.4017699), (SELECT region_id FROM region WHERE name = 'Московская область')),
	(DEFAULT, point(52.4840608, 48.0429983), (SELECT region_id FROM region WHERE name = 'Саратовская область')),
	(DEFAULT, point(52.0896985, 47.9510307), (SELECT region_id FROM region WHERE name = 'Саратовская область')),
	(DEFAULT, point(51.5286974, 46.0626510), (SELECT region_id FROM region WHERE name = 'Саратовская область')),
	(DEFAULT, point(52.9399165, 52.0279348), (SELECT region_id FROM region WHERE name = 'Оренбургская область')),
	(DEFAULT, point(52.6442482, 52.8048527), (SELECT region_id FROM region WHERE name = 'Оренбургская область')),
	(DEFAULT, point(51.7537619, 55.1069847), (SELECT region_id FROM region WHERE name = 'Оренбургская область')),
	(DEFAULT, point(55.7981571, 49.1040909), (SELECT region_id FROM region WHERE name = 'Республика Татарстан')),
	(DEFAULT, point(55.6940899, 52.2816074), (SELECT region_id FROM region WHERE name = 'Республика Татарстан')),
	(DEFAULT, point(55.0502280, 51.9281673), (SELECT region_id FROM region WHERE name = 'Республика Татарстан')),
	(DEFAULT, point(54.3252713, 48.3804631), (SELECT region_id FROM region WHERE name = 'Ульяновская область')),
	(DEFAULT, point(54.1918717, 49.4877863), (SELECT region_id FROM region WHERE name = 'Ульяновская область')),
	(DEFAULT, point(54.3546681, 48.8447535), (SELECT region_id FROM region WHERE name = 'Ульяновская область')),
	(DEFAULT, point(56.8726204, 53.2194498), (SELECT region_id FROM region WHERE name = 'Удмуртская Республика')),
	(DEFAULT, point(56.9114214, 52.8081894), (SELECT region_id FROM region WHERE name = 'Удмуртская Республика')),
	(DEFAULT, point(56.1723405, 52.4723339), (SELECT region_id FROM region WHERE name = 'Удмуртская Республика')),
	(DEFAULT, point(53.1832273, 45.0187540), (SELECT region_id FROM region WHERE name = 'Пензенская область')),
	(DEFAULT, point(53.1117765, 46.6016087), (SELECT region_id FROM region WHERE name = 'Пензенская область')),
	(DEFAULT, point(53.4397424, 44.6101463), (SELECT region_id FROM region WHERE name = 'Пензенская область')),
	(DEFAULT, point(54.6339120, 39.7133070), (SELECT region_id FROM region WHERE name = 'Рязанская область')),
	(DEFAULT, point(54.9445665, 41.3917100), (SELECT region_id FROM region WHERE name = 'Рязанская область')),
	(DEFAULT, point(53.7241386, 40.9859776), (SELECT region_id FROM region WHERE name = 'Рязанская область')),
	(DEFAULT, point(54.7507836, 55.9611583), (SELECT region_id FROM region WHERE name = 'Республика Башкортостан')),
	(DEFAULT, point(54.2546457, 58.1070113), (SELECT region_id FROM region WHERE name = 'Республика Башкортостан')),
	(DEFAULT, point(53.0950355, 57.4280369), (SELECT region_id FROM region WHERE name = 'Республика Башкортостан')),
	(DEFAULT, point(54.1893733, 45.1827443), (SELECT region_id FROM region WHERE name = 'Республика Мордовия')),
	(DEFAULT, point(54.7111355, 43.4252429), (SELECT region_id FROM region WHERE name = 'Республика Мордовия')),
	(DEFAULT, point(54.1148454, 42.9043686), (SELECT region_id FROM region WHERE name = 'Республика Мордовия')),
	(DEFAULT, point(59.9956438, 30.1484048), (SELECT region_id FROM region WHERE name = 'Санкт-Петербург')),
	(DEFAULT, point(59.9431635, 30.2610576), (SELECT region_id FROM region WHERE name = 'Санкт-Петербург')),
	(DEFAULT, point(59.8433394, 30.4328853), (SELECT region_id FROM region WHERE name = 'Санкт-Петербург')),
	(DEFAULT, point(59.9376497, 31.0374606), (SELECT region_id FROM region WHERE name = 'Ленинградская область')),
	(DEFAULT, point(59.6403702, 33.5106182), (SELECT region_id FROM region WHERE name = 'Ленинградская область')),
	(DEFAULT, point(59.7563086, 30.6030822), (SELECT region_id FROM region WHERE name = 'Ленинградская область'));

INSERT INTO person (passport, full_name, date_of_birth, address, region_id) VALUES
	(4729604234, 'Вольнов Валерий Павлович', '29.02.1996', 'г. Москва, Загородное шоссе, д. 2',
			(SELECT region_id FROM region WHERE name = 'Москва')),
	(0503743450, 'Медведев Иван Дмитриевич', '12.05.2003', 'г. Самара, ул. Ново-Садовая, д. 257',
	 		(SELECT region_id FROM region WHERE name = 'Самарская область')),
	(3405945082, 'Самарский Михаил Алексеевич', '02.03.2004', 'г. Балаково, ул. Братьев Захаровых, д. 133',
	 		(SELECT region_id FROM region WHERE name = 'Саратовская область')),
	(3449534053, 'Смирнов Дмитрий Максимович', '11.12.2003', 'г. Соль-Илецк, ул. Илецкая, д. 76',
	 		(SELECT region_id FROM region WHERE name = 'Оренбургская область')),
	(3495734053, 'Липатов Федор Николаевич', '26.08.1969', 'г. Казань, ул. Аделя Кутуя, д. 8',
	 		(SELECT region_id FROM region WHERE name = 'Республика Татарстан')),
	(4358934502, 'Алмазова Инесса Михайловна', '05.01.2000', 'с. Солнечная Поляна, СНТ Газовик, уч. 13А',
	 		(SELECT region_id FROM region WHERE name = 'Самарская область')),
	(3452304325, 'Ким Ирина Геннадьевна', '14.11.1983', 'г. Кропоткин, ул. Ленина, д. 19',
	 		(SELECT region_id FROM region WHERE name = 'Краснодарский край')),
	(6876419168, 'Швабикер Александр Александрович', '06.01.1994', 'г. Ульяновск, ул. Промышленная, д. 32',
	 		(SELECT region_id FROM region WHERE name = 'Ульяновская область')),
	(2841653183, 'Петров Геннадий Вячеславович', '02.06.1990', 'г. Ижевск, ул. 10 лет Октября, д. 24',
	 		(SELECT region_id FROM region WHERE name = 'Удмуртская Республика')),
	(6413584135, 'Уранова Алина Никитовна', '19.03.2005', 'г. Кузнецк, ул. Сызранская, д. 1',
	 		(SELECT region_id FROM region WHERE name = 'Пензенская область')),
	(1638436846, 'Азарова Елена Сергеевна', '30.09.2004', 'г. Касимов, ул. Илюшкина, д. 9',
	 		(SELECT region_id FROM region WHERE name = 'Рязанская область')),
	(3496435898, 'Фурсенко Борис Павлович', '01.10.1972', 'г. Стерлитамак, ул. Дружбы, д. 48',
	 		(SELECT region_id FROM region WHERE name = 'Республика Башкортостан')),
	(3451484365, 'Сосновская Анна Ярославовна', '04.07.2003', 'г. Саранск, ул. Коммунистическая, д. 35',
	 		(SELECT region_id FROM region WHERE name = 'Республика Мордовия')),
	(3468543458, 'Лапкина Ангелина Олеговна', '20.04.1949', 'г. Шлиссельбург, ул. 1 Мая, д. 16',
	 		(SELECT region_id FROM region WHERE name = 'Ленинградская область')),
	(3434534622, 'Пекарь Сергей Владиславович', '24.11.1999', 'г. Санкт-Петербург, ул. Думская, 28',
	 		(SELECT region_id FROM region WHERE name = 'Санкт-Петербург')),
	(7765738843, 'Калигин Ярослав Игоревич', '28.12.2003', 'г. Электросталь, пр. Ленина, д. 3',
	 		(SELECT region_id FROM region WHERE name = 'Московская область'));

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
	
INSERT INTO subscriber (code, numb, passport, date_of_connection, phone_imei) VALUES
	(846, 9505057, 0503743450, '05.06.2005', 123456789012345),
	(848, 6237838, 4358934502, '08.08.2008', 134454843543958),
	(927, 1276607, 4358934502, '02.02.2010', 434543859494582),
	(937, 3749078, 4358934502, '17.06.2018', 345438459431684),
	(495, 1035533, 4729604234, '01.03.2022', 645778373416653),
	(925, 4353445, 7765738843, '25.12.2019', 128344235684561),
	(845, 1968758, 3405945082, '09.01.2007', 445827235894484),
	(353, 1549788, 3449534053, '23.09.2009', 324235197451323),
	(927, 9873849, 3449534053, '24.09.2009', 231526839542315),
	(843, 4988469, 3495734053, '16.03.2013', 342132634551663),
	(842, 2721993, 6876419168, '05.06.2005', 335623436834439),
	(341, 6987466, 2841653183, '09.02.2014', 466346544636434),
	(841, 8761463, 6413584135, '05.06.2005', 563605546456125),
	(491, 4678676, 1638436846, '01.09.1999', 987345223154823),
	(936, 3467767, 1638436846, '24.02.2008', 465543451026238),
	(347, 4961381, 3496435898, '13.04.2020', 435698351488345),
	(834, 9794163, 0503743450, '11.10.2009', 435534582283459),
	(812, 9785627, 3434534622, '24.11.2018', 234188771337235),
	(813, 2776886, 3468543458, '26.04.2019', 345413482823455),
	(938, 1273879, 3468543458, '30.05.2020', 466482684236948);
	
INSERT INTO tariff_connection (tariff_connection_id, code, numb, tariff_id, date_of_connection, date_of_disconnection) VALUES
	(DEFAULT, 846, 9505057, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц XS'), '05.06.2003', NULL),
	(DEFAULT, 848, 6237838, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц M'), '08.08.2008', '06.07.2009'),
	(DEFAULT, 848, 6237838, (SELECT tariff_id FROM tariff WHERE name = 'Звонки поминутно M'), '06.07.2009', NULL),
	(DEFAULT, 927, 1276607, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц XL'), '02.02.2010', NULL),
	(DEFAULT, 495, 1035533, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц XS'), '01.03.2022', NULL),
	(DEFAULT, 937, 3749078, (SELECT tariff_id FROM tariff WHERE name = 'Звонки поминутно XL'), '17.06.2018', NULL),
	(DEFAULT, 925, 4353445, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц L'), '25.12.2019', NULL),
	(DEFAULT, 845, 1968758, (SELECT tariff_id FROM tariff WHERE name = 'Звонки поминутно XS'), '09.01.2007', NULL),
	(DEFAULT, 353, 1549788, (SELECT tariff_id FROM tariff WHERE name = 'Звонки поминутно S'), '23.09.2009', NULL),
	(DEFAULT, 927, 9873849, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц L'), '24.09.2009', '04.07.2021'),
	(DEFAULT, 927, 9873849, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц M'), '04.07.2021', NULL),
	(DEFAULT, 843, 4988469, (SELECT tariff_id FROM tariff WHERE name = 'Звонки поминутно XL'), '16.03.2013', NULL),
	(DEFAULT, 842, 2721993, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц XS'), '05.06.2005', '20.12.2013'),
	(DEFAULT, 842, 2721993, (SELECT tariff_id FROM tariff WHERE name = 'Звонки поминутно XS'), '20.12.2013', NULL),
	(DEFAULT, 341, 6987466, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц M'), '09.02.2014', NULL),
	(DEFAULT, 841, 8761463, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц XS'), '05.06.2005', NULL),
	(DEFAULT, 491, 4678676, (SELECT tariff_id FROM tariff WHERE name = 'Звонки поминутно M'), '01.09.1999', NULL),
	(DEFAULT, 936, 3467767, (SELECT tariff_id FROM tariff WHERE name = 'Звонки поминутно L'), '24.02.2008', NULL),
	(DEFAULT, 347, 4961381, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц M'), '13.04.2020', '14.04.2020'),
	(DEFAULT, 347, 4961381, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц M'), '14.04.2020', NULL),
	(DEFAULT, 834, 9794163, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц XL'), '11.10.2009', NULL),
	(DEFAULT, 812, 9785627, (SELECT tariff_id FROM tariff WHERE name = 'Звонки поминутно S'), '24.11.2018', NULL),
	(DEFAULT, 813, 2776886, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц XL'), '26.04.2019', NULL),
	(DEFAULT, 938, 1273879, (SELECT tariff_id FROM tariff WHERE name = 'Звонки на месяц M'), '30.05.2020', NULL);
	
INSERT INTO calling (calling_id, caller_tariff_connection_id, receiver_tariff_connection_id,
					 beginning, ending, caller_cell_tower, receiver_cell_tower) VALUES
	(DEFAULT, 1, 4, 	TIMESTAMP WITH TIME ZONE '30.05.2020 23:59:54+03',
	 					TIMESTAMP WITH TIME ZONE '31.05.2020 00:01:55+03', 13, 14),
	(DEFAULT, 6, 10, 	TIMESTAMP WITH TIME ZONE '24.06.2021 07:25:30+03',
	 					TIMESTAMP WITH TIME ZONE '24.06.2021 07:27:45+03', 23, 10),
	(DEFAULT, 3, 7, 	TIMESTAMP WITH TIME ZONE '24.07.2022 14:45:58+03',
	 					TIMESTAMP WITH TIME ZONE '24.07.2022 15:14:34+03', 7, 44),
	(DEFAULT, 17, 8, 	TIMESTAMP WITH TIME ZONE '23.08.2023 18:58:49+03',
	 					TIMESTAMP WITH TIME ZONE '23.08.2023 20:30:46+03', 10, 39),
	(DEFAULT, 14, 10, 	TIMESTAMP WITH TIME ZONE '09.05.2021 20:20:20+03',
	 					TIMESTAMP WITH TIME ZONE '09.05.2021 20:54:17+03', 16, 7),
	(DEFAULT, 15, 1, 	TIMESTAMP WITH TIME ZONE '13.10.2022 23:11:11+03',
	 					TIMESTAMP WITH TIME ZONE '13.10.2022 23:12:00+03', 5, 24),
	(DEFAULT, 20, 6, 	TIMESTAMP WITH TIME ZONE '07.04.2023 03:45:34+03',
	 					TIMESTAMP WITH TIME ZONE '07.04.2023 03:45:50+03', 10, 23),
	(DEFAULT, 21, 7, 	TIMESTAMP WITH TIME ZONE '01.02.2022 08:45:49+03',
	 					TIMESTAMP WITH TIME ZONE '01.02.2022 09:11:12+03', 35, 16),
	(DEFAULT, 7, 8, 	TIMESTAMP WITH TIME ZONE '27.10.2022 08:23:56+03',
	 					TIMESTAMP WITH TIME ZONE '27.10.2022 08:24:58+03', 33, 5),
	(DEFAULT, 8, 12, 	TIMESTAMP WITH TIME ZONE '13.02.2023 19:45:56+03',
	 					TIMESTAMP WITH TIME ZONE '13.02.2023 19:55:27+03', 43, 13),
	(DEFAULT, 12, 18, 	TIMESTAMP WITH TIME ZONE '30.05.2022 16:56:38+03',
	 					TIMESTAMP WITH TIME ZONE '31.05.2022 17:56:38+03', 41, 5),
	(DEFAULT, 13, 17, 	TIMESTAMP WITH TIME ZONE '31.12.2012 23:55:45+03',
	 					TIMESTAMP WITH TIME ZONE '01.01.2013 00:03:59+03', 24, 4),
	(DEFAULT, 10, 13, 	TIMESTAMP WITH TIME ZONE '29.01.2011 16:28:53+03',
	 					TIMESTAMP WITH TIME ZONE '29.01.2011 16:29:34+03', 29, 28),
	(DEFAULT, 6, 20, 	TIMESTAMP WITH TIME ZONE '05.07.2022 14:45:28+03',
	 					TIMESTAMP WITH TIME ZONE '05.07.2022 15:01:36+03', 45, 34),
	(DEFAULT, 9, 21, 	TIMESTAMP WITH TIME ZONE '24.05.2022 17:46:23+03',
	 					TIMESTAMP WITH TIME ZONE '24.05.2022 18:01:12+03', 4, 9),
	(DEFAULT, 3, 23, 	TIMESTAMP WITH TIME ZONE '31.08.2022 23:58:01+03',
	 					TIMESTAMP WITH TIME ZONE '31.08.2022 23:59:10+03', 3, 21),
	(DEFAULT, 9, 14, 	TIMESTAMP WITH TIME ZONE '28.02.2023 15:35:58+03',
	 					TIMESTAMP WITH TIME ZONE '28.02.2023 16:25:40+03', 28, 22),
	(DEFAULT, 17, 15, 	TIMESTAMP WITH TIME ZONE '14.09.2023 20:02:20+03',
	 					TIMESTAMP WITH TIME ZONE '14.09.2023 20:04:34+03', 29, 38),
	(DEFAULT, 21, 6, 	TIMESTAMP WITH TIME ZONE '04.12.2022 19:09:56+03',
	 					TIMESTAMP WITH TIME ZONE '04.12.2022 19:11:05+03', 13, 25),
	(DEFAULT, 22, 7, 	TIMESTAMP WITH TIME ZONE '18.01.2022 18:53:26+003',
	 					TIMESTAMP WITH TIME ZONE '18.01.2022 18:55:37+03', 11, 24),
	(DEFAULT, 5, 3, 	TIMESTAMP WITH TIME ZONE '02.07.2023 09:40:27+03',
	 					TIMESTAMP WITH TIME ZONE '02.07.2023 10:05:36+03', 10, 7),
	(DEFAULT, 4, 9, 	TIMESTAMP WITH TIME ZONE '04.06.2022 08:48:56+03',
	 					TIMESTAMP WITH TIME ZONE '04.06.2022 08:49:23+03', 32, 33),
	(DEFAULT, 3, 17, 	TIMESTAMP WITH TIME ZONE '22.06.2023 17:45:39+03',
	 					TIMESTAMP WITH TIME ZONE '22.06.2023 19:29:29+03', 26, 3),
	(DEFAULT, 6, 22, 	TIMESTAMP WITH TIME ZONE '07.11.2022 13:25:27+03',
	 					TIMESTAMP WITH TIME ZONE '07.11.2022 14:05:34+03', 40, 41),
	(DEFAULT, 19, 14, 	TIMESTAMP WITH TIME ZONE '23.04.2019 22:23:24+03',
	 					TIMESTAMP WITH TIME ZONE '23.04.2019 23:24:25+03', 1, 40),
	(DEFAULT, 5, 9, 	TIMESTAMP WITH TIME ZONE '10.10.2022 11:26:37+03',
	 					TIMESTAMP WITH TIME ZONE '10.10.2022 11:38:24+03', 2, 39),
	(DEFAULT, 4, 3, 	TIMESTAMP WITH TIME ZONE '23.09.2022 16:59:48+03',
	 					TIMESTAMP WITH TIME ZONE '23.09.2022 17:03:45+03', 8, 34),
	(DEFAULT, 19, 7, 	TIMESTAMP WITH TIME ZONE '13.02.2020 18:08:46+03',
	 					TIMESTAMP WITH TIME ZONE '13.02.2020 18:10:48+03', 26, 17),
	(DEFAULT, 10, 6, 	TIMESTAMP WITH TIME ZONE '06.03.2021 20:34:24+03',
	 					TIMESTAMP WITH TIME ZONE '06.03.2021 20:35:37+03', 27, 11),
	(DEFAULT, 11, 5, 	TIMESTAMP WITH TIME ZONE '14.12.2022 22:20:33+03',
	 					TIMESTAMP WITH TIME ZONE '14.12.2022 22:23:44+03', 11, 12) RETURNING *;