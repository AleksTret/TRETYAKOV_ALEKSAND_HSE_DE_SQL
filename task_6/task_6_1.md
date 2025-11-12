# Домашнее задание 6

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 1

### Задание
Добавьте в определение таблицы `aircrafts_log` значение по умолчанию
`current_timestamp` и соответствующим образом измените команды `INSERT`,
приведенные в тексте главы.

### Решение
Создадим временную таблицу `aircrafts_tmp` как в Главе 7. Добавим поля.
```sql
CREATE TEMP TABLE aircrafts_tmp AS
    SELECT * FROM aircrafts WITH NO DATA;

ALTER TABLE aircrafts_tmp
    ADD PRIMARY KEY ( aircraft_code );
ALTER TABLE aircrafts_tmp
    ADD UNIQUE ( model );
```
<img src="./assets/ex_1/2025-11-12 100528.jpg" width="700">

Создадим временную таблицу `aircrafts_log`. Добавим поля в таблицу.

Для поля `when_add` добавим значение по умолчанию `= current_timestamp`

```sql
CREATE TEMP TABLE aircrafts_log AS
    ELECT * FROM aircrafts WITH NO DATA;

ALTER TABLE aircrafts_log
    ADD COLUMN when_add timestamp DEFAULT current_timestamp;
ALTER TABLE aircrafts_log
    ADD COLUMN operation text;
```

<img src="./assets/ex_1/2025-11-12 101249.jpg" width="700">

Модифицируем команду `INSERT` с явным указанием именов столбцов следующим образом

```sql
WITH add_row AS
( INSERT INTO aircrafts_tmp
    SELECT * FROM aircrafts
    RETURNING *
)
INSERT INTO aircrafts_log (aircraft_code, model, range, operation)
    SELECT add_row.aircraft_code, add_row.model, add_row.range, 'INSERT'
    FROM add_row;
```

<img src="./assets/ex_1/2025-11-12 102054.jpg" width="700">

Если выполнить команду без явного перечисления столбцов, получим ошибку

```sql
WITH add_row AS
( INSERT INTO aircrafts_tmp
    SELECT * FROM aircrafts
    RETURNING *
)
INSERT INTO aircrafts_log
    SELECT add_row.aircraft_code, add_row.model, add_row.range, 'INSERT'
    FROM add_row;    
```

<img src="./assets/ex_1/2025-11-12 101948.jpg" width="700">

Проверим результат

<img src="./assets/ex_1/2025-11-12 102356.jpg" width="700">

<img src="./assets/ex_1/2025-11-12 102416.jpg" width="700">


Столбец when_add заполняется автоматически со значением актуального время операции
