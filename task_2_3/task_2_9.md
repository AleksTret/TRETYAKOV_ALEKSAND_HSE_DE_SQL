# Домашнее задание 3

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 9

### Задание


Функция
JSON_TABLE
В разделе 4.3 «Тип JSON и конструкция LATERAL» (с. 236) решалась задача формирования номеров кресел для салонов самолетов с применением функции
JSON_TABLE. В исходных данных для каждой модели самолета предусматривалась одна строка, содержащая два поля: код модели и описания планировок ее
салонов, представленные в виде JSON-массива.
```sql
WITH seats_confs( aircraft_code, seats_conf ) AS
( VALUES
    ( 'SU9',
    '[ { "fare conditions": "Business",
    "rows": [ 1, 3 ],
    "letters": [ "A", "C", "D", "F" ] },
    { "fare conditions": "Economy",
    "rows": [ 4, 20 ],
    "letters": [ "A", "C", "D", "E", "F" ] }
    ]'::jsonb
    ),
    ( 'CN1',
    '[ { "fare conditions": "Economy",
    "rows": [ 1, 6 ],
    "letters": [ "A", "B" ] }
    ]'::jsonb
    )
)
...
```
Структуру исходных данных можно изменить, объединив два поля в единый
JSON-объект. В него нужно поместить код модели самолета в качестве скалярного значения с ключом aircraft_code и JSON-массив описаний планировок
с ключом confs:
```sql
WITH seats_confs(seats_conf) AS (
    VALUES
    ('{ "aircraft code": "SU9",
        "confs": [ { "fare conditions": "Business",
                    "rows": [ 1, 3 ],
                    "letters": [ "A", "C", "D", "F" ] },
                  { "fare conditions": "Economy",
                    "rows": [ 4, 20 ],
                    "letters": [ "A", "C", "D", "E", "F" ] }
                ]
    }'::jsonb),
    ('{ "aircraft code": "CN1",
        "confs": [ { "fare conditions": "Economy",
                    "rows": [ 1, 6 ],
                    "letters": [ "A", "B" ] }
                ]
    }'::jsonb)
)
SELECT
aircraft_code,
fare_conditions,
row || letter AS seat_no
FROM seats_confs AS sc,
...
generate_series( row_from, row_to ) AS rows( row )
ORDER BY aircraft_code, row, letter;
```
Задание. Модифицируйте запрос с учетом изменившейся структуры данных

<div style="page-break-after: always;"></div>

### Решение

Модифицируем запрос

```sql
WITH seats_confs(seats_conf) AS (
    VALUES
    ('{ "aircraft code": "SU9",
        "confs": [ { "fare conditions": "Business",
                    "rows": [ 1, 3 ],
                    "letters": [ "A", "C", "D", "F" ] },
                  { "fare conditions": "Economy",
                    "rows": [ 4, 20 ],
                    "letters": [ "A", "C", "D", "E", "F" ] }
                ]
    }'::jsonb),
    ('{ "aircraft code": "CN1",
        "confs": [ { "fare conditions": "Economy",
                    "rows": [ 1, 6 ],
                    "letters": [ "A", "B" ] }
                ]
    }'::jsonb)
)
SELECT 
    sc.seats_conf->>'aircraft code' AS aircraft_code,
    conf->>'fare conditions' AS fare_conditions,
    row || letter AS seat_no
FROM seats_confs AS sc
CROSS JOIN LATERAL jsonb_array_elements(sc.seats_conf->'confs') AS conf
CROSS JOIN LATERAL generate_series(
    (conf->'rows'->>0)::integer, 
    (conf->'rows'->>1)::integer
) AS rows(row)
CROSS JOIN LATERAL jsonb_array_elements_text(conf->'letters') AS letters(letter)
ORDER BY aircraft_code, row, letter;
```

<img src="./assets/2026-02-02 202324.jpg" width="700"> 

<img src="./assets/2026-02-02 202357.jpg" width="700"> 




