# Домашнее задание 1

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 13

### Задание

В массив можно «собрать» не только путь,
но и стоимости ребер вдоль этого пути
В разделе 2.3 «Массивы в общих табличных выражениях» (с. 49) был приведен запрос, выводящий неуникальные пути от начала иерархии к ее вершинам,
а также общие стоимости этих путей. Модифицируйте запрос таким образом,
чтобы он выводил не только суммарные стоимости выбранных путей, но также
и стоимости ребер, образующих эти пути, в виде массивов. Это может выглядеть примерно так:
```text
vertex_to  | path         | path_values       | total_value
−−−−−−−−−−−+−−−−−−−−−−−−−−+−−−−−−−−−−−−−−−−−−−+−−−−−−−−−−−−−
9          | {1,2,4,9}    | {4.7,6.3,5.7}     | 16.7
9          | {1,2,5,9}    | {4.7,1.9,3.3}     | 9.9
13         | {1,2,4,9,13} | {4.7,6.3,5.7,2.1} | 18.8
13         | {1,2,5,9,13} | {4.7,1.9,3.3,2.1} | 12.0
(4 строки)
```
Указание. Чтобы в таблице «Иерархия» (hier) образовались неуникальные пути,
не забудьте предварительно добавить в нее еще одну строку (как это было сделано в тексте главы):
```sql
INSERT INTO hier VALUES ( 4, 9, 5.7 );
```
В противном случае запрос не вернет ни одной строки.

<div style="page-break-after: always;"></div>

### Решение

Создадим таблицу для работы и заполним ее данными

```sql
CREATE TABLE hier
( vertex_from integer,
  vertex_to integer,
  data numeric,
  PRIMARY KEY ( vertex_from, vertex_to )
);

COPY hier FROM STDIN WITH ( format csv );
>> 1,2,4.7
1,3,5.6
2,4,6.3
2,5,1.9
3,6,3.5
3,7,2.8
3,8,4.1
5,9,3.3
5,10,4.5
6,11,2.7
6,12,1.3
9,13,2.1
\.
```

<img src="./assets/2026-01-26 200557.jpg" width="700">

<div style="page-break-after: always;"></div>

Выполним вставку неуникального пути

```sql
INSERT INTO hier VALUES ( 4, 9, 5.7 );
```

<img src="./assets/2026-01-26 200933.jpg" width="700">

Исходный запрос 

```sql
WITH RECURSIVE search_hier( vertex_from, vertex_to, data, depth, path, total_value ) AS
( SELECT h.vertex_from, h.vertex_to, h.data, 1,
    ARRAY[ h.vertex_from, h.vertex_to ], h.data
  FROM hier h
  WHERE h.vertex_from = 1
  UNION ALL
  SELECT h.vertex_from, h.vertex_to, h.data, sh.depth + 1,
    sh.path || h.vertex_to, sh.total_value + h.data
  FROM search_hier sh,
    hier h
  WHERE h.vertex_from = sh.vertex_to
),
nonunique_paths ( vertex_to ) AS
( SELECT vertex_to
  FROM search_hier
  GROUP BY vertex_to
  HAVING count( * ) > 1
)
SELECT nup.vertex_to, sh.path, sh.total_value
FROM nonunique_paths nup
JOIN search_hier sh ON sh.vertex_to = nup.vertex_to
ORDER BY nup.vertex_to, sh.path;
```

<img src="./assets/2026-01-26 200734.jpg" width="700">

Модифицируем исходный запрос и проверим результат

```sql
WITH RECURSIVE search_hier(vertex_from, vertex_to, data, depth, path, total_value, path_values) AS (
    SELECT 
        h.vertex_from, 
        h.vertex_to, 
        h.data, 
        1, 
        ARRAY[h.vertex_from, h.vertex_to],  
        h.data,                              
        ARRAY[h.data]                       
    FROM hier h
    WHERE h.vertex_from = 1
    
    UNION ALL
    
    SELECT 
        h.vertex_from, 
        h.vertex_to, 
        h.data, 
        sh.depth + 1, 
        sh.path || h.vertex_to,            
        sh.total_value + h.data,            
        sh.path_values || h.data     
    FROM search_hier sh
    JOIN hier h ON h.vertex_from = sh.vertex_to
),
nonunique_paths(vertex_to) AS (
    SELECT vertex_to
    FROM search_hier
    GROUP BY vertex_to
    HAVING COUNT(*) > 1
)
SELECT 
    nup.vertex_to,
    sh.path,
    sh.path_values,
    sh.total_value
FROM nonunique_paths nup
JOIN search_hier sh ON sh.vertex_to = nup.vertex_to
ORDER BY nup.vertex_to, sh.path;
```

<img src="./assets/2026-01-26 201521.jpg" width="700">

<img src="./assets/2026-01-26 201803.jpg" width="700">

- Добавлен новый столбец `path_values` в `CTE` `search_hier`

- В нерекурсивной части: `path_values` инициализируется как массив с одним элементом `ARRAY[h.data]`

- В рекурсивной части: к массиву `path_values` добавляется стоимость очередного ребра `sh.path_values || h.data`

- В основном запросе: теперь выводится не только `path` и `total_value`, но и `path_values`