# Домашнее задание 6

**Выполнил - Третьяков Александр Юрьевич**

### Задание

Выполняется на основе презентации «Триггеры».

Задание. Создайте представление (можно на основе только одной таблицы) в рамках
предметной области «Авиаперевозки» или в любой другой. Напишите триггерные функции и
создайте триггеры для реализации операций вставки записей в это представление, а также
операций обновления и удаления записей.

<div style="page-break-after: always;"></div>

### Решение

Создаём представление

```sql
CREATE VIEW airports_data_view AS
SELECT airport_code, airport_name, city, coordinates, timezone
FROM airports_data;
```

<img src="./assets/2026-02-16 185458.jpg" width="700"> 


Пишем триггерную функцию для INSERT
```sql
CREATE OR REPLACE FUNCTION airports_data_view_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO airports_data (airport_code, airport_name, city, coordinates, timezone)
    VALUES (NEW.airport_code, NEW.airport_name, NEW.city, NEW.coordinates, NEW.timezone);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```
<img src="./assets/2026-02-16 191612.jpg" width="700"> 

Пишем триггерную функцию для UPDATE

```sql
CREATE OR REPLACE FUNCTION airports_data_view_update()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE airports_data
    SET airport_name = NEW.airport_name,
        city = NEW.city,
        coordinates = NEW.coordinates,
        timezone = NEW.timezone
    WHERE airport_code = OLD.airport_code;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```
<img src="./assets/2026-02-16 191630.jpg" width="700"> 

Пишем триггерную функцию для DELETE

```sql
CREATE OR REPLACE FUNCTION airports_data_view_delete()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM airports_data WHERE airport_code = OLD.airport_code;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;
```

<img src="./assets/2026-02-16 191647.jpg" width="700"> 


Создаём триггеры:
```sql
CREATE TRIGGER airports_data_view_insert_trigger
INSTEAD OF INSERT ON airports_data_view
FOR EACH ROW
EXECUTE FUNCTION airports_data_view_insert();

CREATE TRIGGER airports_data_view_update_trigger
INSTEAD OF UPDATE ON airports_data_view
FOR EACH ROW
EXECUTE FUNCTION airports_data_view_update();

CREATE TRIGGER airports_data_view_delete_trigger
INSTEAD OF DELETE ON airports_data_view
FOR EACH ROW
EXECUTE FUNCTION airports_data_view_delete();
```

<img src="./assets/2026-02-16 192003.jpg" width="700"> 


Проверка

Вставка
```sql
INSERT INTO airports_data_view VALUES (
    'XXX', 
    '"Test Airport"', 
    '"Test City"', 
    point(10,20), 
    'UTC+3'
);

SELECT * FROM airports_data_view WHERE airport_code = 'XXX';
```

<img src="./assets/2026-02-16 192112.jpg" width="700"> 

<img src="./assets/2026-02-16 192126.jpg" width="700"> 

<img src="./assets/2026-02-16 192155.jpg" width="700"> 

Обновление
```sql
UPDATE airports_data_view 
SET airport_name = '"Updated Airport"' 
WHERE airport_code = 'XXX';

SELECT * FROM airports_data WHERE airport_code = 'XXX';
```

<img src="./assets/2026-02-16 192321.jpg" width="700"> 

Удаление
```sql
DELETE FROM airports_data_view WHERE airport_code = 'XXX';

SELECT * FROM airports_data WHERE airport_code = 'XXX';
```

<img src="./assets/2026-02-16 192355.jpg" width="700"> 