# Домашнее задание 2

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 14

### Задание

Сопоставление конструкции UNION
с конструкцией CUBE
В подразделе 3.3.3 «Группировка с помощью CUBE» (с. 145) было показано решение задачи с помощью конструкции CUBE. Эту задачу — формирование детального отчета о распределении продаж билетов по направлениям, моделям
самолетов и классам обслуживания — можно решить и с помощью оператора
UNION ALL и восьми подзапросов (по числу комбинаций столбцов, формируемых
при обработке предложения CUBE). Поскольку наборы группируемых столбцов
будут различаться, списки SELECT в подзапросах также будут различаться, поэтому в ряде случаев придется вместо конкретного столбца использовать NULL,
чтобы структура выборок была регулярной.
В этом запросе предложения FROM будут одинаковыми, а предложения GROUP BY
будут различаться (в последнем подзапросе GROUP BY вовсе не будет):

```sql
SELECT
    r.departure_airport AS da,
    r.arrival_airport AS aa,
    a.model, left( tf.fare_conditions, 1 ) AS fc,
    count( * ),
    round( sum( tf.amount ) / 1000000, 2 ) AS t_amount,
    'da,aa,model,fc' AS grouped_ cols
FROM routes r
JOIN flights f ON f.flight_no = r.flight_no
JOIN ticket_flights tf ON tf.flight_id = f.flight_id
JOIN aircrafts a ON a.aircraft_code = r.aircraft_code
GROUP BY da, aa, a.model, tf.fare_conditions

UNION ALL

SELECT
    r.departure_airport AS da,
    r.arrival_airport AS aa,
    a.model,
    NULL AS fc,
    count( * ),
    round( sum( tf.amount ) / 1000000, 2 ) AS t_amount,
    'da,aa,model' AS grouped_ cols
FROM routes r
JOIN flights f ON f.flight_no = r.flight_no
JOIN ticket_flights tf ON tf.flight_id = f.flight_id
JOIN aircrafts a ON a.aircraft_code = r.aircraft_code
GROUP BY da, aa, a.model

UNION ALL
--
-- Здесь нужно добавить еще пять подзапросов
--
UNION ALL

SELECT
    NULL AS da,
    NULL AS aa,
    NULL AS model,
    NULL AS fc,
    count( * ),
    round( sum( tf.amount ) / 1000000, 2 ) AS t_amount,
    NULL AS grouped_cols
FROM routes r
JOIN flights f ON f.flight_no = r.flight_no
JOIN ticket_flights tf ON tf.flight_id = f.flight_id
JOIN aircrafts a ON a.aircraft_code = r.aircraft_code
ORDER BY da, aa, model, fc;
```

Задание 1. Допишите запрос, добавив в него пять подзапросов. Сравните время
выполнения этого запроса с тем, что был рассмотрен в тексте главы.

Задание 2. Посмотрите планы запросов. Попытайтесь найти объяснение большой разнице во времени выполнения в пользу запроса с конструкцией CUBE.
Указание. Планы получаются очень громоздкими из-за того, что в запросах используется представление «Маршруты» (routes). Для их упрощения можно создать временную таблицу на основе этого представления:

```sql
CREATE TEMP TABLE routes_t AS SELECT * FROM routes;
```


<div style="page-break-after: always;"></div>

### Решение

Напишем 5 подзапросов

```sql
EXPLAIN
-- Первый подзапрос: группировка по всем четырем столбцам
SELECT
    r.departure_airport AS da,
    r.arrival_airport AS aa,
    a.model,
    left(tf.fare_conditions, 1) AS fc,
    count(*) AS count,
    round(sum(tf.amount) / 1000000, 2) AS t_amount,
    'da,aa,model,fc' AS grouped_cols
FROM routes r
JOIN flights f ON f.flight_no = r.flight_no
JOIN ticket_flights tf ON tf.flight_id = f.flight_id
JOIN aircrafts a ON a.aircraft_code = r.aircraft_code
GROUP BY da, aa, a.model, tf.fare_conditions

UNION ALL

-- Второй подзапрос: группировка по da, aa, model
SELECT
    r.departure_airport AS da,
    r.arrival_airport AS aa,
    a.model,
    NULL AS fc,
    count(*),
    round(sum(tf.amount) / 1000000, 2) AS t_amount,
    'da,aa,model' AS grouped_cols
FROM routes r
JOIN flights f ON f.flight_no = r.flight_no
JOIN ticket_flights tf ON tf.flight_id = f.flight_id
JOIN aircrafts a ON a.aircraft_code = r.aircraft_code
GROUP BY da, aa, a.model

UNION ALL

-- Третий подзапрос: группировка по da, aa, fc
SELECT
    r.departure_airport AS da,
    r.arrival_airport AS aa,
    NULL AS model,
    left(tf.fare_conditions, 1) AS fc,
    count(*),
    round(sum(tf.amount) / 1000000, 2) AS t_amount,
    'da,aa,fc' AS grouped_cols
FROM routes r
JOIN flights f ON f.flight_no = r.flight_no
JOIN ticket_flights tf ON tf.flight_id = f.flight_id
JOIN aircrafts a ON a.aircraft_code = r.aircraft_code
GROUP BY da, aa, tf.fare_conditions

UNION ALL

-- Четвертый подзапрос: группировка только по da, aa
SELECT
    r.departure_airport AS da,
    r.arrival_airport AS aa,
    NULL AS model,
    NULL AS fc,
    count(*),
    round(sum(tf.amount) / 1000000, 2) AS t_amount,
    'da,aa' AS grouped_cols
FROM routes r
JOIN flights f ON f.flight_no = r.flight_no
JOIN ticket_flights tf ON tf.flight_id = f.flight_id
JOIN aircrafts a ON a.aircraft_code = r.aircraft_code
GROUP BY da, aa

UNION ALL

-- Пятый подзапрос: группировка по model, fc
SELECT
    NULL AS da,
    NULL AS aa,
    a.model,
    left(tf.fare_conditions, 1) AS fc,
    count(*),
    round(sum(tf.amount) / 1000000, 2) AS t_amount,
    'model,fc' AS grouped_cols
FROM routes r
JOIN flights f ON f.flight_no = r.flight_no
JOIN ticket_flights tf ON tf.flight_id = f.flight_id
JOIN aircrafts a ON a.aircraft_code = r.aircraft_code
GROUP BY a.model, tf.fare_conditions

UNION ALL

-- Шестой подзапрос: группировка только по model
SELECT
    NULL AS da,
    NULL AS aa,
    a.model,
    NULL AS fc,
    count(*),
    round(sum(tf.amount) / 1000000, 2) AS t_amount,
    'model' AS grouped_cols
FROM routes r
JOIN flights f ON f.flight_no = r.flight_no
JOIN ticket_flights tf ON tf.flight_id = f.flight_id
JOIN aircrafts a ON a.aircraft_code = r.aircraft_code
GROUP BY a.model

UNION ALL

-- Седьмой подзапрос: группировка только по fc
SELECT
    NULL AS da,
    NULL AS aa,
    NULL AS model,
    left(tf.fare_conditions, 1) AS fc,
    count(*),
    round(sum(tf.amount) / 1000000, 2) AS t_amount,
    'fc' AS grouped_cols
FROM routes r
JOIN flights f ON f.flight_no = r.flight_no
JOIN ticket_flights tf ON tf.flight_id = f.flight_id
JOIN aircrafts a ON a.aircraft_code = r.aircraft_code
GROUP BY tf.fare_conditions

UNION ALL

-- Восьмой подзапрос: общий итог (без группировки)
SELECT
    NULL AS da,
    NULL AS aa,
    NULL AS model,
    NULL AS fc,
    count(*),
    round(sum(tf.amount) / 1000000, 2) AS t_amount,
    NULL AS grouped_cols
FROM routes r
JOIN flights f ON f.flight_no = r.flight_no
JOIN ticket_flights tf ON tf.flight_id = f.flight_id
JOIN aircrafts a ON a.aircraft_code = r.aircraft_code

ORDER BY da, aa, model, fc;
-- END
```

Полный скрипт не умещается на экране, запустим его из файла.

<img src="./assets/2026-01-30 122300.jpg" width="700"> 

<img src="./assets/2026-01-30 122241.jpg" width="700"> 

Сравним планы запросов.

создадим временную таблицу и выведем планы в файл.
```sql
CREATE TEMP TABLE routes_t AS SELECT * FROM routes;
```
Код скрипта из книги

```sql
\o /tmp/cube_explain.txt
EXPLAIN ANALYZE
SELECT
    r.departure_airport AS da,
    r.arrival_airport AS aa,
    a.model,
    left(tf.fare_conditions, 1) AS fc,
    count(*),
    round(sum(tf.amount) / 1000000, 2) AS t_amount,
    GROUPING(r.departure_airport, r.arrival_airport, a.model, tf.fare_conditions)::bit(4) AS mask,
    concat_ws(',',
        CASE WHEN GROUPING(r.departure_airport) = 0 THEN 'da' END,
        CASE WHEN GROUPING(r.arrival_airport) = 0 THEN 'aa' END,
        CASE WHEN GROUPING(a.model) = 0 THEN 'm' END,
        CASE WHEN GROUPING(tf.fare_conditions) = 0 THEN 'fc' END
    ) AS grouped_cols
FROM routes_t r
JOIN flights f ON f.flight_no = r.flight_no
JOIN ticket_flights tf ON tf.flight_id = f.flight_id
JOIN aircrafts a ON a.aircraft_code = r.aircraft_code
GROUP BY CUBE((da, aa), a.model, tf.fare_conditions)
ORDER BY da, aa, a.model, fc;
\o
```

<img src="./assets/2026-01-30 192238.jpg" width="700"> 

Такую же операцию выполним для запроса с подзапросами

```sql
\o /tmp/union_explain.txt
\i /tmp/task_2_14.sql
\o
```
<img src="./assets/2026-01-30 193138.jpg" width="700"> 

Первая строка плана с `UNION ALL`
```text
 Sort  (cost=261646.55..261666.65 rows=8040 width=168)
```

Первая строка плана с `CUBE`
```text
 Sort  (cost=29826.13..29846.23 rows=8040 width=185) (actual time=21198.292..21208.049 rows=2337 loops=1)
```

Разнице во времени выполнения в пользу запроса с конструкцией CUBE потому что:
- Читает данные один раз
- Строит промежуточные агрегаты в памяти
- Вычисляет все комбинации группировок из этих агрегатов

В отличии от запроса с констукцией CUBE запрос с UNION ALL:
- делает 8 независимых запросов
- Каждый: читает все таблицы с нуля
- Каждый: выполняет все JOIN'ы
- Каждый: строит свою хэш-таблицу
- Потом объединяет результаты