# Домашнее задание 4

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 17

### Задание
Представления могут быть, условно говоря, вертикальными и горизонтальными.
При создании вертикального представления в список его столбцов включается
лишь часть столбцов базовой таблицы (таблиц). Например:
```sql
CREATE VIEW airports_names AS
    SELECT airport_code, airport_name, city
    FROM airports;

SELECT * FROM airports_names;
```
В горизонтальное представление включаются не все строки базовой таблицы
(таблиц), а производится их отбор с помощью фраз `WHERE` или `HAVING`.
Например:
```sql
CREATE VIEW siberian_airports AS
    SELECT * FROM airports
    WHERE city = 'Новосибирск' OR city = 'Кемерово';

SELECT * FROM siberian_airports;
```
Конечно, вполне возможен и смешанный вариант, когда ограничивается как
список столбцов, так и множество строк при создании представления.
Подумайте, какие представления было бы целесообразно создать для нашей
базы данных «Авиаперевозки». Необходимо учесть наличие различных групп
пользователей, например: пилоты, диспетчеры, пассажиры, кассиры.
Создайте представления и проверьте их в работе.

### Решение

- Сделаем горизонтальное представление для пассажиров - Будущие рейсы

```sql
CREATE VIEW passenger_upcoming_flights AS
SELECT 
    f.flight_no,
    f.scheduled_departure,
    dep.city AS departure_city,
    arr.city AS arrival_city,
    f.status,
    f.aircraft_code
FROM bookings.flights f
    JOIN bookings.airports dep ON f.departure_airport = dep.airport_code
    JOIN bookings.airports arr ON f.arrival_airport = arr.airport_code
WHERE f.scheduled_departure > bookings.now()
    AND f.status IN ('Scheduled', 'On Time');
```

<img src="./assets/ex_17/2025-11-03 113222.jpg" width="1000" >

- Сделаем вертикальное представление для пилотов - Характеристики самолетов

```sql
CREATE VIEW pilot_aircraft_info AS
SELECT 
    a.aircraft_code,
    a.model,
    a.range,
    COUNT(s.seat_no) AS total_seats,
    COUNT(CASE WHEN s.fare_conditions = 'Business' THEN 1 END) AS business_seats
FROM bookings.aircrafts a
    LEFT JOIN bookings.seats s ON a.aircraft_code = s.aircraft_code
GROUP BY a.aircraft_code, a.model, a.range;
```

<img src="./assets/ex_17/2025-11-03 113721.jpg" width="1000" >

- Для диспетчеров, смешанное представление - текущие рейсы

```sql
CREATE VIEW dispatcher_current_flights AS
SELECT 
    f.flight_no,
    f.status,
    f.scheduled_departure,
    f.actual_departure,
    dep.city AS departure_city,
    arr.city AS arrival_city,
    a.model AS aircraft
FROM bookings.flights f
    JOIN bookings.airports dep ON f.departure_airport = dep.airport_code
    JOIN bookings.airports arr ON f.arrival_airport = arr.airport_code
    JOIN bookings.aircrafts a ON f.aircraft_code = a.aircraft_code
WHERE f.scheduled_departure::date = bookings.now()::date
    OR f.scheduled_arrival::date = bookings.now()::date
ORDER BY f.scheduled_departure;
```
<img src="./assets/ex_17/2025-11-03 114237.jpg" width="1000" >