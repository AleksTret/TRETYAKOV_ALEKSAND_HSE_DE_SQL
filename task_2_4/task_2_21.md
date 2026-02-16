# Домашнее задание 4

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 21

### Задание

Подведение итогов по операции бронирования:
подстановка кода функции в запрос

В одной операции бронирования может быть оформлено несколько билетов, причем на разных пассажиров, а в каждом билете может присутствовать
несколько перелетов. Было бы удобно иметь функцию, которая собирает всю
информацию об операции бронирования примерно таким образом:

```sql
SELECT
ticket_no,
passenger_name,
flight_no AS flight,
departure_airport AS da,
arrival_airport AS aa,
scheduled_departure,
amount
FROM get_booking_info( '000181' )
ORDER BY ticket_no, passenger_name, scheduled_departure;
ticket_no | passenger_name | flight | da | aa | scheduled_departure | amount
−−−−−−−−−−−−−−−+−−−−−−−−−−−−−−−−−−+−−−−−−−−+−−−−−+−−−−−+−−−−−−−−−−−−−−−−−−−−−+−−−−−−−−−−
0005435545944 | ALEKSANDR ZHUKOV | PG0517 | DME | SCW | 2017−08−28 10:30:00 | 10200.00
0005435545944 | ALEKSANDR ZHUKOV | PG0570 | SCW | SVX | 2017−08−28 14:05:00 | 7900.00
0005435545944 | ALEKSANDR ZHUKOV | PG0378 | SVX | NSK | 2017−09−07 13:40:00 | 19100.00
0005435545944 | ALEKSANDR ZHUKOV | PG0125 | NSK | DME | 2017−09−08 18:45:00 | 28700.00
0005435545945 | EVGENIYA KARPOVA | PG0517 | DME | SCW | 2017−08−28 10:30:00 | 10200.00
0005435545945 | EVGENIYA KARPOVA | PG0570 | SCW | SVX | 2017−08−28 14:05:00 | 7900.00
0005435545945 | EVGENIYA KARPOVA | PG0378 | SVX | NSK | 2017−09−07 13:40:00 | 19100.00
0005435545945 | EVGENIYA KARPOVA | PG0125 | NSK | DME | 2017−09−08 18:45:00 | 28700.00
(8 строк)
```
Задание 1. Напишите предлагаемую функцию.

Указание. В коде функции, вероятно, будет использоваться представление «Рейсы» (flights_v). В силу этого планы запросов могут стать громоздкими. Для их
упрощения можно создать таблицу на основе данного представления:

```sql
CREATE TABLE flights_vt AS
SELECT * FROM flights_v;
```

Задание 2. Код такой функции в принципе может встраиваться в запрос, что
в ряде случаев позволит ускорить его выполнение. Необходимые условия были
рассмотрены в подразделе 5.7.1 «Подстановка кода функций в запрос» (с. 347).
Выполните несколько запросов, использующих эту функцию, например:

```sql
SELECT gbi.*
FROM
bookings AS b,
get_booking_info( b.book_ref ) AS gbi
WHERE gbi.passenger_name = 'IVAN IVANOV'
ORDER BY gbi.ticket_no, gbi.passenger_name, gbi.scheduled_departure;
```

Обратите внимание, что в условии предложения WHERE фигурирует столбец,
возвращаемый функцией. В ходе экспериментов организуйте выполнение запроса как с подстановкой кода функции в запрос,так и без нее. Сравните планы
запросов и время их выполнения.

<div style="page-break-after: always;"></div>

### Решение

Создаём flights_vt

<img src="./assets/2026-02-16 161204.jpg" width="700"> 

```sql
CREATE OR REPLACE FUNCTION get_booking_info(p_book_ref char(6))
RETURNS TABLE (
    ticket_no char(13),
    passenger_name text,
    flight char(8),
    da char(3),
    aa char(3),
    scheduled_departure timestamptz,
    amount numeric(10,2)
) 
LANGUAGE sql STABLE AS $$
    SELECT 
        t.ticket_no,
        t.passenger_name,
        f.flight_no,
        f.departure_airport,
        f.arrival_airport,
        f.scheduled_departure,
        tf.amount
    FROM bookings b
    JOIN tickets t ON b.book_ref = t.book_ref
    JOIN ticket_flights tf ON t.ticket_no = tf.ticket_no
    JOIN flights_vt f ON tf.flight_id = f.flight_id
    WHERE b.book_ref = p_book_ref
    ORDER BY t.ticket_no, t.passenger_name, f.scheduled_departure;
$$;
```

<img src="./assets/2026-02-16 161323.jpg" width="700"> 

Проверим встраивание функции

```sql
EXPLAIN (ANALYZE, VERBOSE)
SELECT gbi.*
FROM (
    SELECT DISTINCT book_ref 
    FROM tickets 
    WHERE passenger_name = 'IVAN IVANOV'
) b
CROSS JOIN LATERAL get_booking_info(b.book_ref) gbi
ORDER BY gbi.ticket_no, gbi.passenger_name, gbi.scheduled_departure;
```

<img src="./assets/2026-02-16 162208.jpg" width="700"> 
<img src="./assets/2026-02-16 163729.jpg" width="700"> 

Функция встроена.
В плане нет `Function Scan`. Есть `Unique`, `Nested Loop`, `Hash Join` — это обычные узлы `SQL`. Значит, тело функции развернулось в запрос.

Время выполнения: 65 секунд. Медленно из-за 200 вызовов и больших таблиц.

```sql
CREATE OR REPLACE FUNCTION get_booking_info_plpgsql(p_book_ref char(6))
RETURNS TABLE (
    ticket_no char(13),
    passenger_name text,
    flight char(8),
    da char(3),
    aa char(3),
    scheduled_departure timestamptz,
    amount numeric(10,2)
) 
LANGUAGE plpgsql STABLE AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.ticket_no,
        t.passenger_name,
        f.flight_no,
        f.departure_airport,
        f.arrival_airport,
        f.scheduled_departure,
        tf.amount
    FROM bookings b
    JOIN tickets t ON b.book_ref = t.book_ref
    JOIN ticket_flights tf ON t.ticket_no = tf.ticket_no
    JOIN flights_vt f ON tf.flight_id = f.flight_id
    WHERE b.book_ref = p_book_ref
    ORDER BY t.ticket_no, t.passenger_name, f.scheduled_departure;
END;
$$;
```
<img src="./assets/2026-02-16 164058.jpg" width="700"> 

<img src="./assets/2026-02-16 164158.jpg" width="700">

Сравнение:
`SQL (inline)`: 65 секунд.
`PL/pgSQL`: 7.7 секунд.

В данном случае `PL/pgSQL` быстрее, потому что функция не встраивается и оптимизатор строит более эффективный план для множественных вызовов.