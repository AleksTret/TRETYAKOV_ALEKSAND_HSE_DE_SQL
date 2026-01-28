# Домашнее задание 1

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 17

### Задание
Главный запрос и все общие табличные выражения в WITH
работают с одним и тем же снимком данных
В подразделе документации 7.8.4 «Изменение данных в WITH» сказано, что
и главный запрос, и все общие табличные выражения в WITH работают с одним
и тем же снимком данных.

Давайте проведем эксперимент, поместив все SQL-запросы, которые требуется
выполнить для реализации процедуры бронирования, в один SQL-запрос с общими табличными выражениями.

В реальной работе код бронирования и номер билета должны генерироваться с помощью специальных процедур, гарантирующих их уникальность; мы
же допустим упрощение, задав эти значения в виде констант. Но, чтобы наш
эксперимент все же был приближен к реальности, в тех подзапросах, которые
работают с подчиненными таблицами, не будем повторно задавать те же самые константы, а будем получать значения кода бронирования и номера билета из
временных таблиц. Так мы оправдаем наличие предложений `RETURNING`.

В первом подзапросе (`bk`) мы вставим строку в таблицу «Бронирования» (`bookings`), но значение поля `total_amount` в ней назначим равным нулю, поскольку на данном этапе оно неизвестно. После завершения процедуры оно должно
стать равным сумме стоимостей всех перелетов, оформленных в рамках этой
процедуры бронирования.

Во втором подзапросе (`tk`) оформим два билета. При этом берем код бронирования, обращаясь к временной таблице, сформированной с помощью предложения `RETURNING` в первом подзапросе.

В третьем подзапросе (`tkf`) сформируем перелеты. В нем мы тоже берем номер
билета из подзапроса, а не вводим его как константу.

Главный запрос обновляет строку, вставленную в первом подзапросе, получив
доступ к стоимостям всех оформленных перелетов.

```sql
BEGIN;
BEGIN;
WITH bk AS
    ( INSERT INTO bookings ( book_ref, book_date, total_amount )
    VALUES ( 'ABC123', bookings.now(), 0 )
    RETURNING book_ref
),
tk AS
    ( INSERT INTO tickets ( ticket_no, book_ref, passenger_id, passenger_name )
    VALUES ( '9991234567890', ( SELECT book_ref FROM bk ), '1234 123456', 'IVAN PETROV' ),
    ( '9991234567891', ( SELECT book_ref FROM bk ), '4321 654321', 'PETR IVANOV' )
RETURNING ticket_no, passenger_id
),
tkf AS
    ( INSERT INTO ticket_flights ( ticket_no, flight_id, fare_conditions, amount )
    VALUES ( ( SELECT ticket_no FROM tk WHERE passenger_id = '1234 123456' ),
    5572, 'Business', 12500 ),
    ( ( SELECT ticket_no FROM tk WHERE passenger_id = '4321 654321' ),
    13881, 'Economy', 8500 )
    RETURNING amount
)
UPDATE bookings
SET total_amount = ( SELECT sum( amount ) FROM tkf )
WHERE book_ref = ( SELECT book_ref FROM bk );
```

Задание 1. Сделайте обоснованное предположение: будет ли обновлена строка
в таблице «Бронирования» (bookings)? Проверьте вашу гипотезу практически.

```sql
SELECT * FROM bookings WHERE book_ref = 'ABC123';
```
Какое число будет в столбце `total_amount`?
Поскольку эксперименты продолжатся, отмените транзакцию.
```sql
ROLLBACK;
ROLLBACK
```
Задание 2. Разделите приведенный запрос на отдельные запросы и выполните их в рамках транзакции на уровне изоляции, например, Repeatable Read. На
этом уровне все запросы транзакции выполняются с тем снимком данных, который был сделан в момент начала выполнения ее первого запроса (см. подраздел документации 13.2.2 «Уровень изоляции Repeatable Read»). Будет ли теперь
обновлена строка в таблице «Бронирования» (bookings)? Сопоставьте результаты двух проведенных экспериментов. Конечно, во втором эксперименте нам
не удастся получать повторный доступ к коду бронирования и номеру билета с помощью подзапросов, но в данном случае для нас важнее сопоставить
механизмы выполнения запроса с общими табличными выражениями и транзакции, имеющей аналогичный набор команд.


<div style="page-break-after: always;"></div>

### Решение

#### Задание 1: Будет ли обновлена строка в CTE-запросе?

Cтрока НЕ БУДЕТ обновлена.

Потому что, например из документации следует что:
- "Все эти операторы выполняются с одним снимком данных", то есть и CTE, и главный запрос видят состояние таблиц до начала выполнения всего запроса.
- "Операторы... не могут «видеть», как каждый из них меняет целевые таблицы" - UPDATE в главном запросе не видит вставку, сделанную в CTE bk.
- "RETURNING — единственный вариант передачи изменений" - через RETURNING мы передаем данные между CTE, но главный запрос все равно работает с исходным снимком.

Результат: INSERT выполнится, создав запись с total_amount = 0, но UPDATE не найдет эту запись для обновления.

Практическая проверка:

```sql
BEGIN;

WITH bk AS (
    INSERT INTO bookings (book_ref, book_date, total_amount)
    VALUES ('ABC123', bookings.now(), 0)
    RETURNING book_ref
),
tk AS (
    INSERT INTO tickets (ticket_no, book_ref, passenger_id, passenger_name)
    VALUES 
        ('9991234567890', (SELECT book_ref FROM bk), '1234 123456', 'IVAN PETROV'),
        ('9991234567891', (SELECT book_ref FROM bk), '4321 654321', 'PETR IVANOV')
    RETURNING ticket_no, passenger_id
),
tkf AS (
    INSERT INTO ticket_flights (ticket_no, flight_id, fare_conditions, amount)
    VALUES 
        ((SELECT ticket_no FROM tk WHERE passenger_id = '1234 123456'), 5572, 'Business', 12500),
        ((SELECT ticket_no FROM tk WHERE passenger_id = '4321 654321'), 13881, 'Economy', 8500)
    RETURNING amount
)
UPDATE bookings
SET total_amount = (SELECT sum(amount) FROM tkf)
WHERE book_ref = (SELECT book_ref FROM bk);

-- Проверяем результат
SELECT * FROM bookings WHERE book_ref = 'ABC123';
-- Ожидаем: total_amount = 21000

ROLLBACK;
```
Проверим наличие значения в таблицы до выполнения `UPDATE`

<img src="./assets/2026-01-28 152205.jpg" width="700"> 

Выполним обновление и проверим результат повторно

<img src="./assets/2026-01-28 154217.jpg" width="700"> 

Как результат `total_amount` = 0.

<div style="page-break-after: always;"></div>

## Задание 2: Разделение на отдельные запросы в транзакции Repeatable Read

Cтрока БУДЕТ обновлена, потому что:

- В уровне изоляции `Repeatable Read` каждый последующий запрос видит изменения, сделанные предыдущими запросами в той же транзакции.
- `INSERT` выполнится, и последующий `UPDATE` увидит вставленную строку, так как изменения внутри транзакции видны всем ее запросам.

Итог: `total_amount` станет равно `21 000`.

```sql
-- Начинаем транзакцию с уровнем изоляции Repeatable Read
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- 1. Вставляем бронирование
INSERT INTO bookings (book_ref, book_date, total_amount)
VALUES ('ABC123', bookings.now(), 0)
RETURNING book_ref;

-- 2. Вставляем билеты
INSERT INTO tickets (ticket_no, book_ref, passenger_id, passenger_name)
VALUES 
    ('9991234567890', 'ABC123', '1234 123456', 'IVAN PETROV'),
    ('9991234567891', 'ABC123', '4321 654321', 'PETR IVANOV');

-- 3. Вставляем перелеты
INSERT INTO ticket_flights (ticket_no, flight_id, fare_conditions, amount)
VALUES 
    ('9991234567890', 5572, 'Business', 12500),
    ('9991234567891', 13881, 'Economy', 8500);

-- 4. Обновляем сумму бронирования
UPDATE bookings
SET total_amount = (
    SELECT SUM(amount) 
    FROM ticket_flights 
    WHERE ticket_no IN ('9991234567890', '9991234567891')
)
WHERE book_ref = 'ABC123';

-- Проверяем результат
SELECT * FROM bookings WHERE book_ref = 'ABC123';

ROLLBACK;
```
<img src="./assets/2026-01-28 161040.jpg" width="700"> 

