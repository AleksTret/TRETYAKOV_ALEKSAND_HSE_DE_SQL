# Домашнее задание 5

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 2

### Задание

Бывают ситуации, когда специалисту по базам данных приходится
заниматься переработкой и оптимизацией унаследованного кода на языке
PL/pgSQL. И может оказаться, что некоторую функцию, написанную на этом
языке, вполне возможно заменить одним SQL-запросом, причем, довольно
простым. В качестве примера такой ситуации возьмем подсчет числа рейсов,
выполняемых в каждый день недели.

```sql
CREATE OR REPLACE FUNCTION flights_per_days()
 RETURNS TABLE( day_of_week bigint, flights_count integer )
AS
$$
DECLARE
day smallint;
flights_counts integer[ 7 ] = ARRAY[ 0, 0, 0, 0, 0, 0, 0 ];
week_days routes.days_of_week%TYPE;
BEGIN
-- Берем значение поля (массив) "Дни недели, когда
-- выполняются рейсы".
FOR week_days IN SELECT days_of_week FROM routes
LOOP
-- Для каждого номера дня недели, представленного в этом
-- массиве, ...
FOREACH day IN ARRAY week_days
LOOP
-- ... наращиваем счетчик рейсов в массиве счетчиков.
flights_counts[ day ] = flights_counts[ day ] + 1;
END LOOP;
END LOOP;
-- Выведем итоговый массив в виде таблицы, пронумеровав строки
-- с помощью WITH ORDINALITY.
RETURN QUERY
SELECT week_day, counts.flights_count
FROM unnest( flights_counts ) WITH ORDINALITY 
AS counts( flights_count, week_day );
END;
$$ LANGUAGE plpgsql;
CREATE FUNCTION
```

Вот что получается в результате.

```sql
SELECT * FROM flights_per_days();
day_of_week | flights_count
-------------+---------------
 1 | 538
 2 | 546
 3 | 548
 4 | 550
 5 | 493
 6 | 568
 7 | 555
(7 строк)
```

Задание. Напишите один SQL-запрос, решающий эту же задачу.

Указание. В этом запросе также можно воспользоваться функцией
unnest, для того чтобы разделить массив дней недели, в которые выполняются
рейсы, на отдельные элементы.

<div style="page-break-after: always;"></div>

### Решение

Напишем запрос

```sql
SELECT
    day_of_week,
    COUNT(*) AS flights_count
FROM routes r
CROSS JOIN LATERAL unnest(r.days_of_week) AS day_of_week
GROUP BY day_of_week
ORDER BY day_of_week;
```

<img src="./assets/2026-02-16 183650.jpg" width="700"> 