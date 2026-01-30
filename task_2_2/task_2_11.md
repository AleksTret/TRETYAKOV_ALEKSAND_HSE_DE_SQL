# Домашнее задание 2

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 14

### Задание

Влияет ли порядок следования групп столбцов
в конструкции GROUPING SETS на работу запроса?
В подразделе 3.3.1 «Группировка с помощью GROUPING SETS» (с. 137) был приведен запрос, вычисляющий количество рейсов, выполняемых самолетами разных моделей из каждого аэропорта. В том запросе группировка выполнялась по
комбинации наименования аэропорта и наименования модели самолета.

Задание. Измените порядок группирования строк на обратный: первым должно
идти наименование модели самолета, а затем наименование аэропорта. Модифицируйте запрос таким образом, чтобы он выводил отчет в следующем виде:

```text
model                           | airport_name         | routes_count
−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−+−−−−−−−−−−−−−−−−−−−−−−+−−−−−−−−−−−−−−
Аэробус A319−100                | Астрахань            | 1
Аэробус A319−100                | Байкал               | 1
Аэробус A319−100                | Богашёво             | 1
Аэробус A319−100                | Братск               | 1
Аэробус A319−100                | Казань               | 1
...
Аэробус A319−100                | Талаги               | 2
Аэробус A319−100                | Хомутово             | 2
Аэробус A319−100                | Внуково              | 3
Аэробус A319−100                | Шереметьево          | 3
Аэробус A319−100                | Анадырь              | 4
Аэробус A319−100                | Чульман              | 4
Аэробус A319−100                | Домодедово           | 5
Всего по Аэробус A319−100       |                      | 46
Аэробус A321−200                | Иркутск              | 1
Аэробус A321−200                | Казань               | 1
...
Сухой Суперджет−100             | Брянск               | 10
Сухой Суперджет−100             | Домодедово           | 18
Сухой Суперджет−100             | Шереметьево          | 18
Всего по Сухой Суперджет−100    |                      | 158
                                | Братск               | 1
                                | Елизово              | 1
                                | Игнатьево            | 1
                                ...
                                | Пулково              | 35
                                | Шереметьево          | 57
                                | Домодедово           | 62
ИТОГО | | 710
(387 строк)
```

Обязательно ли порядок следования имен столбцов в конструкции GROUPING
SETS должен совпадать с порядком их вывода в выборке?
```sql
GROUP BY GROUPING SETS
( ( a.model, r.departure_airport_name ),
    ( a.model ),
    ( r.departure_airport_name ),
    ( )
)
```
А если сделать так, это повлияет на выполнение запроса?
```sql
GROUP BY GROUPING SETS
( ( a.model ),
    ( a.model, r.departure_airport_name ),
    ( ),
    ( r.departure_airport_name )
)
```

<div style="page-break-after: always;"></div>

### Решение

Перепишем исходный запрос из книги

```sql
SELECT CASE
        WHEN r.departure_airport_name IS NULL AND a.model IS NULL
            THEN 'ИТОГО'
        WHEN a.model IS NULL
            THEN ' Всего по а/п ' || r.departure_airport_name
        ELSE r.departure_airport_name
    END AS airport,
    a.model,
    count( * ) AS routes_count
FROM routes r
JOIN aircrafts a ON a.aircraft_code = r.aircraft_code
GROUP BY GROUPING SETS
    ( ( r.departure_airport_name, a.model ),
    ( r.departure_airport_name ),
    ( a.model ),
    ()
    )
ORDER BY airport, routes_count, a.model;
```

<img src="./assets/2026-01-30 103747.jpg" width="700"> 

Изменим запрос, как требуется по заданию

```sql
SELECT 
    CASE
        WHEN a.model IS NULL AND r.departure_airport_name IS NULL THEN 'ИТОГО'
        WHEN r.departure_airport_name IS NULL THEN 'Всего по ' || a.model
        ELSE a.model
    END AS model,
    CASE
        WHEN r.departure_airport_name IS NULL AND a.model IS NOT NULL THEN ''
        ELSE COALESCE(r.departure_airport_name, '')
    END AS airport_name,
    COUNT(*) AS routes_count
FROM bookings.routes r
JOIN bookings.aircrafts a ON a.aircraft_code = r.aircraft_code
GROUP BY GROUPING SETS
    ( ( r.departure_airport_name, a.model ),
    ( r.departure_airport_name ),
    ( a.model ),
    ()
    )
ORDER BY 
    a.model NULLS LAST,
    routes_count,
    r.departure_airport_name NULLS LAST;
```    

Ограниченный LIMIT 10 вывод

<img src="./assets/2026-01-30 113901.jpg" width="700"> 

Более полный вывод результата запроса

<img src="./assets/2026-01-30 113922.jpg" width="700"> 

Проверим что порядок следования имен столбцов в конструкции `GROUPING SETS` что порядок имен может не совпадать с порядком их вывода в выборке

Используя следующий вид группировки
```sql
GROUP BY GROUPING SETS
( ( a.model, r.departure_airport_name ),
    ( a.model ),
    ( r.departure_airport_name ),
    ( )
)
```

Полный текст запроса

```sql
SELECT 
    CASE
        WHEN a.model IS NULL AND r.departure_airport_name IS NULL THEN 'ИТОГО'
        WHEN r.departure_airport_name IS NULL THEN 'Всего по ' || a.model
        ELSE a.model
    END AS model,
    CASE
        WHEN r.departure_airport_name IS NULL AND a.model IS NOT NULL THEN ''
        ELSE COALESCE(r.departure_airport_name, '')
    END AS airport_name,
    COUNT(*) AS routes_count
FROM bookings.routes r
JOIN bookings.aircrafts a ON a.aircraft_code = r.aircraft_code
GROUP BY GROUPING SETS
( ( a.model, r.departure_airport_name ),
    ( a.model ),
    ( r.departure_airport_name ),
    ( )
)
ORDER BY 
    a.model NULLS LAST,
    routes_count,
    r.departure_airport_name NULLS LAST;
``` 
<img src="./assets/2026-01-30 114154.jpg" width="700"> 

<img src="./assets/2026-01-30 114214.jpg" width="700"> 

Теперь используя

Используя следующий вид группировки
```sql
GROUP BY GROUPING SETS
( ( a.model ),
    ( a.model, r.departure_airport_name ),
    ( ),
    ( r.departure_airport_name )
)
```

Полный текст запроса

```sql
SELECT 
    CASE
        WHEN a.model IS NULL AND r.departure_airport_name IS NULL THEN 'ИТОГО'
        WHEN r.departure_airport_name IS NULL THEN 'Всего по ' || a.model
        ELSE a.model
    END AS model,
    CASE
        WHEN r.departure_airport_name IS NULL AND a.model IS NOT NULL THEN ''
        ELSE COALESCE(r.departure_airport_name, '')
    END AS airport_name,
    COUNT(*) AS routes_count
FROM bookings.routes r
JOIN bookings.aircrafts a ON a.aircraft_code = r.aircraft_code
GROUP BY GROUPING SETS
( ( a.model ),
    ( a.model, r.departure_airport_name ),
    ( ),
    ( r.departure_airport_name )
)
ORDER BY 
    a.model NULLS LAST,
    routes_count,
    r.departure_airport_name NULLS LAST;
```

<img src="./assets/2026-01-30 114447.jpg" width="700"> 

<img src="./assets/2026-01-30 114502.jpg" width="700"> 


Получается что порядок следования имен столбцов в конструкции GROUPING SETS может не совпадать с порядком их вывода в выборке.