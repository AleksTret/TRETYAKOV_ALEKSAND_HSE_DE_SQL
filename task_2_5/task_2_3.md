# Домашнее задание 5

**Выполнил - Третьяков Александр Юрьевич**

## Упражение 3

### Задание

В подразделе документации 41.6.8.1 «Получение информации об
ошибке» описывается команда GET STACKED DIAGNOSTICS,
предназначенная для получения информации о текущем исключении.

Задание. Проиллюстрируйте использование этой команды. С этой целью
модифицируйте одну из функций, приведенных в тексте лекции (презентации),
включив эту команду в ее код.

<div style="page-break-after: always;"></div>

### Решение

Для иллюстрации `GET STACKED DIAGNOSTICS` возьмём функцию из лекции, которая делит числа - `divide_numbers`, и добавим обработку ошибки деления на ноль

```sql
CREATE OR REPLACE FUNCTION divide_numbers(a integer, b integer)
RETURNS integer AS $$
DECLARE
    result integer;
    err_context text;
    err_message text;
BEGIN
    result := a / b;
    RETURN result;
EXCEPTION
    WHEN division_by_zero THEN
        GET STACKED DIAGNOSTICS 
            err_context = PG_CONTEXT,
            err_message = MESSAGE_TEXT;
        RAISE NOTICE 'Ошибка: деление на ноль';
        RAISE NOTICE 'Контекст: %', err_context;
        RAISE NOTICE 'Сообщение: %', err_message;
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;
```

Проверка:

```sql
SELECT divide_numbers(10, 2); 
SELECT divide_numbers(10, 0); 
```

<img src="./assets/2026-02-16 184134.jpg" width="700">

<img src="./assets/2026-02-16 184156.jpg" width="700">