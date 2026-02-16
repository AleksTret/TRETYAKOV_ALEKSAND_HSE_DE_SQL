# Домашнее задание 4

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 19

### Задание

А если вызвать изменчивую функцию
из стабильной или постоянной?

В разделе документации 36.7 «Категории изменчивости функций» (см. последнее примечание) сказано, что для предотвращения модификации данных
PostgreSQL требует, чтобы стабильные и постоянные функции не содержали
иных SQL-команд, кроме SELECT. Однако это ограничение не является «непробиваемым», как сказано в документации, поскольку из таких функций все же
могут быть вызваны изменчивые функции, способные модифицировать базу
данных. В документации далее говорится, что если реализовать такую схему,
то можно увидеть, что стабильные и постоянные функции не замечают изменений в базе данных, произведенных вызванной изменчивой функцией, поскольку такие изменения не проявляются в их снимке данных.
Задание. Проверьте описанный эффект практически, подобрав сначала абстрактный пример, а затем пример из предметной области авиаперевозок.

<div style="page-break-after: always;"></div>

### Решение

Проверим на абстрактном примере.

```sql
-- Таблица и начальные данные
CREATE TABLE test_table (id int, value text);
INSERT INTO test_table VALUES (1, 'initial');

-- VOLATILE функция, изменяющая данные
CREATE OR REPLACE FUNCTION volatile_update() RETURNS void VOLATILE AS $$
BEGIN
    UPDATE test_table SET value = 'updated' WHERE id = 1;
END;
$$ LANGUAGE plpgsql;

-- STABLE функция, вызывающая VOLATILE и затем читающая данные
CREATE OR REPLACE FUNCTION stable_select() RETURNS text STABLE AS $$
DECLARE
    result text;
BEGIN
    PERFORM volatile_update();
    SELECT value INTO result FROM test_table WHERE id = 1;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Проверка
SELECT * FROM test_table;         
SELECT stable_select();           
SELECT * FROM test_table;        
```      

Ожидаемый результат:
- `SELECT * FROM test_table` вернет значение `1 initial` которое было при создании таблицы. 
- `SELECT stable_select();` не увидит изменений, и так же вернет `initial` 
- `SELECT * FROM test_table;` вернет `1 updated`
После этого проверим реальное значение в таблице и ожидаем, что там будет значение 3 (по одному увеличению на каждый вызов).


<img src="./assets/2026-02-11 092850.jpg" width="700"> 

<img src="./assets/2026-02-11 092940.jpg" width="700"> 



`STABLE` функция работает со снимком данных, полученным в начале запроса. Когда она вызывает `VOLATILE` функцию, та изменяет данные, но эти изменения не попадают в снимок `STABLE` функции. Поэтому последующий `SELECT` внутри `STABLE` функции возвращает старые данные, хотя в базе они уже изменены.

```sql
CREATE OR REPLACE FUNCTION reserve_seat(p_aircraft_code text, p_seat_no text) RETURNS void VOLATILE AS $$
BEGIN
    UPDATE seats SET fare_conditions = 'Reserved' WHERE aircraft_code = p_aircraft_code AND seat_no = p_seat_no;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION check_seat_status(p_aircraft_code text, p_seat_no text) RETURNS text STABLE AS $$
DECLARE
    status text;
BEGIN
    PERFORM reserve_seat(p_aircraft_code, p_seat_no);
    SELECT fare_conditions INTO status FROM seats WHERE aircraft_code = p_aircraft_code AND seat_no = p_seat_no;
    RETURN status;
END;
$$ LANGUAGE plpgsql;
```

<img src="./assets/2026-02-11 100956.jpg" width="700"> 

Изменим ограничения на таблице
```sql
ALTER TABLE seats DROP CONSTRAINT seats_fare_conditions_check;
ALTER TABLE seats ADD CONSTRAINT seats_fare_conditions_check CHECK (fare_conditions IN ('Business', 'Comfort', 'Economy', 'Reserved'));
```

<img src="./assets/2026-02-11 101015.jpg" width="700"> 

Проверка
```sql
SELECT fare_conditions FROM seats WHERE aircraft_code = '319' AND seat_no = '1A';
SELECT check_seat_status('319', '1A');
SELECT fare_conditions FROM seats WHERE aircraft_code = '319' AND seat_no = '1A';
```

<img src="./assets/2026-02-11 101154.jpg" width="700"> 