# Домашнее задание 5

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 7

### Задание
Самые крупные самолеты в нашей авиакомпании — это `Boeing 777-300`. 
Выяснить, между какими парами городов они летают, поможет запрос:
```sql
SELECT DISTINCT departure_city, arrival_city
FROM routes r
JOIN aircrafts a ON r.aircraft_code = a.aircraft_code
WHERE a.model = 'Boeing 777-300'
ORDER BY 1;

departure_city  | arrival_city
----------------+--------------
Екатеринбург    | Москва
Москва          | Екатеринбург
Москва          | Новосибирск
Москва          | Пермь
Москва          | Сочи
Новосибирск     | Москва
Пермь           | Москва
Сочи            | Москва
(8 строк)
```
К сожалению, в этой выборке информация дублируется. Пары городов приведены по два раза: для рейса «туда» и для рейса «обратно». Модифицируйте запрос
таким образом, чтобы каждая пара городов была выведена только один раз:
```sql
departure_city  | arrival_city
----------------+--------------
Москва          | Екатеринбург
Новосибирск     | Москва
Пермь           | Москва
Сочи            | Москва
(4 строки)
```
### Решение

Для "склеивания" пар городов можно использовать функции `LEAST()` и `GREATEST()`.

- `LEAST()` возвращает меньший из двух городов (по алфавиту)
- `GREATEST()` возвращает больший из двух городов (по алфавиту)
- `DISTINCT` убирает дубликаты

```sql
SELECT DISTINCT 
    GREATEST(departure_city, arrival_city) AS departure_city,
    LEAST(departure_city, arrival_city) AS arrival_city
FROM routes r
JOIN aircrafts a ON r.aircraft_code = a.aircraft_code
WHERE a.model = 'Boeing 777-300'
ORDER BY 1, 2;
```
<img src="./assets/ex_7/2025-11-10 163851.jpg" width="700">

Аналогичный результат можно получить используя `CASE WHEN`

```sql
SELECT DISTINCT
    CASE WHEN arrival_city > departure_city 
         THEN arrival_city ELSE departure_city  
    END AS city1,
    CASE WHEN arrival_city > departure_city
         THEN departure_city ELSE arrival_city 
    END AS city2
FROM routes r
JOIN aircrafts a ON r.aircraft_code = a.aircraft_code
WHERE a.model = 'Boeing 777-300'
ORDER BY 1, 2;
```
<img src="./assets/ex_7/2025-11-10 164557.jpg" width="700">

Или так называемый "`SELF JOIN`"

```sql
SELECT DISTINCT
    r1.arrival_city,
    r1.departure_city
FROM routes r1
JOIN aircrafts a1 ON r1.aircraft_code = a1.aircraft_code
LEFT JOIN routes r2 ON r1.departure_city = r2.arrival_city 
                    AND r1.arrival_city = r2.departure_city
                    AND r1.departure_city > r1.arrival_city
WHERE a1.model = 'Boeing 777-300'
  AND r2.departure_city IS NULL
ORDER BY 1, 2;
```
<img src="./assets/ex_7/2025-11-10 165655.jpg" width="700">