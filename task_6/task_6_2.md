# Домашнее задание 6

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 2

### Задание
В предложении `RETURNING` можно указывать не только символ `«∗»`, означающий
выбор всех столбцов таблицы, но и более сложные выражения, сформированные
на основе этих столбцов. В тексте главы мы копировали содержимое таблицы
«Самолеты» в таблицу `aircrafts_tmp`, используя в предложении `RETURNING`
именно `«∗»`. Однако возможен и другой вариант запроса:
```sql
WITH add_row AS
    ( INSERT INTO aircrafts_tmp
        SELECT * FROM aircrafts
        RETURNING aircraft_code, model, range,
                  current_timestamp, 'INSERT'
)

INSERT INTO aircrafts_log
    SELECT ? FROM add_row;
```
Что нужно написать в этом запросе вместо вопросительного знака?

### Решение

1. Вместо вопросительного знака нужно написать звездочку (`*`):

```sql
WITH add_row AS
    ( INSERT INTO aircrafts_tmp
        SELECT * FROM aircrafts
        RETURNING aircraft_code, model, range,
                  current_timestamp, 'INSERT'
    )

INSERT INTO aircrafts_log
    SELECT * FROM add_row;
```

В предложении `RETURNING` мы уже сформировали все необходимые столбцы в правильном порядке:
- `aircraft_code`
- `model`
- `range`
- `current_timestamp` (для `when_add`)
- `'INSERT'` (для `operation`)

Теперь в основном запросе `SELECT * FROM add_row` просто выбирает все эти столбцы из `CTE add_row` в том же порядке, который соответствует структуре таблицы `aircrafts_log`

<img src="./assets/ex_2/2025-11-12 103520.jpg" width="700">

Проверим результат

<img src="./assets/ex_2/2025-11-12 103557.jpg" width="700">

<img src="./assets/ex_2/2025-11-12 103614.jpg" width="700">

2. Альтернативный вариант с явным перечислением:

```sql
WITH add_row AS
    ( INSERT INTO aircrafts_tmp
        SELECT * FROM aircrafts
        RETURNING aircraft_code, model, range,
                  current_timestamp, 'INSERT'
    )

INSERT INTO aircrafts_log
    SELECT aircraft_code
        ,model
        ,range
        ,current_timestamp
        ,'INSERT'
    FROM add_row;
```

<img src="./assets/ex_2/2025-11-12 104041.jpg" width="700">