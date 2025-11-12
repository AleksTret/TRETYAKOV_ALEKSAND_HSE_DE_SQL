# Домашнее задание 6

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 4

### Задание
В тексте главы в предложениях `ON CONFLICT` команды `INSERT` мы использовали только выражения, состоящие из имени одного столбца. Однако в таблице
«Места» `(seats)` первичный ключ является составным и включает два столбца.

Напишите команду `INSERT` для вставки новой строки в эту таблицу и предусмотрите возможный конфликт добавляемой строки со строкой, уже имеющейся в таблице. Сделайте два варианта предложения `ON CONFLICT`: первый — с использованием перечисления имен столбцов для проверки наличия дублирования, второй — с использованием предложения `ON CONSTRAINT`.

Для того чтобы не изменить содержимое таблицы «Места», создайте ее копию
и выполняйте все эти эксперименты с таблицей-копией.

### Решение

Создание копии таблицы "Места" `(seats)`

```sql
-- Создаем копию таблицы seats
CREATE TEMP TABLE seats_copy AS 
    SELECT * FROM seats;

-- Добавляем составной первичный ключ как в оригинальной таблице
ALTER TABLE seats_copy 
    ADD PRIMARY KEY (aircraft_code, seat_no);
```

<img src="./assets/ex_4/2025-11-12 104911.jpg" width="700">

- Вариант 1: `ON CONFLICT` с перечислением столбцов
```sql
INSERT INTO seats_copy (aircraft_code, seat_no, fare_conditions)
    VALUES 
        ('320', '10A', 'Business'),
        ('321', '15B', 'Economy')
    ON CONFLICT (aircraft_code, seat_no) 
    DO UPDATE SET
        fare_conditions = EXCLUDED.fare_conditions
    RETURNING *;
```
Выполним

<img src="./assets/ex_4/2025-11-12 105644.jpg" width="700">

Протестируем 

```sql
-- Тестируем Вариант 1 (конфликт по столбцам)
INSERT INTO seats_copy (aircraft_code, seat_no, fare_conditions)
VALUES 
    ('320', '10A', 'Comfort+')  -- Конфликт с существующей записью
ON CONFLICT (aircraft_code, seat_no) 
DO UPDATE SET
    fare_conditions = EXCLUDED.fare_conditions
RETURNING *;
```

<img src="./assets/ex_4/2025-11-12 105940.jpg" width="700">


- Вариант 2: `ON CONFLICT ON CONSTRAINT` с именем ограничения

```sql
-- Сначала узнаем имя первичного ключа (если неизвестно)
SELECT constraint_name 
    FROM information_schema.table_constraints 
    WHERE table_name = 'seats_copy' 
        AND constraint_type = 'PRIMARY KEY';
```
<img src="./assets/ex_4/2025-11-12 110135.jpg" width="700">

Выполним

```sql
INSERT INTO seats_copy (aircraft_code, seat_no, fare_conditions)
VALUES 
    ('320', '10A', 'Comfort'),
    ('321', '15B', 'Business')
ON CONFLICT ON CONSTRAINT seats_copy_pkey 
DO UPDATE SET
    fare_conditions = EXCLUDED.fare_conditions
RETURNING *;
```

<img src="./assets/ex_4/2025-11-12 110338.jpg" width="700">

