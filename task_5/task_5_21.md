# Домашнее задание 5

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 21

### Задание
В тексте главы был приведен запрос, выводящий список городов, в которые нет
рейсов из Москвы.
```sql
SELECT DISTINCT a.city
    FROM airports a
    WHERE NOT EXISTS (
        SELECT * FROM routes r
        WHERE r.departure_city = 'Москва'
        AND r.arrival_city = a.city
        )
    AND a.city <> 'Москва'
    ORDER BY city;
```
Можно предложить другой вариант, в котором используется одна из операций
над множествами строк: объединение, пересечение или разность.
Вместо знака `«?»` поставьте в приведенном ниже запросе нужное ключевое слово — `UNION`, `INTERSECT` или `EXCEPT` — и обоснуйте ваше решение
```sql
SELECT city
FROM airports
WHERE city <> 'Москва'
?
SELECT arrival_city
FROM routes
WHERE departure_city = 'Москва'
ORDER BY city;
```
### Решение
В этом запросе нужно использовать оператор `EXCEPT`
```sql
SELECT city
FROM airports
WHERE city <> 'Москва'
EXCEPT
SELECT arrival_city
FROM routes
WHERE departure_city = 'Москва'
ORDER BY city;
```
<img src="./assets/ex_21/2025-11-10 205600.jpg" width="700">

Логика работы запроса:
- Первое множество - все города с аэропортами, кроме Москвы: 
```sql 
SELECT city FROM airports WHERE city <> 'Москва'
```
- Второе множество - города, в которые ЕСТЬ рейсы из Москвы:
```sql
SELECT arrival_city FROM routes WHERE departure_city = 'Москва'
```
- `EXCEPT` - вычитает из всех городов (кроме Москвы) те города, в которые есть рейсы из Москвы

Почему не другие операторы:
- `UNION` - объединил бы оба списка, получив ВСЕ города из обоих наборов
- `INTERSECT` - нашел бы пересечение (города, в которые ЕСТЬ рейсы из Москвы)

Преимущества этого варианта с использованием `EXCEPT`
Более декларативный стиль
- Четко выражает логику "все города кроме..."
- Легче читается и понимается
- Хорошая производительность