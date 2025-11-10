# Домашнее задание 5

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 9

### Задание
Для ответа на вопрос, сколько рейсов выполняется из Москвы в Санкт-Петербург, можно написать совсем простой запрос:
```sql
SELECT count(*)
FROM routes
WHERE departure_city = 'Москва'
AND arrival_city = 'Санкт-Петербург';

count
-------
12
(1 строка)
```
А с помощью какого запроса можно получить результат в таком виде?
```sql
departure_city  | arrival_city    | count
----------------+-----------------+-------
Москва          | Санкт-Петербург | 12
(1 строка)
```
### Решение

Самый простой способ - с явным указанием значений

```sql
SELECT 
    'Москва' AS departure_city,
    'Санкт-Петербург' AS arrival_city,
    COUNT(*) AS count
FROM routes
WHERE departure_city = 'Москва'
AND arrival_city = 'Санкт-Петербург';
```
<img src="./assets/ex_9/2025-11-10 170418.jpg" width="700">

С использованием `GROUP BY`

```sql
SELECT 
    departure_city,
    arrival_city,
    COUNT(*) AS count
FROM routes
WHERE departure_city = 'Москва'
AND arrival_city = 'Санкт-Петербург'
GROUP BY departure_city, arrival_city;
```
<img src="./assets/ex_9/2025-11-10 170558.jpg" width="700">

Общее решение, без условий на города вылета и прибытия

```sql
SELECT 
    departure_city,
    arrival_city,
    COUNT(*) AS count
FROM routes
GROUP BY departure_city, arrival_city
ORDER BY count DESC LIMIT 5;
```
<img src="./assets/ex_9/2025-11-10 172722.jpg" width="700">

Так же можно воспользоваться решением из предыдущей задачи №7 и посчтитать "туда" и "обратно" как один маршрут между городами
```sql
SELECT 
    LEAST(departure_city, arrival_city) AS departure_city,
    GREATEST(departure_city, arrival_city) AS arrival_city,
    COUNT(*) AS count
FROM routes
WHERE departure_city < arrival_city  
GROUP BY 
    LEAST(departure_city, arrival_city),
    GREATEST(departure_city, arrival_city)
ORDER BY count DESC
LIMIT 5;
```
<img src="./assets/ex_9/2025-11-10 173031.jpg" width="700">