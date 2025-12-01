# Домашнее задание 11

**Выполнил - Третьяков Александр Юрьевич**

### Задание

Полнотекстовый поиск.
Задание выполняется на основе презентации 10 «Полнотекстовый поиск» и главы 12
документации на Постгрес https://postgrespro.ru/docs/postgresql/18/textsearch

**Задание.**

Придумать и реализовать пример использования полнотекстового поиска,
аналогичный (можно более простой или более сложный) тому примеру с библиотечным
каталогом, который был приведен в презентации. Можно использовать исходные тексты,
приведенные в презентации: https://edu.postgrespro.ru/sqlprimer/sqlprimer-2019-msu-10.tgz

### Решение

Создадим таблицу и заполним данными

```sql
CREATE TABLE books
    ( book_id integer PRIMARY KEY,
    book_description text
    );
```

```sql
COPY books FROM '/tmp/books3.txt';
```

```sql
ALTER TABLE books ADD COLUMN ts_description tsvector;
```

```sql
UPDATE books
SET ts_description = to_tsvector( 'russian', book_description );
```

<img src="./assets/2025-12-01 184832.jpg" width="700">

Создадим индекс

```sql
CREATE INDEX books_idx ON books USING GIN ( ts_description );
```

<img src="./assets/2025-12-01 185238.jpg" width="700">

Выполним простой запрос для поиска книг по автору

```sql
SELECT book_id, book_description
FROM books
WHERE ts_description @@ to_tsquery('Шилдт');
```

<img src="./assets/2025-12-01 190052.jpg" width="700">

Выполним поиск по нескольким темам

```sql
SELECT book_id,
       LEFT(book_description, 100) as preview
FROM books
WHERE ts_description @@ to_tsquery('база & данных | SQL | MySQL');
```

<img src="./assets/2025-12-01 191117.jpg" width="700">

Попробуем сравнить `LIKE` и полнотекстовый поиск

```sql
SELECT 'FTS' as method, COUNT(*) 
    FROM books 
    WHERE ts_description @@ to_tsquery('Java')

UNION ALL

SELECT 'LIKE' as method, COUNT(*) 
    FROM books 
    WHERE book_description ILIKE '%Java%';
```

<img src="./assets/2025-12-01 191605.jpg" width="700">

Полнотекстовый поиск (`FTS`) нашел меньше книг (9)
- Ищет именно слово "Java" как отдельную лексему
- Учитывает морфологию, стемминг
- Более строгий и точный поиск
- Может не находить "Java" в составе других слов (например, "JavaScript")

`LIKE` поиск нашел больше книг (14)
- Ищет подстроку "Java" в любом месте текста
- Менее точный, но более чувствительный
- Находит "Java" везде

Посмотрим что именно нашел `LIKE`

```sql
SELECT book_id, LEFT(book_description, 120) 
FROM books 
WHERE book_description ILIKE '%Java%';
```

<img src="./assets/2025-12-01 191911.jpg" width="700">

Посмотрим что нашел `FTS`

```sql
SELECT book_id, LEFT(book_description, 120) 
FROM books 
WHERE ts_description @@ to_tsquery('Java');
```

<img src="./assets/2025-12-01 192037.jpg" width="700">

Таким образом `FTS` подходит для точного поиска, a `LIKE` для максимально полного поиска.

Составим запрос на поиск самых подходящих книг по Java или C#, которые изданы Питером в 2017 или 2018 году, и отсортируем по степени соответствия.

```sql
SELECT book_id,
       LEFT(book_description, 100) as preview,
       ts_rank(ts_description, 
            to_tsquery('Java | C# | Питер | 2017 | 2018')) as score
FROM books
WHERE ts_description @@ to_tsquery('(Java | C#) & Питер & (2017 | 2018)')
ORDER BY score DESC;
```

<img src="./assets/2025-12-01 193841.jpg" width="700">