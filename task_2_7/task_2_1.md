# Домашнее задание 7

**Выполнил - Третьяков Александр Юрьевич**

### Задание

Расширяемость PostgreSQL

Выполняется на основе презентации «Расширяемость PostgreSQL» и примеров
простейших расширений, прилагаемых к презентации.
Задание. Создайте пользовательский тип данных, аналогичный тому, который был
показан в лекции. Продемонстрируйте использование этого типа данных, написав
соответствующие запросы. В качестве предметной области можно выбрать «Авиаперевозки»
или любую другую. Если необходимой таблицы в базе данных нет, создайте свою таблицу.

<div style="page-break-after: always;"></div>

### Решение

Создаём тип flight_duration.
```sql
CREATE TYPE flight_duration AS (
    hours smallint,
    minutes smallint
);
```


 Создаём копию таблицы `flights` — `flights_tmp`.
```sql
CREATE TABLE flights_tmp AS
SELECT * FROM flights;
```

Добавляем колонку `duration` типа `flight_duration` в таблицу `flights_tmp`

```sql
ALTER TABLE flights_tmp ADD COLUMN duration flight_duration;
```

<img src="./assets/2026-03-19 163233.jpg" width="700"> 

Заполняем колонку `duration` для каждой строки, вычисляя разницу между `scheduled_arrival` и `scheduled_departure`.

```sql
UPDATE flights_tmp
SET duration = (
    EXTRACT(HOUR FROM (scheduled_arrival - scheduled_departure))::smallint,
    EXTRACT(MINUTE FROM (scheduled_arrival - scheduled_departure))::smallint
)::flight_duration;
```

<img src="./assets/2026-03-19 163707.jpg" width="700"> 

Проверяем результат: 
1. выбираем первые 10 строк с сортировкой по длительности полёта.
    ```sql
    SELECT flight_id, flight_no, scheduled_departure, scheduled_arrival, duration
    FROM flights_tmp
    WHERE duration IS NOT NULL
    ORDER BY duration
    LIMIT 10;
    ```

    <img src="./assets/2026-03-19 163846.jpg" width="700">

2. выбираем рейсы, длительность которых больше 5 часов
    ```sql
    SELECT flight_id, flight_no, scheduled_departure, scheduled_arrival, duration
    FROM flights_tmp
    WHERE (duration).hours > 5
    ORDER BY duration
    LIMIT 10;
    ```
    <img src="./assets/2026-03-19 164014.jpg" width="700">

3. Группировка по диапазонам длительности
    ```sql
    SELECT 
        (duration).hours AS hours,
        count(*) AS flight_count
    FROM flights_tmp
    WHERE duration IS NOT NULL
    GROUP BY (duration).hours
    ORDER BY hours;
    ```
    <img src="./assets/2026-03-19 164203.jpg" width="300">

4. Создаём индекс по колонке `duration` для ускорения сортировки и поиска.
    ```sql
    CREATE INDEX flights_tmp_duration_idx ON flights_tmp (duration);
    ```
    Проверяем использование индекса:

    ```sql
    EXPLAIN (COSTS OFF)
    SELECT flight_id, flight_no, duration
    FROM flights_tmp
    WHERE duration > (5, 0)::flight_duration
    ORDER BY duration;
    ```
    <img src="./assets/2026-03-19 164537.jpg" width="700">

    План подтверждает, что индекс используется (Bitmap Index Scan) для поиска по условию duration > (5,0) 