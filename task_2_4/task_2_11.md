# Домашнее задание 4

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 11

### Задание
Когда в предложении FROM
несколько табличных функций
В разделе 5.5 «Конструкция LATERAL и функции» (с. 309) мы рассматривали запрос, в предложении FROM которого была всего одна такая конструкция.Давайте
рассмотрим ситуацию, в которой этих конструкций будет две.

На принятие решения руководством авиакомпании о сохранении тех или иных
маршрутов влияет в том числе их востребованность у пассажиров. Она зависит от разных факторов: от исторически сложившихся связей между городами,
от стоимости авиабилетов, от наличия других транспортных возможностей, от
численности населения городов и т. д. Интегральным показателем востребованности будем считать степень заполнения самолетов, выполняющих рейсы
по конкретным маршрутам. Мы будем принимать во внимание лишь рейсы,
имеющие статус Departed или Arrived.

Начнем разработку с функции вычисления интересующего нас показателя для
конкретной пары городов за указанный период, причем для рейсов как «туда»,
так и «обратно».

```sql
CREATE OR REPLACE FUNCTION get_routes_occupation(
dep_city text,
arr_city text,
from_date date,
till_date date
) RETURNS TABLE (
dep_city text,
arr_city text,
total_passengers numeric, -- число перевезенных пассажиров
total_seats numeric, -- общее число мест в самолетах
occupancy_rate numeric -- доля занятых мест
) AS
$$
WITH seats_counts AS
( SELECT aircraft_code, count( * ) AS seats_cnt
FROM seats
GROUP BY aircraft_code
),
per_flight_results AS
( SELECT
r.departure_city,
r.arrival_city,
f.flight_id,
f.aircraft_code,
count( * ) AS passengers_cnt
FROM routes AS r
JOIN flights AS f ON f.flight_no = r.flight_no
JOIN ticket_flights AS tf ON tf.flight_id = f.flight_id
WHERE ( ( r.departure_city = dep_city AND r.arrival_city = arr_city ) -- туда
OR ( r.departure_city = arr_city AND r.arrival_city = dep_city ) -- обратно
)
AND f.scheduled_departure BETWEEN from_date AND till_date
AND f.status IN ( 'Departed', 'Arrived' )
GROUP BY r.departure_city, r.arrival_city, f.flight_id, f.aircraft_code
)
SELECT
pfr.departure_city,
pfr.arrival_city,
sum( pfr.passengers_cnt ) AS total_passengers,
sum( sc.seats_cnt ) AS total_seats,
round( sum( pfr.passengers_cnt ) / sum( sc.seats_cnt ), 2 ) AS occupancy_rate
FROM per_flight_results AS pfr
JOIN seats_counts AS sc ON sc.aircraft_code = pfr.aircraft_code
GROUP BY pfr.departure_city, pfr.arrival_city;
$$ LANGUAGE sql;
CREATE FUNCTION
```

В первом подзапросе в конструкции WITH вычисляется количество мест в каждой модели самолета.

Во втором подзапросе вычисляется количество пассажиров на каждом рейсе,
выполненном по одному из двух заданных направлений («туда» и «обратно»).
Хотя целью этого подзапроса является вычисление количества пассажиров на
каждом рейсе, а не на каждом направлении, тем не менее в группировке участвуют также столбцы «Город отправления», «Город прибытия» и «Код модели
самолета», поскольку они будут нужны на заключительном этапе, в главном запросе. Конечно, можно было бы упростить подзапрос, убрав эти столбцы из его
списка SELECT и предложения GROUP BY, но тогда пришлось бы включить обращения к таблицам «Маршруты» (routes) и «Рейсы» (flights) и в предложение FROM
главного запроса. В результате запрос в целом не стал бы проще.

Тип numeric для столбцов total_passengers и total_seats в таблице, которую
формирует функция, выбран потому, что функция count возвращает тип bigint,
а функция sumдает для аргумента типа bigint результаттипа numeric (см. раздел
документации 9.21 «Агрегатные функции»). Отметим также, что при вычислении доли занятых мест операция деления не будет целочисленной и округление
будет корректным.

Перейдем к проверке функции get_routes_occupation в работе. Начнем с простейшего случая — зададим ее аргументы в запросе явным образом:

```sql
SELECT
dep_city,
arr_city,
total_passengers AS pass,
total_seats AS seats,
occupancy_rate AS rate
FROM get_routes_occupation( 'Владивосток', 'Москва', '2017-08-01', '2017-08-15' );
dep_city | arr_city | pass | seats | rate
−−−−−−−−−−−−−+−−−−−−−−−−−−−+−−−−−−+−−−−−−−+−−−−−−
Владивосток | Москва | 461 | 3108 | 0.15
Москва | Владивосток | 567 | 3108 | 0.18
(2 строки)
```

Самолеты летают полупустые, возможно, из-за очень высоких цен на билеты.
Теперь посмотрим, как часто летают в Москву жители самых восточных регионов России, то есть тех, в которых аэропорты расположены восточнее долготы
150 градусов

```sql
SELECT
gro.dep_city,
gro.arr_city,
gro.total_passengers AS pass,
gro.total_seats AS seats,
gro.occupancy_rate AS rate
FROM airports
CROSS JOIN LATERAL
get_routes_occupation( city, 'Москва', '2017-08-01', '2017-08-15' ) AS gro
WHERE coordinates[ 0 ] > 150;
```

Напомним, что столбец coordinates имеет тип данных point (точка). Для обращения к отдельным координатам точки используется та же нотация, что и для
обращения к массивам. В элементе с индексом 0 записана географическая долгота, а в элементе с индексом 1 — географическая широта

```text
dep_city                  | arr_city                 | pass | seats | rate
−−−−−−−−−−−−−−−−−−−−−−−−−−+−−−−−−−−−−−−−−−−−−−−−−−−−−+−−−−−−+−−−−−−−+−−−−−−
Москва                    | Петропавловск−Камчатский | 449  | 1332  | 0.34
Петропавловск−Камчатский  | Москва                   | 415  | 1332  | 0.31
Анадырь                   | Москва                   | 64   | 232   | 0.28
Москва                    | Анадырь                  | 92   | 232   | 0.40
(4 строки)
```

В выполненном запросе первый аргумент функции брался из текущей строки
таблицы «Аэропорты» (airports), а второй оставался неизменным.

Давайте усложним задачу: нужно определить степень заполнения самолетов на
всех направлениях, проложенных из каждого города, находящегося, например,
в часовом поясе Asia/Vladivostok. Очевидно, придется каким-то образом определять список всех городов, с которыми имеет авиасообщение конкретный город, а затем подставлять полученные названия городов поочередно в качестве
второго аргумента функции get_routes_occupation, которая будет вызываться
для каждого города из выбранного часового пояса.
Функция, формирующая список городов, в которые можно улететь из указанного города, будет несложной.

Она возвращает множество строк, состоящих из одного поля, поэтому в предложении RETURNS SETOF лучше написать не record, а имя конкретного скалярного
типа — у нас это тип text.

```sql
CREATE OR REPLACE FUNCTION list_connected_cities(
city text,
OUT connected_city text
)
RETURNS SETOF text AS
$$
SELECT DISTINCT arrival_city
FROM routes
WHERE departure_city = city;
$$ LANGUAGE sql;
CREATE FUNCTION
```

Поскольку для каждого маршрута существует обратный маршрут, то города,
в которые можно улететь из данного города, совпадают с городами, из которых можно прилететь в данный город. Следовательно, если в запросе поменять
местами имена столбцов arrival_city и departure_city, получим тот же самый
список городов. Поэтому можно выбрать любой из двух вариантов запроса.
Проверим эту функцию в работе:

```sql
SELECT city, connected_city
FROM airports AS a
CROSS JOIN list_connected_cities( city ) AS connected_city
WHERE timezone = 'Asia/Vladivostok'
ORDER BY city, connected_city;
city | connected_city
−−−−−−−−−−−−−−−−−−−−−−+−−−−−−−−−−−−−−−−−
Владивосток | Иркутск
Владивосток | Москва
Владивосток | Хабаровск
Комсомольск−на−Амуре | Екатеринбург
Хабаровск | Анадырь
Хабаровск | Благовещенск
Хабаровск | Владивосток
Хабаровск | Москва
Хабаровск | Санкт−Петербург
Хабаровск | Усть−Илимск
Хабаровск | Южно−Сахалинск
(11 строк)
```

Теперь, имея функцию list_connected_cities, можно решить поставленную выше задачу. В предложении FROM поставим вызов функции list_connected_cities
левее вызова функции get_routes_occupation, чтобы вторая функция могла ссылаться на результаты работы первой.

Напомним: поскольку в предложении FROM используются функции, ключевое
слово LATERAL является необязательным.
Запрос выполняется относительно долго:

```sql
SELECT
gro.dep_city,
gro.arr_city,
gro.total_passengers AS pass,
gro.total_seats AS seats,
gro.occupancy_rate AS rate
FROM airports AS a
CROSS JOIN LATERAL list_connected_cities( a.city ) AS lcc
CROSS JOIN LATERAL
get_routes_occupation( a.city, lcc.connected_city, '2017-08-01', '2017-08-15' )
AS gro
WHERE timezone = 'Asia/Vladivostok'
ORDER BY gro.dep_city, gro.arr_city;
dep_city              | arr_city             | pass | seats | rate
−−−−−−−−−−−−−−−−−−−−−−+−−−−−−−−−−−−−−−−−−−−−−+−−−−−−+−−−−−−−+−−−−−−
Анадырь               | Хабаровск            | 90   | 232   | 0.39
Благовещенск          | Хабаровск            | 639  | 1358  | 0.47
Владивосток           | Иркутск              | 122  | 700   | 0.17
Владивосток           | Москва               | 461  | 3108  | 0.15
Владивосток           | Хабаровск            | 1201 | 1358  | 0.88
Владивосток           | Хабаровск            | 1201 | 1358  | 0.88
Екатеринбург          | Комсомольск−на−Амуре | 127  | 888   | 0.14
Иркутск               | Владивосток          | 113  | 700   | 0.16
Комсомольск−на−Амуре  | Екатеринбург         | 117  | 888   | 0.13
...
Усть−Илимск           | Хабаровск            | 122  | 200   | 0.61
Хабаровск             | Анадырь              | 85   | 232   | 0.37
Хабаровск             | Благовещенск         | 622  | 1358  | 0.46
Хабаровск             | Владивосток          | 1171 | 1358  | 0.86
Хабаровск             | Владивосток          | 1171 | 1358  | 0.86
Хабаровск             | Москва               | 2835 | 3108  | 0.91
Хабаровск             | Санкт−Петербург      | 1797 | 3108  | 0.58
Хабаровск             | Усть−Илимск          | 119  | 300   | 0.40
Хабаровск             | Южно−Сахалинск       | 85   | 168   | 0.51
Южно−Сахалинск        | Хабаровск            | 89   | 168   | 0.53
(22 строки)
```

В выборке повторяются строки «Владивосток — Хабаровск» и «Хабаровск —
Владивосток», поскольку оба этих города находятся в одном часовом поясе
Asia/Vladivostok.

Посмотрим план запроса:
```text
QUERY PLAN
−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−
Sort (actual rows=22 loops=1)
Sort Key: gro.dep_city, gro.arr_city
Sort Method: quicksort Memory: 26kB
−> Nested Loop (actual rows=22 loops=1)
−> Nested Loop (actual rows=11 loops=1)
−> Seq Scan on airports_data ml (actual rows=3 loops=1)
Filter: (timezone = 'Asia/Vladivostok'::text)
Rows Removed by Filter: 101
−> Function Scan on list_connected_cities lcc (actual rows=4 loops=3)
−> Function Scan on get_routes_occupation gro (actual rows=2 loops=11)
Planning Time: 0.110 ms
Execution Time: 11354.892 ms
(12 строк)
```

Прежде чем перейти к обсуждению плана, напомним, что объект «Аэропорты»
(airports) на самом деле является представлением, за которым скрывается таблица airports_data.

В этом плане мы видим двойной вложенный цикл. Работа начинается с отбора трех строк из таблицы airports_data, для каждой из которых вызывается
функция list_connected_cities. Она порождает в среднем по четыре строки при
каждом вызове (показатели actual rows=4 loops=3), а общее число порожденных
строк равно 11, как свидетельствует показатель actual rows=11 во внутреннем
узле Nested Loop.

Рассуждая аналогично, можно заключить, что во внешнем вложенном цикле
для каждой из одиннадцати строк, порожденных во внутреннем цикле, вызывается функция get_routes_occupation, выдающая по две строки за один вызов
(actual rows=2 loops=11). В результате число сформированных строк становится
равным 22.

**Задание**. В последнем запросе, приведенном в тексте упражнения, отчетный период задавался двумя параметрами функции get_routes_occupation. Модифицируйте запрос таким образом, чтобы можно было задать несколько отчетных
периодов. Если в конкретном периоде не было ни одного рейса, итоговая строка
все равно должна быть сформирована. Добавьте два столбца в список SELECT —
начало и конец отчетного периода.

Указание. Можно воспользоваться такой конструкцией (временны́е периоды
могут быть другими):
```sql
unnest(
ARRAY[ '2017-07-16', '2017-08-01', '2017-09-01' ]::date[],
ARRAY[ '2017-07-31', '2017-08-31', '2017-09-15' ]::date[]
) AS periods( from_date, till_date )
```

<div style="page-break-after: always;"></div>

### Решение

Создадим необходимые для выполнения задания функции и проверим их работу.

`get_routes_occupation`

<img src="./assets/2026-02-09 184335.jpg" width="700"> 

`list_connected_cities`

<img src="./assets/2026-02-09 183725.jpg" width="700"> 

<img src="./assets/2026-02-09 184335.jpg" width="700"> 

Модифицируем запрос, чтобы можно было задать несколько отчетных периодов.

```sql
SELECT
    gro.dep_city,
    gro.arr_city,
    periods.from_date,
    periods.till_date,
    COALESCE(gro.total_passengers, 0) AS pass,
    COALESCE(gro.total_seats, 0) AS seats,
    COALESCE(gro.occupancy_rate, 0) AS rate
FROM airports AS a
CROSS JOIN LATERAL list_connected_cities(a.city) AS lcc
CROSS JOIN LATERAL (
    SELECT *
    FROM unnest(
        ARRAY['2017-07-16', '2017-08-01', '2017-09-01']::date[],
        ARRAY['2017-07-31', '2017-08-31', '2017-09-15']::date[]
    ) AS periods(from_date, till_date)
) AS periods
LEFT JOIN LATERAL get_routes_occupation(
    a.city,
    lcc.connected_city,
    periods.from_date,
    periods.till_date
) AS gro ON true
WHERE a.timezone = 'Asia/Vladivostok'
ORDER BY gro.dep_city, gro.arr_city, periods.from_date;
```

Результат запроса

<img src="./assets/2026-02-09 185115.jpg" width="700"> 

<img src="./assets/2026-02-09 185134.jpg" width="700"> 