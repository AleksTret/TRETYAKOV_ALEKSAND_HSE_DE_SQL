# Домашнее задание 5

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 1

### Задание

Функция на языке SQL может возвращать значение типа record, а вот
принимать параметр такого типа не может. Однако язык PL/pgSQL позволяет
задавать параметры такого типа.
Давайте напишем три простые функции для иллюстрации сказанного.
Первая из них будет подсчитывать число аэропортов в указанном часовом
поясе, имеющих долготу и широту больше заданных.

```sql
CREATE OR REPLACE FUNCTION param_record( params record )
 RETURNS bigint AS
$$
DECLARE
 cnt bigint;
BEGIN
 SELECT count( *) INTO cnt FROM airports
 WHERE timezone ~ params.tz AND
 coordinates[ 0 ] > params.long AND
 coordinates[ 1 ] > params.lat;
 RETURN cnt;
END;
$$ LANGUAGE plpgsql;
CREATE FUNCTION
```

Аналогичная функция на языке SQL не получается.

```sql
CREATE OR REPLACE FUNCTION param_record_sql( params record )
 RETURNS bigint AS
$$
 SELECT count( *) FROM airports
 WHERE timezone ~ params.tz AND
 coordinates[ 0 ] > params.long AND
 coordinates[ 1 ] > params.lat;
$$ LANGUAGE sql;
ОШИБКА: SQL-функции не могут иметь аргументы типа record
```

Это функция, возвращающая значение типа record. Она будет
использоваться для формирования параметра функции param_record.

```sql
CREATE OR REPLACE FUNCTION
 prepare_param_record( timezone text, longitude integer,
 latitude integer )
 RETURNS record AS
$$
DECLARE
 rec record;
BEGIN
 SELECT * INTO rec
 FROM ...
 RETURN rec;
END;
$$ LANGUAGE plpgsql;
CREATE FUNCTION
```

Проверим функции в работе.

```sql
SELECT param_record( prepare_param_record(
 'Yekaterinburg', 70, 60 ) );
param_record
--------------
 7
(1 строка)
```

Задание. Допишите код функции prepare_param_record.


<div style="page-break-after: always;"></div>

### Решение

Код функции

```sql
CREATE OR REPLACE FUNCTION prepare_param_record(
    timezone text, 
    longitude integer, 
    latitude integer
) RETURNS record AS $$
DECLARE
    rec record;
BEGIN
    SELECT tz, long, lat INTO rec
    FROM (VALUES (timezone, longitude, latitude)) AS t(tz, long, lat);
    RETURN rec;
END;
$$ LANGUAGE plpgsql;
```

Проверим работу

```sql
SELECT prepare_param_record('Yekaterinburg', 70, 60);
```

<img src="./assets/2026-02-16 182953.jpg" width="700"> 

<img src="./assets/2026-02-16 183014.jpg" width="700"> 