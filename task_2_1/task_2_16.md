# Домашнее задание 1

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 16

### Задание
С помощью запросов, разработанных для иерархий,
можно исследовать и граф общего вида
В разделе 2.3 «Массивы в общих табличных выражениях» (с. 49) мы рассмотрели
целый ряд запросов, позволяющих исследовать иерархическую структуру.
Задание. Попробуйте применить эти запросы к графу общего вида. При необходимости модифицируйте запросы. В качестве модельной системы можно рассмотреть, например, сеть автодорог региона. В ней могут существовать альтернативные пути между населенными пунктами, соседние населенные пункты
могут соединяться двумя дорогами (ребра-дубликаты на графе). Возможно, эти
избыточные пути в реальной дорожной сети можно было бы сделать запасными, выделять на их поддержание меньше ресурсов и т. п.

<div style="page-break-after: always;"></div>

### Решение

Граф общего вида отличается от дерева (иерархии) тем, что:

- Может иметь несколько корней 
- Возможны циклы
- Вершина может иметь несколько предков 
- Граф может быть несвязным

Cоздадим тестовый граф "дороги"

```sql
CREATE TABLE roads (
    point_from integer,
    point_to integer,
    road_name text,
    distance_km numeric,
    road_quality text,
    PRIMARY KEY (point_from, point_to)
);
```
Заполним тестовыми данными
```sql
INSERT INTO roads VALUES
    (1, 2, 'М-10', 50, 'хорошее'),
    (2, 1, 'М-10', 50, 'хорошее'),  -- обратная дорога
    (1, 3, 'А-100', 30, 'отличное'),
    (3, 1, 'А-100', 30, 'отличное'), -- обратная дорога
    (2, 3, 'Р-90', 40, 'удовлетворительное'),
    (3, 2, 'Р-90', 40, 'удовлетворительное'),
    (2, 4, 'М-11', 80, 'хорошее'),
    (4, 2, 'М-11', 80, 'хорошее'),
    (3, 5, 'А-101', 60, 'отличное'),
    (5, 3, 'А-101', 60, 'отличное'),
    (4, 5, 'Р-91', 70, 'удовлетворительное'),
    (5, 4, 'Р-91', 70, 'удовлетворительное'),
    (4, 6, 'М-12', 90, 'хорошее'),
    (6, 4, 'М-12', 90, 'хорошее'),
    (5, 6, 'А-102', 20, 'отличное'),
    (6, 5, 'А-102', 20, 'отличное'),
    (6, 1, 'К-1', 120, 'плохое'),  -- цикл
    (1, 6, 'К-1', 120, 'плохое');  -- цикл
```    
<div style="page-break-after: always;"></div>

<img src="./assets/2026-01-26 203028.jpg" width="700"> 

#### Составим запрос для поиск всех путей между двумя точками
```sql
WITH RECURSIVE all_paths(point_from, point_to, path, distance, transfers, cycle) AS (
    -- Начальные пути из A
    SELECT 
        r.point_from,
        r.point_to,
        ARRAY[r.point_from, r.point_to] AS path,
        r.distance_km AS distance,
        1 AS transfers,
        false AS cycle
    FROM roads r
    WHERE r.point_from = 1  -- стартовая точка
    
    UNION ALL
    
    -- Продолжение путей
    SELECT 
        ap.point_from,
        r.point_to,
        ap.path || r.point_to,
        ap.distance + r.distance_km,
        ap.transfers + 1,
        r.point_to = ANY(ap.path)
    FROM all_paths ap
    JOIN roads r ON r.point_from = ap.point_to
    WHERE NOT ap.cycle
      AND ap.transfers < 10  -- ограничение глубины
)
-- Все пути от точки 1 к точке 6
SELECT 
    transfers AS "Число перегонов",
    distance AS "Общее расстояние, км",
    array_to_string(path, ' → ') AS "Маршрут"
FROM all_paths
WHERE point_to = 6
  AND NOT cycle
ORDER BY distance, transfers;
```
<img src="./assets/2026-01-26 203319.jpg" width="700"> 
<img src="./assets/2026-01-26 203426.jpg" width="700"> 

#### Составим запрос поиска всех путей от начала иерархии

```sql
WITH RECURSIVE search_roads(point_from, point_to, road_name, distance_km, depth, path, cycle) AS (
    SELECT 
        r.point_from, 
        r.point_to, 
        r.road_name, 
        r.distance_km, 
        1,
        ARRAY[r.point_from, r.point_to],
        false
    FROM roads r
    WHERE point_from = 1
    UNION ALL
    SELECT 
        r.point_from, 
        r.point_to, 
        r.road_name, 
        r.distance_km, 
        sr.depth + 1,
        sr.path || r.point_to,
        r.point_to = ANY(sr.path)
    FROM search_roads sr, roads r
    WHERE r.point_from = sr.point_to
      AND NOT sr.cycle  -- ОСТАНОВКА если обнаружили цикл
      AND sr.depth < 6  -- ОГРАНИЧЕНИЕ глубины поиска
)
SELECT 
    depth AS "Число перегонов",
    array_to_string(path, ' → ') AS "Маршрут",
    road_name AS "Последняя дорога",
    distance_km AS "Длина последнего участка",
    CASE WHEN cycle THEN 'ЦИКЛ!' ELSE 'норма' END AS "Статус"
FROM search_roads
WHERE NOT cycle 
ORDER BY depth, path
LIMIT 10;  
```

<img src="./assets/2026-01-26 205518.jpg" width="700"> 

<img src="./assets/2026-01-26 205533.jpg" width="700"> 

<div style="page-break-after: always;"></div>

#### Составим запрос для проверки есть ли вообще "листья" в графе

```sql
SELECT 
    point,
    incoming,
    outgoing,
    total_connections,
    CASE 
        WHEN outgoing = 0 THEN 'ТУПИК (лист)'
        WHEN incoming = 0 THEN 'НАЧАЛЬНЫЙ ПУНКТ'
        ELSE 'ПРОМЕЖУТОЧНЫЙ'
    END AS type
FROM (
    SELECT 
        COALESCE(f.point, t.point) AS point,
        COALESCE(t.incoming, 0) AS incoming,
        COALESCE(f.outgoing, 0) AS outgoing,
        COALESCE(t.incoming, 0) + COALESCE(f.outgoing, 0) AS total_connections
    FROM (
        SELECT point_to AS point, COUNT(*) AS incoming
        FROM roads
        GROUP BY point_to
    ) t
    FULL OUTER JOIN (
        SELECT point_from AS point, COUNT(*) AS outgoing
        FROM roads
        GROUP BY point_from
    ) f ON t.point = f.point
) conn
ORDER BY total_connections;
```

<img src="./assets/2026-01-26 210413.jpg" width="700"> 

<div style="page-break-after: always;"></div>

#### Составим запрос выявление множественных путей

```sql
WITH RECURSIVE search_roads(point_from, point_to, road_name, distance_km, depth, path, total_distance, cycle) AS (
    SELECT r.point_from, r.point_to, r.road_name, r.distance_km, 1,
           ARRAY[r.point_from, r.point_to],
           r.distance_km,
           false
    FROM roads r
    WHERE r.point_from = 1
    UNION ALL
    SELECT r.point_from, r.point_to, r.road_name, r.distance_km, sr.depth + 1,
           sr.path || r.point_to,
           sr.total_distance + r.distance_km,
           r.point_to = ANY(sr.path)
    FROM search_roads sr, roads r
    WHERE r.point_from = sr.point_to
      AND NOT sr.cycle
      AND sr.depth < 6
),
multiple_paths(point_to) AS (
    SELECT point_to
    FROM search_roads
    GROUP BY point_to
    HAVING COUNT(DISTINCT path) > 1
)
SELECT 
    mp.point_to AS "Пункт назначения",
    COUNT(DISTINCT sr.path) AS "Количество разных маршрутов",
    MIN(sr.total_distance) AS "Минимальная дистанция",
    MAX(sr.total_distance) AS "Максимальная дистанция",
    ROUND(AVG(sr.total_distance), 2) AS "Средняя дистанция"
FROM multiple_paths mp
JOIN search_roads sr ON sr.point_to = mp.point_to
GROUP BY mp.point_to
ORDER BY "Количество разных маршрутов" DESC;
```

<img src="./assets/2026-01-26 204931.jpg" width="700"> 

<img src="./assets/2026-01-26 204958.jpg" width="700"> 

<div style="page-break-after: always;"></div>

#### Составим запрос поиска с учетом стоимости

```sql
WITH RECURSIVE search_roads(point_from, point_to, road_name, distance_km, road_quality, depth, path, total_distance, quality_score) AS (
    SELECT r.point_from, r.point_to, r.road_name, r.distance_km, r.road_quality, 1,
           ARRAY[r.point_from, r.point_to],
           r.distance_km,
           CASE r.road_quality
               WHEN 'отличное' THEN 1
               WHEN 'хорошее' THEN 2
               WHEN 'удовлетворительное' THEN 3
               WHEN 'плохое' THEN 5
               ELSE 4
           END
    FROM roads r
    WHERE r.point_from = 1
    UNION ALL
    SELECT r.point_from, r.point_to, r.road_name, r.distance_km, r.road_quality, sr.depth + 1,
           sr.path || r.point_to,
           sr.total_distance + r.distance_km,
           sr.quality_score + 
               CASE r.road_quality
                   WHEN 'отличное' THEN 1
                   WHEN 'хорошее' THEN 2
                   WHEN 'удовлетворительное' THEN 3
                   WHEN 'плохое' THEN 5
                   ELSE 4
               END
    FROM search_roads sr, roads r
    WHERE r.point_from = sr.point_to
      AND NOT r.point_to = ANY(sr.path)  -- избегаем циклов
      AND sr.depth < 5
)
SELECT 
    point_to AS "Куда",
    array_to_string(path, ' → ') AS "Маршрут",
    total_distance AS "Расстояние, км",
    quality_score AS "Оценка качества",
    total_distance * quality_score AS "Общий показатель"
FROM search_roads
WHERE point_to = 6  -- ищем все пути до пункта 6
ORDER BY "Общий показатель";  
```

<img src="./assets/2026-01-26 205155.jpg" width="700"> 

<img src="./assets/2026-01-26 205218.jpg" width="700"> 