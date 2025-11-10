# Домашнее задание 5

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 13

### Задание
Ответить на вопрос о том, каковы максимальные и минимальные цены билетов
на все направления, может такой запрос:
```sql
SELECT f.departure_city, f.arrival_city,
max( tf.amount ), min( tf.amount )
FROM flights_v f
JOIN ticket_flights tf ON f.flight_id = tf.flight_id
GROUP BY 1, 2
ORDER BY 1, 2;

departure_city       | arrival_city        | max       | min
---------------------+---------------------+-----------+----------
Абакан               | Москва              | 101000.00 | 33700.00
Абакан               | Новосибирск         | 5800.00   | 5800.00
Абакан               | Томск               | 4900.00   | 4900.00
Анадырь              | Москва              | 185300.00 | 61800.00
Анадырь              | Хабаровск           | 92200.00  | 30700.00
...
Якутск               | Мирный              | 8900.00   | 8100.00
Якутск               | Санкт-Петербург     | 145300.00 | 48400.00
(367 строк)
```

А как выявить те направления, на которые не было продано ни одного билета?
Один из вариантов решения такой: если на рейсы, отправляющиеся по какомуто направлению, не было продано ни одного билета, то максимальная и минимальная цены будут равны `NULL`. Нужно получить выборку в таком виде:
```sql
departure_city       | arrival_city        | max       | min
---------------------+---------------------+-----------+----------
Абакан               | Архангельск         |           |
Абакан               | Грозный             |           |
Абакан               | Кызыл               |           |
Абакан               | Москва              | 101000.00 | 33700.00
Абакан               | Новосибирск         | 5800.00   | 5800.00
...
```
Модифицируйте запрос, приведенный выше
### Решение
Чтобы выявить направления, на которые не было продано ни одного билета, нужно использовать `LEFT JOIN` вместо `INNER JOIN`

 То есть `LEFT JOIN` дополнит все строки из `flights_v` данными из `ticket_flights` не удаляя из итоговой выборки те для которых не нашлось проданных билетов.


```sql
SELECT 
    f.departure_city, 
    f.arrival_city,
    MAX(tf.amount) AS max,
    MIN(tf.amount) AS min
FROM flights_v f
LEFT JOIN ticket_flights tf ON f.flight_id = tf.flight_id
GROUP BY f.departure_city, f.arrival_city
ORDER BY f.departure_city, f.arrival_city
LIMIT 5;
```
<img src="./assets/ex_13/2025-11-10 174222.jpg" width="700">

Аналогичный результат можно получить используя объединение `UNION ALL`

```sql
-- Направления с билетами
SELECT 
    f.departure_city, 
    f.arrival_city,
    MAX(tf.amount) AS max,
    MIN(tf.amount) AS min
FROM flights_v f
JOIN ticket_flights tf ON f.flight_id = tf.flight_id
GROUP BY f.departure_city, f.arrival_city

UNION ALL

-- Направления без билетов
SELECT 
    f.departure_city, 
    f.arrival_city,
    NULL AS max,
    NULL AS min
FROM flights_v f
WHERE NOT EXISTS (
    SELECT 1 FROM ticket_flights tf WHERE tf.flight_id = f.flight_id
)
GROUP BY f.departure_city, f.arrival_city

ORDER BY departure_city, arrival_city;
LIMIT 5;
```

<img src="./assets/ex_13/2025-11-10 180239.jpg" width="700">