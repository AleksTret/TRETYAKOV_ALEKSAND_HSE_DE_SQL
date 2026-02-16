# Домашнее задание 4

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 24

### Задание

Иллюстрация использования
системного каталога pg_depend

В разделе 5.2 «Функции и зависимости между объектами базы данных» (с. 288)
мы уже обращались к системному каталогу pg_depend. Давайте сделаем это еще
раз. Для экспериментов обратимся к перегруженным функциям get_lastname,
возвращающим фамилию пассажира. Они были созданы в упражнении 22
(с. 408).

Посмотрим, что записано о наших функциях в системном каталоге pg_proc (конечно, в выборку вошла лишь малая часть сведений). Воспользуемся типом
regprocedure, представленным в разделе документации 8.19 «Идентификаторы объектов». Он позволяет вывести имя функции вместе с типами данных ее
параметров.

```sql
SELECT oid, proname, proargtypes, proargtypes::regtype[], oid::regprocedure
FROM pg_proc
WHERE proname = 'get_lastname';
oid | proname | proargtypes | proargtypes | oid
−−−−−−−+−−−−−−−−−−−−−−+−−−−−−−−−−−−−+−−−−−−−−−−−−−−−−−−−+−−−−−−−−−−−−−−−−−−−−−−−−−
16684 | get_lastname | 25 | [0:0]={text} | get_lastname(text)
16686 | get_lastname | 25 25 | [0:1]={text,text} | get_lastname(text,text)
(2 строки)
```
Создадим индекс на таблице «Билеты» (tickets) по одной из этих функций:

```sql
CREATE INDEX tickets_func_idx ON tickets ( get_lastname( passenger_name ) );
CREATE INDEX
```

Зная имя индекса, выберем из системного каталога pg_depend все строки, описывающие зависимости этого индекса от других объектов базы данных:

```sql
SELECT
classid::regclass AS classname,
objid::regclass AS objname,
refclassid::regclass AS refclassname,
refobjid::regclass AS refobjname,
( SELECT attname
FROM pg_attribute
WHERE attrelid = refobjid
AND attnum = refobjsubid
),
CASE deptype
WHEN 'n' THEN 'normal'
WHEN 'a' THEN 'auto'
ELSE 'other'
END AS deptype
FROM pg_depend
WHERE objid::regclass::text = 'tickets_func_idx';
```

Для столбца refobjid мы использовали приведение типа refobjid::regclass.
Оно не работает для объекта, являющегося функцией.

В столбце attname выборки показано имя столбца таблицы tickets, от которой
зависит наш индекс. Обратите внимание, что хотя индекс был создан на основе
функции, здесь указывается столбец, который передавался ей в качестве аргумента в команде создания индекса. Номер этого столбца хранится в столбце
refobjsubid, а для вывода его имени мы воспользовались подзапросом к системному каталогу pg_attribute. Он представлен в разделе документации 51.7
«pg_attribute»

```text
classname | objname | refclassname | refobjname | attname | deptype
−−−−−−−−−−−+−−−−−−−−−−−−−−−−−−+−−−−−−−−−−−−−−+−−−−−−−−−−−−+−−−−−−−−−−−−−−−−+−−−−−−−−−
pg_class | tickets_func_idx | pg_class | tickets | | auto
pg_class | tickets_func_idx | pg_class | tickets | passenger_name | auto
pg_class | tickets_func_idx | pg_proc | 16684 | | normal
(3 строки)
```

Чтобы вместо OID функции get_lastname вывести ее имя, нужно в списке SELECT
запроса заменить тип regclass на regproc в операции приведения типа столбца
refobjid, а в предложение WHERE добавить условие, сужающее выборку.

```sql
SELECT
classid::regclass AS classname,
objid::regclass AS objname,
refclassid::regclass AS refclassname,
refobjid::regproc AS refobjname,
( SELECT attname
FROM pg_attribute
WHERE attrelid = refobjid
AND attnum = refobjsubid
),
CASE deptype
WHEN 'n' THEN 'normal'
WHEN 'a' THEN 'auto'
ELSE 'other'
END AS deptype
FROM pg_depend
WHERE objid::regclass::text = 'tickets_func_idx'
AND refclassid::regclass::text = 'pg_proc' \gx
−[ RECORD 1 ]+−−−−−−−−−−−−−−−−−−−−−−
classname | pg_class
objname | tickets_func_idx
refclassname | pg_proc
refobjname | bookings.get_lastname
attname |
deptype | normal
```

Задание 1. Модифицируйте первый запрос к системному каталогу pg_depend таким образом, чтобы он выводил не OID функции get_lastname, а ее имя.

Задание 2. Модифицируйте запросы к системному каталогу pg_depend, воспользовавшись стандартной функцией pg_describe_object, представленной в подразделе документации 9.27.5 «Функции получения информации и адресации
объектов». Эта функция выводит текстовое описание объекта базы данных.

Задание 3. Обратитесь к системному каталогу pg_index (см. раздел документации 51.26 «pg_index»). В столбце indexprs хранятся сведения об атрибутах
индекса, не являющихся простыми ссылками на столбцы. Эти сведения представлены в виде деревьев специальной структуры. Здесь можно увидеть и OID
функции, на основе которой построен индекс.



<div style="page-break-after: always;"></div>

### Решение

Создаем функцию

```sql
CREATE OR REPLACE FUNCTION get_lastname(fullname text)
RETURNS text AS $$
    SELECT substr(fullname, strpos(fullname, ' ') + 1);
$$ LANGUAGE sql IMMUTABLE SECURITY INVOKER;
```

Проверяем

```sql
SELECT oid, proname, proargtypes, proargtypes::regtype[], oid::regprocedure
FROM pg_proc
WHERE proname = 'get_lastname';
```

<img src="./assets/2026-02-16 164922.jpg" width="700"> 

Создаем индекс `tickets_func_idx` по `get_lastname(passenger_name)`

<img src="./assets/2026-02-16 165048.jpg" width="700"> 

Модифицируем первый запрос 

```sql
SELECT
classid::regclass AS classname,
objid::regclass AS objname,
refclassid::regclass AS refclassname,
refobjid::regproc AS refobjname,
( SELECT attname
FROM pg_attribute
WHERE attrelid = refobjid
AND attnum = refobjsubid
),
CASE deptype
WHEN 'n' THEN 'normal'
WHEN 'a' THEN 'auto'
ELSE 'other'
END AS deptype
FROM pg_depend
WHERE objid::regclass::text = 'tickets_func_idx';
```

В третьей строке refobjname теперь get_lastname (имя функции), а не OID.

<img src="./assets/2026-02-16 165301.jpg" width="700"> 

Используем функцию `pg_describe_object`

```sql
SELECT 
    classid::regclass,
    objid::regclass,
    refclassid::regclass,
    refobjid,
    pg_describe_object(refclassid, refobjid, refobjsubid) AS description,
    deptype
FROM pg_depend
WHERE objid::regclass::text = 'tickets_func_idx';
```

`pg_describe_object` выдал понятные описания: таблица `tickets`, столбец `passenger_name`, функция `get_lastname(text)`

<img src="./assets/2026-02-16 165412.jpg" width="700"> 

Посмотрим что хранится в `indexprs` для индекса `tickets_func_idx`:

```sql
SELECT indexprs FROM pg_index WHERE indexrelid = 'tickets_func_idx'::regclass;
```

`funcid 43106` — OID функции `get_lastname`.
`args` — аргумент функции: `VAR :varattno 4` (столбец с номером 4 таблицы `tickets` — это `passenger_name`).

<img src="./assets/2026-02-16 165652.jpg" width="700"> 