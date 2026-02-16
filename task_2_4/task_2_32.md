# Домашнее задание 4

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 32

### Задание
Сортировка массивов
разной размерности

В разделе документации 9.19 «Функции и операторы для работы с массивами»
представлено много разнообразных функций для обработки массивов, однако
функции сортировки среди них нет. Давайте ее напишем, но сначала уточним,
что мы понимаем под сортировкой массива. В случае одномерного массива
речь идет о сортировке его элементов. Элементами двухмерного массива являются одномерные массивы, поэтому сначала сортируются элементы каждого
одномерного массива, а потом — сами одномерные массивы (в лексикографическом порядке). Аналогично понимается и сортировка трехмерных массивов,
учитывая, что их элементы — двухмерные массивы.
Начнем с сортировки одномерного массива.

```sql
CREATE OR REPLACE FUNCTION array_sort( arr integer[] )
RETURNS integer[] AS
$$
SELECT array_agg( elem ORDER BY elem ) AS sorted_array
FROM unnest( arr ) AS elem;
$$ LANGUAGE sql IMMUTABLE;
CREATE FUNCTION
Вот что получается:
SELECT *
FROM array_sort( ARRAY[ 8, 3, 1, 4, 2, 9 ] );
array_sort
−−−−−−−−−−−−−−−
{1,2,3,4,8,9}
(1 строка)
```

Для сортировки двухмерного массива можно воспользоваться функцией, представленной в разделе документации 9.26 «Функции, возвращающие множества»: generate_subscripts. Она формирует в виде таблицы список действительных индексов в указанном измерении массива. В предложении FROM подзапроса sort_subarrays получим все комбинации обоих индексов, а затем с их помощью сформируем одномерные массивы и отсортируем каждый из них. Для
получения окончательного результата соберем в двухмерный массив отсортированные одномерные массивы.

```sql
CREATE OR REPLACE FUNCTION array_sort_2d( arr integer[][] )
RETURNS integer[][] AS
$$
WITH sort_subarrays AS
( SELECT
array_agg( arr[ i ][ j ] ORDER BY arr[ i ][ j ] ) AS subarray
FROM
generate_subscripts( arr, 1 ) AS i,
generate_subscripts( arr, 2 ) AS j
GROUP BY i
)
SELECT array_agg( subarray ORDER BY subarray )
FROM sort_subarrays;
$$
LANGUAGE sql IMMUTABLE;
CREATE FUNCTION
Проверяем функцию в работе:
SELECT *
FROM array_sort_2d(
ARRAY [
[ 12, 3 ], [ 4, 9 ],
[ 11, 7 ], [ 17, 3 ],
[ 8, 14 ], [ 22, 4 ]
]
);
array_sort_2d
−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−
{{3,12},{3,17},{4,9},{4,22},{7,11},{8,14}}
(1 строка)
```

Задание. Напишите функцию сортировки трехмерных массивов. Начало одного
из вариантов может быть таким:

```sql
CREATE OR REPLACE FUNCTION array_sort_3d( arr integer[][][] )
RETURNS integer[][][] AS
$$
WITH sort_subarrays_3rd_dim AS
( SELECT
i,
j,
array_agg( arr[ i ][ j ][ k ] ORDER BY arr[ i ][ j ][ k ] ) AS subarray_3rd_dim
FROM
generate_subscripts( arr, 1 ) AS i,
generate_subscripts( arr, 2 ) AS j,
generate_subscripts( arr, 3 ) AS k
GROUP BY i, j
),
...
```

Ожидается получить такой результат:

```sql
SELECT *
FROM array_sort_3d(
ARRAY [
[ [ 12, 3 ], [ 4, 9 ] ],
[ [ 11, 7 ], [ 17, 3 ] ],
[ [ 8, 14 ], [ 22, 4 ] ]
]
);
array_sort_3d
−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−
{{{3,12},{4,9}},{{3,17},{7,11}},{{4,22},{8,14}}}
(1 строка)
```

<div style="page-break-after: always;"></div>

### Решение

```sql
CREATE OR REPLACE FUNCTION array_sort_3d(arr integer[][][])
RETURNS integer[][][] AS $$
WITH step1 AS (
    SELECT i, j, array_agg(arr[i][j][k] ORDER BY arr[i][j][k]) AS sorted_k
    FROM generate_subscripts(arr, 1) i,
         generate_subscripts(arr, 2) j,
         generate_subscripts(arr, 3) k
    GROUP BY i, j
),
step2 AS (
    SELECT i, array_agg(sorted_k ORDER BY sorted_k) AS sorted_j
    FROM step1
    GROUP BY i
)
SELECT array_agg(sorted_j ORDER BY sorted_j)
FROM step2;
$$ LANGUAGE sql IMMUTABLE;
```

```sql
SELECT array_sort_3d(
    ARRAY [
        [ [12, 3], [4, 9] ],
        [ [11, 7], [17, 3] ],
        [ [8, 14], [22, 4] ]
    ]
);
```

<img src="./assets/2026-02-16 170226.jpg" width="700"> 