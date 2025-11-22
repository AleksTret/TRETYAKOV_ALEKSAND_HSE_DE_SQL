# Домашнее задание 9

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 3

### Задание
Самостоятельно выполните команду `EXPLAIN` для запроса, содержащего общее
табличное выражение (`CTE`). Посмотрите, на каком уровне находится узел плана, отвечающий за это выражение, как он оформляется. Учтите, что общие табличные выражения всегда материализуются, т. е. вычисляются однократно и
результат их вычисления сохраняется в памяти, а затем все последующие обращения в рамках запроса направляются уже к этому материализованному результату.

### Решение

Возьме для примера следующий запрос и выполним его с явным указание материализации и без

**С явным указание MATERIALIZED**

```sql
EXPLAIN ANALYZE
WITH cte AS MATERIALIZED (
    SELECT flight_id, COUNT(*) as cnt
    FROM ticket_flights 
    GROUP BY flight_id
)
SELECT f.flight_no, cte.cnt
FROM cte
JOIN flights f ON cte.flight_id = f.flight_id
WHERE cte.cnt > 100;
```

<img src="./assets/ex_3/2025-11-21 211442.jpg" width="900">

**Теперь выполним без явного указания MATERIALIZED**

```sql
EXPLAIN ANALYZE
WITH cte AS (
    SELECT flight_id, COUNT(*) as cnt
    FROM ticket_flights 
    GROUP BY flight_id
)
SELECT f.flight_no, cte.cnt
FROM cte
JOIN flights f ON cte.flight_id = f.flight_id
WHERE cte.cnt > 100;
```

<img src="./assets/ex_3/2025-11-21 212806.jpg" width="900">

**Анализ планов выполнения**

Вычисление `CTE` (материализация)    

```
Hash Join
  CTE cte
    -> Finalize HashAggregate
         -> Gather
              -> Partial HashAggregate
                   -> Parallel Seq Scan on ticket_flights
  -> CTE Scan on cte
        Filter: (cnt > 100)
  -> Hash
        -> Seq Scan on flights f
```     

`CTE` БЕЗ `MATERIALIZED` 

```
Hash Join
  -> Seq Scan on flights f
  -> Hash
        -> Subquery Scan on cte
              -> Finalize HashAggregate
                    Filter: (count(*) > 100)
                    -> Gather
                          -> Partial HashAggregate
                                -> Parallel Seq Scan on ticket_flights
```  

| Параметр            | Без MATERIALIZED | С MATERIALIZED  |
|---------------------|------------------|----------------|
| Время выполнения     | 3941 ms          | 4110 ms        |
| Память хэша         | 162 kB           | 1936 kB        |
| Подход к фильтрации  | Во время агрегации | После материализации |


С `MATERIALIZED` (явно):

- Агрегация всех 22,226 строк
- Материализация полного результата
- Фильтр `cnt` > 100 отбрасывает 19,964 строк
- Строим хэш из 2,262 строк
- `JOIN` с `flights`

Без `MATERIALIZED`(оптимизированно):

- Агрегация + фильтр `count(*)` > 100 вместе
- Сразу получаем 2,262 строки
- Строим маленький хэш (162 kB)
- `JOIN` с `flights`

Оптимизатор `PostgreSQL` без явного указания выбрал более эффективную стратегию - совместил агрегацию и фильтрацию, избежав материализации лишних данных.


Основные выводы
1. `CTE` НЕ всегда материализуются
 - Без `MATERIALIZED`: Оптимизатор может встроить `CTE` в основной запрос (второй пример)
 - С `MATERIALIZED`: Гарантированная материализация (первый пример)

2. Уровень узла `CTE` в плане
- При материализации: `CTE` находится на верхнем уровне плана
- Оформляется как отдельный блок `CTE имя_cte`
- Вычисляется до основных операций `JOIN`

