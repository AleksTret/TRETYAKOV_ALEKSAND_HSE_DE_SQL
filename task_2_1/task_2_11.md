# Домашнее задание 1

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 11

### Задание

Можно ли ускорить поиск маршрута
между двумя городами?
В разделе 2.3 «Массивы в общих табличных выражениях» (с. 49) был рассмотрен поиск маршрута между двумя городами, возможно не связанными прямым
рейсом. Предложенный запрос успешно решал поставленную задачу, однако
его выполнение можно значительно ускорить. Опишем идею одного из возможных способов.
Обратите внимание, что объект «Маршруты» (`routes`) является представлением. При этом рекурсивное общее табличное выражение неоднократно обращается к нему, отбирая уникальные строки с помощью предложения `DISTINCT`
ON. Предположительно выполнение запроса можно ускорить, используя вместо
представления таблицу, содержащую только уникальные пары городов отправления и прибытия. К сожалению, у нас нет такой таблицы, но, к счастью, у нас
есть общие табличные выражения.
Задание. Реализуйте описанную идею. Сравните время выполнения обоих вариантов запроса.
Указание. Общее табличное выражение, формирующее уникальные пары городов отправления и прибытия, можно сделать вложенным.
```sql
WITH RECURSIVE search_route( city_from, city_to, transfers, route ) AS
( WITH unique_routes AS
    ( SELECT ...
    FROM routes
)
...
```
Однако можно избежать вложенности, поместив подзапрос unique_routes после
подзапроса `search_route`. Такие ссылки «вперед» допустимы, если рекурсивное
общее табличное выражение идет первым.


<div style="page-break-after: always;"></div>

### Решение

Исходный запрос из книги:
```sql
WITH RECURSIVE search_route( city_from, city_to, transfers, route ) AS
( 
  SELECT DISTINCT ON ( arrival_city )
    departure_city, arrival_city, 1,
    ARRAY[ departure_city, arrival_city ]
  FROM routes
  WHERE departure_city = 'Хабаровск'
  
  UNION ALL
  
  SELECT DISTINCT ON ( sr.route || r.arrival_city )
    r.departure_city, r.arrival_city, transfers + 1,
    sr.route || r.arrival_city
  FROM search_route AS sr
  JOIN routes AS r ON r.departure_city = sr.city_to
  WHERE sr.city_to <> 'Сочи'
    AND sr.transfers <= 3
    AND r.arrival_city <> ALL( sr.route )
)
SELECT 
  transfers AS "Число перелетов", 
  array_to_string( route, ' - ' ) AS "Маршрут"
FROM search_route
WHERE city_to = 'Сочи'
ORDER BY transfers, route;
```
Отключим вывод и проверим время работы исходного запроса ~71 ms.
```sql
\o /dev/null
\timing on
```

<img src="./assets/2026-01-26 191332.jpg" width="700">

Реализуем идею из задания и проверим время выполнения
```sql
WITH RECURSIVE search_route(city_from, city_to, transfers, route) AS (
  WITH unique_routes AS (
    SELECT DISTINCT ON (departure_city, arrival_city)
      departure_city, 
      arrival_city
    FROM routes
  )
  SELECT 
    departure_city, 
    arrival_city, 
    1,
    ARRAY[departure_city, arrival_city]
  FROM unique_routes
  WHERE departure_city = 'Хабаровск'
  
  UNION ALL
  
  SELECT 
    sr.city_from,
    ur.arrival_city,
    sr.transfers + 1,
    sr.route || ur.arrival_city
  FROM search_route AS sr
  JOIN unique_routes AS ur ON ur.departure_city = sr.city_to
  WHERE sr.city_to <> 'Сочи'
    AND sr.transfers <= 3
    AND ur.arrival_city <> ALL(sr.route)
)
SELECT 
  transfers AS "Число перелетов", 
  array_to_string(route, ' - ') AS "Маршрут"
FROM search_route
WHERE city_to = 'Сочи'
ORDER BY transfers, route;
```
<img src="./assets/2026-01-26 192922.jpg" width="700">

Время выполнения составляет ~30 ms. Что в приблизительно в 2 раза быстрее, чем изначальный запрос.

### Вывод:

Оптимизированный запрос будет работать быстрее, поскольку:

- `unique_routes` вычисляется один раз - он создается до начала рекурсии и кэшируется

- Меньше данных на каждом шаге рекурсии - вместо всех рейсов (routes) только уникальные пары городов

- Нет `DISTINCT ON` в рекурсивной части - дорогая операция на каждом шаге

- Упрощенная структура данных - работа с 2 колонками вместо сложного представления routes