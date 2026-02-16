# Домашнее задание 4

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 20

### Задание

Не только багаж,
но и питание

В подразделе 5.6.2 «Видимость изменений» (с. 338) мы рассматривали ситуацию, в которой в процессе регистрации билетов на рейс подсчитывались багажные места и их общий вес. Предположим, что с целью дальнейшего повышения
качества обслуживания пассажиров наша авиакомпания решила опрашивать
их перед полетом насчет предпочитаемого питания.

Задание 1. Для реализации поставленной задачи создайте дополнительную таблицу «Питание» (flight_meals) и соответствующим образом модифицируйте
функции, выполняющие регистрацию билета.
Таблица может быть, например, такой:
```sql
CREATE TABLE flight_meals
( flight_id integer,
boarding_no integer,
main_course text NOT NULL
CHECK ( main_course IN ( 'мясо', 'рыба', 'курица' ) ),
PRIMARY KEY ( flight_id, boarding_no ),
FOREIGN KEY ( flight_id, boarding_no )
REFERENCES boarding_passes ( flight_id, boarding_no )
ON DELETE CASCADE
);
CREATE TABLE
```
Теперь функция `boarding_info` должна выводить не только сведения о багаже,
но также и общее число блюд каждого вида, выбранных пассажирами данного
рейса.

Задание 2. Повторите ранее проведенные эксперименты, модифицировав запросы соответствующим образом.

<div style="page-break-after: always;"></div>

### Решение

Создадим таблицы
```sql
CREATE TABLE flight_meals (
    flight_id integer,
    boarding_no integer,
    main_course text NOT NULL
    CHECK ( main_course IN ( 'мясо', 'рыба', 'курица' ) ),
    PRIMARY KEY ( flight_id, boarding_no ),
    FOREIGN KEY ( flight_id, boarding_no )
    REFERENCES boarding_passes ( flight_id, boarding_no )
    ON DELETE CASCADE
);

CREATE TABLE luggage (
    flight_id integer,
    boarding_no integer,
    piece_no smallint NOT NULL CHECK ( piece_no > 0 ),
    weight numeric( 3, 1 ) CHECK ( weight > 0.0 ),
    PRIMARY KEY ( flight_id, boarding_no, piece_no ),
    FOREIGN KEY ( flight_id, boarding_no )
    REFERENCES boarding_passes ( flight_id, boarding_no ) ON DELETE CASCADE
);
```
<img src="./assets/2026-02-11 102957.jpg" width="700"> 

<img src="./assets/2026-02-11 103018.jpg" width="700"> 

Модифицируем функцию

```sql
CREATE OR REPLACE FUNCTION boarding_info(
    INOUT flight_id integer,
    OUT total_passengers bigint,
    OUT total_luggage_pieces bigint,
    OUT total_luggage_weight numeric,
    OUT meat_cnt bigint,
    OUT fish_cnt bigint,
    OUT chicken_cnt bigint
) RETURNS record AS $$
WITH boarding_pass_info AS (
    SELECT count(*) AS total_passengers
    FROM boarding_passes
    WHERE flight_id = boarding_info.flight_id
),
luggage_info AS (
    SELECT count(*) AS total_luggage_pieces,
           sum(weight) AS total_luggage_weight
    FROM luggage
    WHERE flight_id = boarding_info.flight_id
),
meals_info AS (
    SELECT 
        count(*) FILTER (WHERE main_course = 'мясо') AS meat_cnt,
        count(*) FILTER (WHERE main_course = 'рыба') AS fish_cnt,
        count(*) FILTER (WHERE main_course = 'курица') AS chicken_cnt
    FROM flight_meals
    WHERE flight_id = boarding_info.flight_id
)
SELECT 
    flight_id,
    bpi.total_passengers,
    li.total_luggage_pieces,
    li.total_luggage_weight,
    mi.meat_cnt,
    mi.fish_cnt,
    mi.chicken_cnt
FROM 
    boarding_pass_info AS bpi,
    luggage_info AS li,
    meals_info AS mi;
$$ LANGUAGE sql STABLE;
```

Вставим тестовые данные в `flight_meals` используя существующие `boarding_passes`.
Поищем какой нибудь рейс

```sql
SELECT flight_id, boarding_no FROM boarding_passes LIMIT 1;
```

<img src="./assets/2026-02-11 103619.jpg" width="700"> 

Вставляем данные о питании для трёх разных boarding_no на рейсе 30625
Сначала проверим, есть ли у рейса 30625 хотя бы 3 boarding_no
```sql
SELECT boarding_no FROM boarding_passes WHERE flight_id = 30625 LIMIT 3;
```
<img src="./assets/2026-02-11 103909.jpg" width="700"> 

```sql
INSERT INTO flight_meals (flight_id, boarding_no, main_course) VALUES
(13841, 1, 'мясо'),
(13841, 2, 'рыба'),
(13841, 3, 'курица');
```

<img src="./assets/2026-02-11 103955.jpg" width="700"> 

Проверим работы модифицированной функции `boarding_info`

```sql
SELECT * FROM boarding_info(30625);
```

<img src="./assets/2026-02-11 104203.jpg" width="700"> 

Теперь проведем эксперементы

Добавим тестовый билет

```sql
INSERT INTO tickets (ticket_no, book_ref, passenger_id, passenger_name)
SELECT 'TEST0000002', book_ref, 'TEST002', 'Test Passenger'
FROM bookings LIMIT 1;

INSERT INTO ticket_flights (ticket_no, flight_id, fare_conditions, amount)
VALUES ('TEST0000002', 30625, 'Economy', 10000);
```

<img src="./assets/2026-02-16 154847.jpg" width="700">

Выполним эксперемент



```sql
BEGIN ISOLATION LEVEL READ COMMITTED;

WITH reg AS (
    INSERT INTO boarding_passes (ticket_no, flight_id, boarding_no, seat_no)
    VALUES ('TEST0000002', 30625, 93, '20C')
    RETURNING flight_id, boarding_no
),
bag AS (
    INSERT INTO luggage (flight_id, boarding_no, piece_no, weight)
    SELECT flight_id, boarding_no, 1, 10.5 FROM reg
),
meal AS (
    INSERT INTO flight_meals (flight_id, boarding_no, main_course)
    SELECT flight_id, boarding_no, 'мясо' FROM reg
)
SELECT * FROM boarding_info(30625);

ROLLBACK;
```

<img src="./assets/2026-02-16 154943.jpg" width="700">

Результат эксперимента (STABLE):

- total_passengers = 92 (старое значение, новая регистрация не учтена).
- total_luggage_pieces = 0 (новый багаж не учтён).
- meat_cnt = 1 (новое блюдо 'мясо' не учтено, осталось 1 от предыдущих тестов).

Всё верно. STABLE функция не видит изменения в текущей транзакции.

```sql
ALTER FUNCTION boarding_info VOLATILE;

BEGIN ISOLATION LEVEL READ COMMITTED;

INSERT INTO boarding_passes (ticket_no, flight_id, boarding_no, seat_no)
VALUES ('TEST0000002', 30625, 93, '20C');

INSERT INTO luggage (flight_id, boarding_no, piece_no, weight)
VALUES (30625, 93, 1, 10.5);

INSERT INTO flight_meals (flight_id, boarding_no, main_course)
VALUES (30625, 93, 'мясо');

SELECT * FROM boarding_info(30625);

ROLLBACK;
```

<img src="./assets/2026-02-16 155517.jpg" width="700">

<img src="./assets/2026-02-16 155248.jpg" width="700">

Результат (VOLATILE, отдельные запросы):

- total_passengers = 93 (увеличилось).
- total_luggage_pieces = 1, weight = 10.5 (багаж учтён).
- meat_cnt = 2 (новое мясо добавлено).

VOLATILE функция видит изменения, сделанные в той же транзакции, если вызывается после вставок отдельным запросом.