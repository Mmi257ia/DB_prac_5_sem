import random
import datetime as dt
import time
import numpy as np

print("BEGIN;")


'''
	cell_tower:
		храним матрицу 1000х1000
		первая координата от 34.67 до 51 (долгота), вторая - от 51 до 60 (широта) (равномерно раскиданы)
'''

print("COPY cell_tower FROM STDIN (FORMAT text, DELIMITER '|');")
cell_towers = np.zeros((1000, 1000), dtype=tuple)
for i in range(1000):
	for j in range(1000):
		cell_towers[i][j] = (34.67 + (51 - 34.67) * i / 999, 51 + (60 - 51) * j / 999)
		print(i * 1000 + j, "|", cell_towers[i][j][0], ", ", cell_towers[i][j][1], sep='')
print("\.")


'''
	tariff:
		напрямую
'''

print("INSERT INTO tariff (tariff_id, name, fee, type) VALUES");
print("(DEFAULT, 'Звонки на месяц XS', 300, 'monthly'),")
print("(DEFAULT, 'Звонки на месяц S', 350, 'monthly'),")
print("(DEFAULT, 'Звонки на месяц M', 450, 'monthly'),")
print("(DEFAULT, 'Звонки на месяц L', 550, 'monthly'),")
print("(DEFAULT, 'Звонки на месяц XL', 700, 'monthly'),")
print("(DEFAULT, 'Звонки поминутно XS', 0.5, 'per_minute'),")
print("(DEFAULT, 'Звонки поминутно S', 0.75, 'per_minute'),")
print("(DEFAULT, 'Звонки поминутно M', 1, 'per_minute'),")
print("(DEFAULT, 'Звонки поминутно L', 1.5, 'per_minute'),")
print("(DEFAULT, 'Звонки поминутно XL', 2, 'per_minute');")

'''
	subscriber:
		1 000 000 штук
		numb - в [0, 9999999999]; первые 7 цифр это номер субскрибера, оставшиеся 3 это (i * 5340593 % 1000);
		address - рандом город, дом, улица из списка, дом [1, 250], квартира [1, 100]
		info:
			name - рандом из списка
			surname - рандом из списка
			patronymic - рандом из списка; 10% не имеют вообще
			passport - рандом [0, 9999999999]
			birth_date - рандом [01.01.1940, 01.01.2005]
			benefit - true у 20%, false у 5%, ничего у остальных - это ХРАНИМ
'''

benefits = np.zeros(10000000000, dtype=bool)

male_names = []
with open("./strings/male_names.txt", 'r') as f:
	for line in f:
		male_names += [line.rstrip('\n')]

female_names = []
with open("./strings/female_names.txt", 'r') as f:
	for line in f:
		female_names += [line.rstrip('\n')]

male_surnames = []
with open("./strings/male_surnames.txt", 'r') as f:
	for line in f:
		male_surnames += [line.rstrip('\n')]

female_surnames = []
with open("./strings/female_surnames.txt", 'r') as f:
	for line in f:
		female_surnames += [line.rstrip('\n')]

male_patronymics = []
with open("./strings/male_patronymics.txt", 'r') as f:
	for line in f:
		male_patronymics += [line.rstrip('\n')]

female_patronymics = []
with open("./strings/female_patronymics.txt", 'r') as f:
	for line in f:
		female_patronymics += [line.rstrip('\n')]


def make_json(numb):
	res = '{"name":"'
	is_female = random.random() < 0.5
	if is_female:
		res += female_names[random.randrange(len(female_names))]
		res += '","surname":"'
		res += female_surnames[random.randrange(len(female_surnames))]
	else:
		res += male_names[random.randrange(len(male_names))]
		res += '","surname":"'
		res += male_surnames[random.randrange(len(male_surnames))]
	res += '","passport":'
	res += str(random.randrange(10000000000))
	res += ',"birth_date":"'
	res += str(random.randrange(28) + 1) + '.' # увы и ах, без 29/30/31
	res += str(random.randrange(12) + 1) + '.'
	res += str(random.randrange(65) + 1940) + '"'
	if random.random() < 0.9:
		res += ', "patronymic":"'
		if is_female:	
			res += female_patronymics[random.randrange(len(female_patronymics))] + '"'
		else:
			res += male_patronymics[random.randrange(len(male_patronymics))] + '"'
	has_benefit = False
	roll = random.random()
	if roll < 0.2:
		res += ', "benefit":true'
		has_benefit = True
	elif roll < 0.25:
		res += ', "benefit":false'
	benefits[numb] = has_benefit
	res += '}'
	return res


cities = []
with open("./strings/cities.txt", 'r') as f:
	for line in f:
		cities += [line.rstrip('\n')]

streets = []
with open("./strings/streets.txt", 'r') as f:
	for line in f:
		streets += [line.rstrip('\n')]


print("COPY subscriber FROM STDIN (FORMAT text, DELIMITER '|');")

for i in range(1000000):
	numb = i * 1000 + (i * 5340593 % 1000)
	addr = cities[random.randrange(len(cities))] + ", " + streets[random.randrange(len(streets))]
	addr += ", д. " + str(random.randrange(250) + 1) + ", кв. " + str(random.randrange(100) + 1)
	json = make_json(numb)
	print(numb, "|", addr, "|", json, sep='')

print("\.")


'''
	tariff_connection:
		тут всё ХРАНИМ
		проходимся по людям (по их numb т. к. все знаем)
			с вер-стью 25% делаем два тариф_конекшна
			с вер-стью 12.5% - три
		date_of_connection - рандом [01.01.2005, 01.01.2017]
			второй - [01.01.2017, 01.01.2022], третий - [01.01.2022, 01.01.2023]
		tariff_id - рандом [1, 10]
'''

tc_counter = 0
tc_numbs = np.empty(2000000, dtype=np.uint64) # Должно хватить
tc_tariffs = np.empty(2000000, dtype=int)
tc_connections = np.empty(2000000, dtype=dt.date)
tc_disconnections = np.empty(2000000, dtype=dt.date) # 01.01.2100 <=> NULL

print("COPY tariff_connection FROM STDIN (FORMAT text, DELIMITER '|');")

for i in range(1000000):
	numb = i * 1000 + (i * 5340593 % 1000)
	tariff = random.randrange(10) + 1
	connection = dt.date(random.randrange(12) + 2005, random.randrange(12) + 1, random.randrange(28) + 1)
	roll = random.random();
	if roll < 0.375: # 2 или 3
		disconnection = dt.date(random.randrange(5) + 2017, random.randrange(12) + 1, random.randrange(28) + 1)
		tc_numbs[tc_counter] = numb # вносим первый
		tc_tariffs[tc_counter] = tariff
		tc_connections[tc_counter] = connection
		tc_disconnections[tc_counter] = disconnection
		print(tc_counter, "|", numb, "|", tariff, "|'", connection.strftime("%d.%m.%Y"), "'|'", disconnection.strftime("%d.%m.%Y"), "'", sep='')
		tc_counter += 1

		old_tariff = tariff # генерируем второй
		while tariff == old_tariff:
			tariff = random.randrange(10) + 1
		connection = disconnection
		if roll < 0.125: # 3
			disconnection = dt.date(random.randrange(1) + 2022, random.randrange(12) + 1, random.randrange(28) + 1)
			tc_numbs[tc_counter] = numb # вносим второй
			tc_tariffs[tc_counter] = tariff
			tc_connections[tc_counter] = connection
			tc_disconnections[tc_counter] = disconnection
			print(tc_counter, "|", numb, "|", tariff, "|'", connection.strftime("%d.%m.%Y"), "'|'", disconnection.strftime("%d.%m.%Y"), "'", sep='')
			tc_counter += 1

			old_tariff = tariff # генерируем третий
			while tariff == old_tariff:
				tariff = random.randrange(10) + 1
			connection = disconnection
			tc_numbs[tc_counter] = numb # вносим третий
			tc_tariffs[tc_counter] = tariff
			tc_connections[tc_counter] = connection
			tc_disconnections[tc_counter] = dt.date(2100, 1, 1)
			print(tc_counter, "|", numb, "|", tariff, "|'", connection.strftime("%d.%m.%Y"), "'|\\N", sep='')
			tc_counter += 1
		else:
			tc_numbs[tc_counter] = numb # вносим второй
			tc_tariffs[tc_counter] = tariff
			tc_connections[tc_counter] = connection
			tc_disconnections[tc_counter] = dt.date(2100, 1, 1)
			print(tc_counter, "|", numb, "|", tariff, "|'", connection.strftime("%d.%m.%Y"), "'|\\N", sep='')
			tc_counter += 1
	else:
		tc_numbs[tc_counter] = numb # вносим первый
		tc_tariffs[tc_counter] = tariff
		tc_connections[tc_counter] = connection
		tc_disconnections[tc_counter] = dt.date(2100, 1, 1)
		print(tc_counter, "|", numb, "|", tariff, "|'", connection.strftime("%d.%m.%Y"), "'|\\N", sep='')
		tc_counter += 1

print("\.")


'''
	calling:
		проходимся по tariff_connection (их мы сохранили)
			на каждый делаем по рандом [60, 80] звонков
			получатель - рандом, пока не найдём того, который подходит по дате
		beginning - рандом по границам тариф_конекшна
		ending - такой чтобы длительность была рандом в пределах 1 часа
		cell_tower - рандомный из матрицы [0, 999]х[0, 999]; вер-сть добавления новой (соседней) - 30%
		price - считаем!
'''

def get_towers_array():
	last_tower = [random.randrange(1000), random.randrange(1000)]
	towers = "{" + str(1000 * last_tower[0] + last_tower[1])
	roll = random.random()
	while roll < 0.3:
		direction = random.randrange(4) # 0 - i++, 1 - j++, 2 - i--, 3 - j--
		if direction == 0:
			if last_tower[0] == 999:
				last_tower[0] -= 1
			else:
				last_tower[0] += 1
		elif direction == 1:
			if last_tower[1] == 999:
				last_tower[1] -= 1
			else:
				last_tower[1] += 1
		elif direction == 2:
			if last_tower[0] == 0:
				last_tower[0] += 1
			else:
				last_tower[0] -= 1
		elif direction == 3:
			if last_tower[1] == 0:
				last_tower[1] += 1
			else:
				last_tower[1] -= 1
		towers += "," + str(1000 * last_tower[0] + last_tower[1])
		roll = random.random()
	towers += "}"
	return towers

c_counter = 0
now = dt.date(2023, 10, 16)

print("COPY calling FROM STDIN (FORMAT text, DELIMITER '|');")

for i in range(tc_counter):
	calls = random.randrange(20) + 60
	for j in range(calls):
		rec = random.randrange(tc_counter)
		while -3 < i - rec < 3 or tc_connections[i] >= tc_disconnections[rec] or tc_connections[rec] >= tc_disconnections[i]:
			rec = random.randrange(tc_counter)
		lower_border = max(tc_connections[i], tc_connections[rec])
		upper_border = min(tc_disconnections[i], tc_disconnections[rec], now)
		beginning_secs = random.randrange(int(time.mktime(upper_border.timetuple()) - time.mktime(lower_border.timetuple()))) + int(time.mktime(lower_border.timetuple()))
		beginning = time.gmtime(beginning_secs)
		duration = random.randrange(3600) + 1
		ending_secs = beginning_secs + duration
		ending = time.gmtime(ending_secs)

		tariff = tc_tariffs[i]
		if tariff <= 5:
			price = 0
		else:
			if tariff == 6:
				fee = 0.5
			elif tariff == 7:
				fee = 0.75
			elif tariff == 8:
				fee = 1
			elif tariff == 9:
				fee = 1.5
			elif tariff == 10:
				fee = 2
			price = duration % 60 * fee
			if benefits[tc_numbs[i]]:
				price *= 0.8

		print(c_counter, "|", i, "|", rec, "|'", time.strftime("%d.%m.%Y %H:%M:%S+0300", beginning), "'|'", time.strftime("%d.%m.%Y %H:%M:%S+0300", ending), "'|", get_towers_array(), "|", get_towers_array(), "|", price, sep='')
		c_counter += 1

print("\.")

print("COMMIT;")

# Чиним serial'ы
print("ALTER SEQUENCE calling_calling_id_seq RESTART WITH ", c_counter, ";", sep='');
print("ALTER SEQUENCE cell_tower_tower_id_seq RESTART WITH 1000000;");
print("ALTER SEQUENCE tariff_connection_tariff_connection_id_seq RESTART WITH ", tc_counter, ";", sep='');
