# Домашнее задание 3

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 3

### Задание

Наглядное представление
планировок салонов

Пассажир имеет право выбрать место в салоне самолета (конечно, из числа свободных). Причем за возможность выбора некоторых мест авиакомпании взимают плату. Предположим, что маркетологи нашей авиакомпании решили выяснить степень популярности различных мест в салонах самолетов. Для этого они попросили нас представить в удобной форме конфигурации салонов,
а именно: для каждого класса обслуживания нужно привести номера первого и последнего рядов, а также список буквенных обозначений кресел в ряду.
Конечно, это упрощение реальной ситуации, поскольку в салоне одного класса
обслуживания могут находиться ряды с разным числом кресел, и каждая группа
рядов потребует отдельного описания.

Необходимую информацию можно получить из таблицы «Места» (seats). Рассмотрим решение этой задачи только для класса обслуживания Business, причем представим два варианта. В каждом из них будем исходить из того, что все
ряды салона этого класса в конкретной модели самолета имеют одно и то же
число кресел.

В первом варианте не используется конструкция LATERAL:
```sql
SELECT
    a.aircraft_code AS a_code,
    a.model,
    sc.first_row AS f_row,
    sc.last_row AS l_row,
    sc.seats_config
FROM aircrafts AS a
LEFT OUTER JOIN
( SELECT
        aircraft_code,
        min( ( left( seat_no, -1 ) )::int ) AS first_row,
        max( ( left( seat_no, -1 ) )::int ) AS last_row,
        array_agg( DISTINCT right( seat_no, 1 ) ORDER BY right( seat_no, 1 ) )
    AS seats_config
    FROM seats
    WHERE fare_conditions = 'Business'
    GROUP BY aircraft_code
    ) AS sc -- seats_config
ON sc.aircraft_code = a.aircraft_code
ORDER BY a.model;
```
Обратите внимание, что левое внешнее соединение необходимо, поскольку
у ряда моделей нет салона бизнес-класса. Все функции, использованные в запросе, уже известны читателю. Добавим только, что отрицательное значение
второго параметра функции left позволяет отбросить часть символов строки,
начиная с ее правого конца. В нашем случае отбрасывается только один символ — буквенное обозначение места в ряду, и в результате остается лишь номер
ряда. И еще важно, что в вызове функции array_agg присутствует ключевое слово DISTINCT. Без него мы получили бы многократное дублирование букв.
```text
a_code  | model               | f_row | l_row | seats_config
−−−−−−−−+−−−−−−−−−−−−−−−−−−−−−+−−−−−−−+−−−−−−−+−−−−−−−−−−−−−−−
319     | Аэробус A319−100    | 1     | 5     | {A,C,D,F}
320     | Аэробус A320−200    | 1     | 5     | {A,C,D,F}
321     | Аэробус A321−200    | 1     | 7     | {A,C,D,F}
733     | Боинг 737−300       | 1     | 3     | {A,C,D,F}
763     | Боинг 767−300       | 1     | 5     | {A,B,C,F,G,H}
773     | Боинг 777−300       | 1     | 5     | {A,C,D,G,H,K}
CR2     | Бомбардье CRJ−200   |       |       |
CN1     | Сессна 208 Караван  |       |       |
SU9     | Сухой Суперджет−100 | 1     | 3     | {A,C,D,F}
(9 строк)
```

Заметим, что возможность указывать и DISTINCT, и ORDER BY в агрегатном выражении — это расширение PostgreSQL, как сказано в подразделе документации
4.2.7 «Агрегатные выражения».
Тот же результат можно получить и с помощью запроса, использующего конструкцию LATERAL.
```sql
SELECT
    a.aircraft_code AS a_code,
    a.model,
    s.first_row AS f_row,
    s.last_row AS l_row,
    s.seats_config
FROM aircrafts AS a,
LATERAL
    ( SELECT
        min( ( left( s.seat_no, -1 ) )::int ) AS first_row,
        max( ( left( s.seat_no, -1 ) )::int ) AS last_row,
        array_agg( DISTINCT right( s.seat_no, 1 ) ORDER BY right( s.seat_no, 1 ) )
    AS seats_config
FROM seats s
WHERE s.aircraft_code = a.aircraft_code
AND s.fare_conditions = 'Business'
) AS s
ORDER BY a.model;
```
Напомним, что запятая между элементами в предложении FROM равнозначна
ключевым словам CROSS JOIN.
Вопрос. В запросе с конструкцией LATERAL не использовано левое внешнее соединение. Тем не менее те модели, у которых нет салона бизнес-класса, также
вошли в выборку. Как это можно объяснить?
Указание. Обратите внимание на то, сколько строк выводит следующий упрощенный запрос и какое значение содержится в столбце first_row:
```sql
SELECT min( ( left( seat_no, -1 ) )::int ) AS first_row
FROM seats
WHERE aircraft_code = 'CN1'
AND fare_conditions = 'Business';
first_row
−−−−−−−−−−−
(1 строка)
```

Задание. 
Напишите запрос, формирующий конфигурацию салонов с учетом
всех трех существующих классов обслуживания. Найдите решение как с использованием конструкции LATERAL, так и без нее. Сравните сложность этих вариантов запроса.

<div style="page-break-after: always;"></div>

### Решение

Сделаем вариант без `LATERAL`
Для того что бы избежать дублирования кода используем `CTE`

```sql
WITH classes AS (
    SELECT 'Business' AS fare_conditions UNION ALL
    SELECT 'Comfort' UNION ALL
    SELECT 'Economy'
),
all_config AS (
    SELECT 
        aircraft_code,
        fare_conditions,
        MIN((LEFT(seat_no, -1))::int) AS first_row,
        MAX((LEFT(seat_no, -1))::int) AS last_row,
        ARRAY_AGG(DISTINCT RIGHT(seat_no, 1) 
                 ORDER BY RIGHT(seat_no, 1)) AS seats_config
    FROM seats
    GROUP BY aircraft_code, fare_conditions
)
SELECT 
    a.aircraft_code AS a_code,
    a.model,
    c.fare_conditions,
    ac.first_row AS f_row,
    ac.last_row AS l_row,
    ac.seats_config
FROM aircrafts a
CROSS JOIN classes c
LEFT JOIN all_config ac 
    ON ac.aircraft_code = a.aircraft_code 
    AND ac.fare_conditions = c.fare_conditions
ORDER BY a.model, c.fare_conditions;
```

<img src="./assets/2026-02-02 205257.jpg" width="700"> 

<img src="./assets/2026-02-02 205323.jpg" width="700"> 


```sql
SELECT 
    a.aircraft_code AS a_code,
    a.model,
    c.fare_conditions,
    s.first_row AS f_row,
    s.last_row AS l_row,
    s.seats_config
FROM aircrafts a
CROSS JOIN (
    VALUES ('Business'), ('Comfort'), ('Economy')
) AS c(fare_conditions)
LEFT JOIN LATERAL (
    SELECT 
        MIN((LEFT(seats.seat_no, -1))::int) AS first_row,
        MAX((LEFT(seats.seat_no, -1))::int) AS last_row,
        ARRAY_AGG(DISTINCT RIGHT(seats.seat_no, 1) 
                 ORDER BY RIGHT(seats.seat_no, 1)) AS seats_config
    FROM seats
    WHERE seats.aircraft_code = a.aircraft_code 
      AND seats.fare_conditions = c.fare_conditions
) s ON TRUE
ORDER BY a.model, c.fare_conditions;
```
<img src="./assets/2026-02-02 205202.jpg" width="700"> 

<img src="./assets/2026-02-02 205225.jpg" width="700"> 

