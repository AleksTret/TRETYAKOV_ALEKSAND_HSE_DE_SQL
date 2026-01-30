# Домашнее задание 2

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 1

### Задание
Битовые строки тоже можно агрегировать:
функции bit_and и bit_or

В разделе 3.1 «Агрегатные функции» (с. 109) были рассмотрены различные
функции, в частности bool_and и bool_or. Однако мы не коснулись функций
bit_and, bit_or и bit_xor. Давайте рассмотрим первые две из них на примере
следующей ситуации. Модели самолетов можно дополнительно охарактеризовать несколькими показателями (сервисами), каждый из которых может либо
присутствовать, либо отсутствовать у конкретной модели. Таким образом, показатели могут иметь истинное или ложное значение.

Для решения задачи воспользуемся типом данных bit, а конкретно bit(5), поскольку у нас будет всего пять показателей. Каждая позиция в битовой строке
будет отвечать за конкретный показатель.

В конструкции WITH подзапросы all_facilities и aircrafts_equipment подготавливают исходные данные, которые затем агрегируются в подзапросе aggregates. Функция bit_and формирует битовую строку, в которой единицы означают, что сервис доступен на всех моделях самолетов. Единицы в битовой строке,
сформированной функцией bit_or, означают, что сервис доступен хотя бы на
одной модели. В главном запросе формируются дополнительные показатели:
сервисы, которыми оборудованы не все модели (not_all_equipped), и те, которыми не оборудована ни одна из них (no_one_equipped).
```sql
WITH all_facilities( facility_code, facility_name ) AS
( VALUES ( B'00001', 'система развлечений' ),
( B'00010', 'перевозка животных' ),
( B'00100', 'USB-розетки' ),
( B'01000', 'теплые пледы' ),
( B'10000', 'Wi-Fi в полете' )
),
aircrafts_equipment( aircraft_code, facilities ) AS
( VALUES ( 'SU9', B'01110' ),
( '320', B'01110' ),
( '773', B'01111' ),
( 'CN1', B'01000' )
),
aggregates AS
( SELECT
bit_and( facilities ) AS all_equipped,
bit_or( facilities ) AS at_least_one_equipped
FROM aircrafts_equipment
)
SELECT
all_equipped,
~all_equipped AS not_all_equipped,
at_least_one_equipped,
~at_least_one_equipped AS no_one_equipped
FROM aggregates \gx
```

Интегральные показатели представлены в виде битовых масок, в которых каждая позиция соответствует конкретному частному показателю:
```text
−[ RECORD 1 ]−−−−−−−−−+−−−−−−
all_equipped          | 01000
not_all_equipped      | 10111
at_least_one_equipped | 01111
no_one_equipped       | 10000
```

Однако более наглядным было бы представление интегрального показателя
в виде совокупности его компонентов. Давайте посмотрим, например, какие
сервисы предлагаются всеми моделями самолетов. Обратите внимание, что
имя интегрального показателя all_equipped задается в предложении ON главного запроса.

```sql
...
aggregates AS
( SELECT
bit_and( facilities ) AS all_equipped,
bit_or( facilities ) AS at_least_one_equipped
FROM aircrafts_equipment
),
finals AS
( SELECT
all_equipped,
~all_equipped AS not_all_equipped,
at_least_one_equipped,
~at_least_one_equipped AS no_one_equipped
FROM aggregates
)
SELECT af.facility_code, af.facility_name
FROM finals AS f
JOIN all_facilities AS af ON ( af.facility_code & f.all_equipped )::int > 0;
facility_code | facility_name
−−−−−−−−−−−−−−−+−−−−−−−−−−−−−−−
01000 | теплые пледы
(1 строка)
```

Для получения состава всех интегральных показателей придется выполнить запрос четыре раза, изменяя имя показателя.

Задание 1. Решите эту задачу с помощью одного запроса, представив результат
в таком виде:
```text
agg_name      | facilities
−−−−−−−−−−−−−−+−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−
все модели    | теплые пледы
не все        | система развлечений, перевозка животных, USB−розетки, Wi−Fi в полете
ни одной      | Wi−Fi в полете
хотя бы одна  | система развлечений, перевозка животных, USB−розетки, теплые пледы
(4 строки)
```
Указание. В качестве одного из решений можно рассмотреть следующее. Измените подзапрос aggregates в конструкции WITH таким образом, чтобы в результате его выполнения каждому интегральному показателю соответствовала
строка, а не столбец. Для этого можно воспользоваться оператором UNION ALL.
В главном запросе соедините подзапросы aggregates и all_facilities аналогично тому, как это было сделано в тексте упражнения. Учтите также, что агрегатные функции могут использовать предложение ORDER BY.

Задание 2. Рассмотренную задачу можно решить и с использованием других
средств, например типа данных JSON. Реализуйте такой вариант и сравните два
решения с точки зрения сложности кода, удобства добавления новых показателей и т. д

<div style="page-break-after: always;"></div>

### Решение

#### Решение задания 1 (с использованием битовых строк и UNION ALL)
```sql
WITH all_facilities(facility_code, facility_name) AS (
    VALUES 
        (B'00001', 'система развлечений'),
        (B'00010', 'перевозка животных'),
        (B'00100', 'USB-розетки'),
        (B'01000', 'теплые пледы'),
        (B'10000', 'Wi-Fi в полете')
),
aircrafts_equipment(aircraft_code, facilities) AS (
    VALUES 
        ('SU9', B'01110'),
        ('320', B'01110'),
        ('773', B'01111'),
        ('CN1', B'01000')
),
aggregates AS (
    SELECT 
        bit_and(facilities) AS all_equipped,
        bit_or(facilities) AS at_least_one_equipped
    FROM aircrafts_equipment
),
indicators AS (
    SELECT 1 AS ord, 'все модели' AS agg_name, all_equipped AS mask FROM aggregates
    UNION ALL
    SELECT 2, 'не все', ~all_equipped FROM aggregates
    UNION ALL
    SELECT 3, 'ни одной', ~at_least_one_equipped FROM aggregates
    UNION ALL
    SELECT 4, 'хотя бы одна', at_least_one_equipped FROM aggregates
)
SELECT 
    i.agg_name,
    string_agg(af.facility_name, ', ' ORDER BY af.facility_code) AS facilities
FROM indicators i
CROSS JOIN all_facilities af
WHERE (af.facility_code & i.mask)::int::boolean
GROUP BY i.ord, i.agg_name
ORDER BY i.ord;
```

Код скрипта не умещается на экране, и затруднителен для вставки, поэтому вызов скрипта выполнен из файла


<img src="./assets/2026-01-28 174122.jpg" width="700"> 

#### Решение задания 2 (с использованием типа JSON)
```sql
WITH facilities_config AS (
    SELECT jsonb_build_object(
        'services', jsonb_build_array(
            'система развлечений',
            'перевозка животных', 
            'USB-розетки',
            'теплые пледы',
            'Wi-Fi в полете'
        )
    ) as config
),
aircrafts_data AS (
    SELECT 
        aircraft_code,
        jsonb_build_object(
            'services_array', jsonb_build_array(
                (facilities::integer & 1) = 1,     -- 00001: система развлечений
                (facilities::integer & 2) = 2,     -- 00010: перевозка животных
                (facilities::integer & 4) = 4,     -- 00100: USB-розетки
                (facilities::integer & 8) = 8,     -- 01000: теплые пледы
                (facilities::integer & 16) = 16    -- 10000: Wi-Fi в полете
            )
        ) as data
    FROM (VALUES 
        ('SU9', B'01110'),
        ('320', B'01110'),
        ('773', B'01111'),
        ('CN1', B'01000')
    ) AS t(aircraft_code, facilities)
),
all_services_arrays AS (
    SELECT jsonb_agg(data->'services_array') as aggregated_arrays
    FROM aircrafts_data
),
service_analysis AS (
    SELECT 
        idx::integer as idx,  
        service_name,
        bool_and(has_service) as all_have,
        bool_or(has_service) as any_has
    FROM all_services_arrays,
    LATERAL jsonb_array_elements(aggregated_arrays) AS aircraft_services,
    LATERAL jsonb_array_elements_text(
        (SELECT config->'services' FROM facilities_config)
    ) WITH ORDINALITY AS service_info(service_name, idx),
    LATERAL (
        SELECT (aircraft_services->>(idx::integer - 1))::text::boolean as has_service
    ) hs
    GROUP BY idx, service_name
),
aggregates AS (
    SELECT 
        jsonb_agg(
            CASE WHEN all_have THEN service_name END
        ) FILTER (WHERE all_have) as all_models,
        jsonb_agg(
            CASE WHEN NOT all_have THEN service_name END
        ) FILTER (WHERE NOT all_have) as not_all,
        jsonb_agg(
            CASE WHEN NOT any_has THEN service_name END
        ) FILTER (WHERE NOT any_has) as none,
        jsonb_agg(
            CASE WHEN any_has THEN service_name END
        ) FILTER (WHERE any_has) as at_least_one
    FROM service_analysis
),
results AS (
    SELECT 'все модели' as agg_name, all_models as facilities FROM aggregates
    UNION ALL
    SELECT 'не все', not_all FROM aggregates
    UNION ALL
    SELECT 'ни одной', none FROM aggregates
    UNION ALL
    SELECT 'хотя бы одна', at_least_one FROM aggregates
)
SELECT 
    agg_name,
    string_agg(value, ', ' ORDER BY ordinality) as facilities
FROM results,
LATERAL jsonb_array_elements_text(facilities) WITH ORDINALITY as elem(value, ordinality)
WHERE value IS NOT NULL
GROUP BY agg_name
ORDER BY 
    CASE agg_name 
        WHEN 'все модели' THEN 1
        WHEN 'не все' THEN 2
        WHEN 'ни одной' THEN 3
        WHEN 'хотя бы одна' THEN 4
    END;
```    

Код скрипта так же как и в первом задании не умещается на экране, и затруднителен для вставки, поэтому вызов скрипта выполнен из файла


<img src="./assets/2026-01-28 180045.jpg" width="700"> 

Битовые строки
- Компактнее, быстрее
- Ограничено кол-вом признаков
- Сложнее добавлять новые

JSON подход 
- Гибче, масштабируемее
- Легче добавлять признаки
- Медленнее, сложнее код

Для фиксированных признаков - битовые строки. 
Для изменяемых - JSON.