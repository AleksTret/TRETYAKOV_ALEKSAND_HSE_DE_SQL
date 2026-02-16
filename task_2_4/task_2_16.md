# Домашнее задание 4

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 16

### Задание

Поиск корней
квадратного уравнения

На языке SQL можно написать функцию, вычисляющую, например, действительные корни квадратного уравнения. В конструкции WITH сначала вычисляется дискриминант, а затем — корни уравнения. В главном запросе значения
корней округляются с требуемой точностью. Обратите внимание, что подзапрос в вызове функции sqrt заключается в скобки.

```sql
CREATE OR REPLACE FUNCTION square_equation(
a double precision,
b double precision,
c double precision,
accuracy integer DEFAULT 2,
OUT x1 numeric,
OUT x2 numeric
) AS
$$
WITH discriminant AS
( SELECT b * b - 4 * a * c AS d
),
roots AS
( SELECT
( -b + sqrt( ( SELECT d FROM discriminant ) ) ) / ( 2 * a ) AS x_one,
( -b - sqrt( ( SELECT d FROM discriminant ) ) ) / ( 2 * a ) AS x_two
)
SELECT
round( x_one::numeric, accuracy ) AS x_one,
round( x_two::numeric, accuracy ) AS x_two
FROM roots;
$$ LANGUAGE sql;
CREATE FUNCTION
```

Обратите внимание, что в главном запросе псевдонимы для имен корней уравнения x_one и x_two (после слова AS) совпадают с именами столбцов x_one
и x_two из подзапроса roots (аргументы функции round). Конечно, делать так
совсем не обязательно, но это тоже работает.
Проверим работу функции:

```sql
SELECT square_equation( 3, -6, 2 );
square_equation
−−−−−−−−−−−−−−−−−
(1.58,0.42)
(1 строка)
```
Зададим точность округления результатов до четырех цифр:
```sql
SELECT square_equation( 3, -6, 2, 4 );
square_equation
−−−−−−−−−−−−−−−−−
(1.5774,0.4226)
(1 строка)
```

В предыдущих запросах, когда функция вызывалась непосредственно в предложении SELECT, результатом было значение составного типа. Если же вызвать
функцию в предложении FROM, два ее результирующих значения будут выведены как отдельные столбцы:
```sql
SELECT * FROM square_equation( 3, -6, 2 );
x1 | x2
−−−−−−+−−−−−−
1.58 | 0.42
(1 строка)
```
В случае ошибки работа функции прекращается:
```sql
SELECT square_equation( 3, -6, 4 );
ОШИБКА: извлечь квадратный корень отрицательного числа нельзя
КОНТЕКСТ: SQL−функция "square_equation", оператор 1
SELECT * FROM square_equation( 0, -6, 2 );
ОШИБКА: деление на ноль
КОНТЕКСТ: SQL−функция "square_equation", оператор 1
```

Вопрос. При создании этой функции мы не указали категорию изменчивости,
поэтому по умолчанию принимается VOLATILE. А можно ли назначить категорию изменчивости STABLE или IMMUTABLE? Почему?

Задание 1. Создайте таблицу coeffs, содержащую значения коэффициентов
уравнений (столбцы a, b и c). Введите в нее несколько строк. Напишите запрос,
в котором функция решает все уравнения, определяемые коэффициентами из
каждой строки таблицы. Представьте результаты не только в виде составных
значений, но также и в виде отдельных столбцов. Например:

```sql
SELECT x1( square_equation( a, b, c ) ), x2( square_equation( a, b, c ) )
FROM coeffs;
SELECT ( square_equation( a, b, c ) ).*
FROM coeffs;
SELECT x1, x2
FROM coeffs, square_equation( a, b, c );
```

Как вы думаете, есть ли принципиальное различие между первым и вторым вариантами? Проверьте ваши предположения с помощью команды EXPLAIN с параметрами ANALYZE и VERBOSE

Задание 2. Предложите вашу функцию, решающую уравнения другого вида или
выполняющую какие-то вычисления на основе базы данных «Авиаперевозки». В качестве примера можно рассмотреть расчет заработной платы пилотов
в зависимости от оклада, районного коэффициента и различных персональных
надбавок, а также с учетом налогов. Вызовите вашу функцию в запросе, возвращающем более одной строки, чтобы функция проводила вычисления на основе
различных исходных значений, получаемых из базы данных. При необходимости создайте дополнительные таблицы

<div style="page-break-after: always;"></div>

### Решение


Функцию `square_equation` нельзя сделать `STABLE` или `IMMUTABLE`, потому что она может вызывать ошибки (деление на ноль, корень из отрицательного числа). Такие функции должны быть `VOLATILE` — это значение по умолчанию, и оно здесь правильно.

Для выполнения **Задания 1** создадим таблицу

```sql
CREATE TABLE coeffs (
    a double precision,
    b double precision,
    c double precision
);

INSERT INTO coeffs (a, b, c) VALUES
(1, -3, 2),
(2, -4, 2),
(1, 2, 1),
(3, -6, 2),
```

<img src="./assets/2026-02-09 195752.jpg" width="700"> 

Вариант 1 — составные значения (функция вызывается дважды)
```sql
SELECT x1(square_equation(a, b, c)), x2(square_equation(a, b, c)) FROM coeffs;
```

Вариант 2 — развёртка составного значения (функция вызывается один раз):
```sql
SELECT (square_equation(a, b, c)).* FROM coeffs;
```

Вариант 3 — (явный вызов в FROM):
```sql
SELECT x1, x2 FROM coeffs, square_equation(a, b, c);
```

<img src="./assets/2026-02-09 200523.jpg" width="700"> 

Предположение:
Вариант 1 вызовет функцию square_equation дважды для каждой строки (один раз для x1, второй для x2), а Вариант 2 — только один раз. Это должно отразиться в плане (разное число вызовов функции).

```sql
-- Вариант 1
EXPLAIN (ANALYZE, VERBOSE) 
SELECT x1(square_equation(a, b, c)), x2(square_equation(a, b, c)) FROM coeffs;

-- Вариант 2
EXPLAIN (ANALYZE, VERBOSE) 
SELECT (square_equation(a, b, c)).* FROM coeffs;
```


<img src="./assets/2026-02-09 200903.jpg" width="700"> 

Планы запросов для вариантов 1 и 2 одинаковы — в Output видно, что оба раза выводятся поля (square_equation(...)).x1 и (...).x2.
Это значит, что PostgreSQL оптимизировал первый запрос (где функция написана дважды) и вычислил её один раз на строку, а затем обратился к полям результата.
Так что принципиального различия в производительности между первым и вторым вариантами нет.

Для выполения **Задания 2** создадим таблицу с данными

```sql
CREATE TABLE pilots (
    pilot_id serial PRIMARY KEY,
    name text NOT NULL,
    base_salary numeric(10,2) NOT NULL,
    regional_coef numeric(5,2) DEFAULT 1.0,
    bonus numeric(10,2) DEFAULT 0.0
);

INSERT INTO pilots (name, base_salary, regional_coef, bonus) VALUES
('Иванов А.П.', 100000, 1.15, 20000),
('Петров С.М.', 120000, 1.0, 15000),
('Сидоров В.Л.', 90000, 1.2, 10000);
```

Создадим функцию `calculate_salary`:
Она будет вычислять зарплату по формуле:
`(base_salary * regional_coef + bonus) * (1 - tax_rate)`,
где `tax_rate` — ставка налога (по умолчанию 13%).

```sql
CREATE OR REPLACE FUNCTION calculate_salary(
    pilot_id integer,
    tax_rate numeric DEFAULT 0.13
)
RETURNS TABLE (
    name text,
    gross_salary numeric, -- зарплата до вычета налога
    tax_amount numeric,   -- сумма налога
    net_salary numeric    -- зарплата на руки
) AS
$$
BEGIN
    RETURN QUERY
    SELECT 
        p.name,
        p.base_salary * p.regional_coef + p.bonus AS gross_salary,
        (p.base_salary * p.regional_coef + p.bonus) * tax_rate AS tax_amount,
        (p.base_salary * p.regional_coef + p.bonus) * (1 - tax_rate) AS net_salary
    FROM pilots p
    WHERE p.pilot_id = calculate_salary.pilot_id;
END;
$$ LANGUAGE plpgsql;
```

Вызов функции
```sql
SELECT * FROM calculate_salary(1);
SELECT * FROM calculate_salary(2);
SELECT * FROM calculate_salary(3);
```

<img src="./assets/2026-02-09 201630.jpg" width="700"> 

<img src="./assets/2026-02-09 201743.jpg" width="700"> 

<img src="./assets/2026-02-09 202053.jpg" width="700">

Выполним что бы получить несколько значений
```sql
SELECT p.pilot_id, cs.* 
FROM pilots p
CROSS JOIN LATERAL calculate_salary(p.pilot_id) AS cs;
```

<img src="./assets/2026-02-09 202434.jpg" width="700">