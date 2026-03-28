-- Создание типа для возврата графика
CREATE TYPE payment_row AS (
    payment_date date,
    mea numeric,
    interest_amount numeric,
    principal_amount numeric,
    remaining_balance numeric,
    interest_rate numeric
);

-- Таблица для хранения графиков
CREATE TABLE payment_schedules (
    accountid integer,
    calcid integer,
    calc_date date,
    payment_date date,
    mea numeric,
    interest_amount numeric,
    principal_amount numeric,
    remaining_balance numeric,
    interest_rate numeric,
    PRIMARY KEY (accountid, calcid, payment_date)
);

COMMENT ON TABLE payment_schedules IS 'Хранит графики аннуитетных платежей';

-- Основная функция построения графика
CREATE FUNCTION build_schedule(
    accountid integer,
    amount numeric,
    rate numeric,
    months integer,
    issue_date text,
    prepayments jsonb DEFAULT '[]'::jsonb
)
RETURNS SETOF payment_row
AS $$
from datetime import datetime, timedelta, date
from decimal import Decimal, ROUND_HALF_UP
import json

def _round_money(v):
    return Decimal(v).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)

def _annuity_payment(amount, rate, months):
    if rate == 0:
        return amount / months
    monthly_rate = rate / 12 / 100
    factor = monthly_rate * (1 + monthly_rate) ** months
    factor /= (1 + monthly_rate) ** months - 1
    return amount * factor

start_date = datetime.strptime(issue_date, '%Y-%m-%d').date()
balance = amount
monthly_rate = rate / 12 / 100
payment = _annuity_payment(amount, rate, months)
schedule = []
payment_date = start_date
for i in range(months):
    payment_date += timedelta(days=30)
    interest = balance * monthly_rate
    principal = payment - interest
    if principal > balance:
        principal = balance
        payment = principal + interest
    balance -= principal
    schedule.append({
        'payment_date': payment_date,
        'mea': _round_money(payment),
        'interest_amount': _round_money(interest),
        'principal_amount': _round_money(principal),
        'remaining_balance': _round_money(balance),
        'interest_rate': rate
    })
    if balance <= 0:
        break

# Получаем следующий calcid
qry = "SELECT COALESCE(MAX(calcid), 0) + 1 AS next_calc FROM payment_schedules WHERE accountid = " + str(accountid)
res = plpy.execute(qry)
calcid = res[0]['next_calc'] if res else 1

calc_date = date.today()

# Вставляем строки
for row in schedule:
    qry = """
        INSERT INTO payment_schedules 
        (accountid, calcid, calc_date, payment_date, mea, interest_amount, principal_amount, remaining_balance, interest_rate)
        VALUES (%s, %s, '%s', '%s', %s, %s, %s, %s, %s)
    """ % (accountid, calcid, calc_date, row['payment_date'], row['mea'], row['interest_amount'], row['principal_amount'], row['remaining_balance'], row['interest_rate'])
    plpy.execute(qry)

return [(row['payment_date'], row['mea'], row['interest_amount'], row['principal_amount'], row['remaining_balance'], row['interest_rate']) for row in schedule]
$$ LANGUAGE plpython3u;

COMMENT ON FUNCTION build_schedule(integer, numeric, numeric, integer, text, jsonb)
IS 'Строит график аннуитетных платежей. Параметры: accountid, сумма, годовая ставка (%), срок в месяцах, дата выдачи (YYYY-MM-DD), ЧДП (JSONB)';

-- Функция расчёта ПСК по сохранённому графику
CREATE OR REPLACE FUNCTION calculate_psc(
    accountid integer,
    calcid integer
)
RETURNS numeric
AS $$
from datetime import datetime
from decimal import Decimal, ROUND_HALF_UP

def _round_money(value):
    return Decimal(value).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)

qry = """
    SELECT payment_date, mea, interest_rate
    FROM payment_schedules
    WHERE accountid = """ + str(accountid) + " AND calcid = " + str(calcid) + """
    ORDER BY payment_date
"""
rows = plpy.execute(qry)

if not rows:
    plpy.error("Schedule not found")

qry2 = """
    SELECT principal_amount, remaining_balance
    FROM payment_schedules
    WHERE accountid = """ + str(accountid) + " AND calcid = " + str(calcid) + """
    ORDER BY payment_date
    LIMIT 1
"""
first = plpy.execute(qry2)
loan_amount = float(first[0]['principal_amount'] + first[0]['remaining_balance'])

payments = [float(row['mea']) for row in rows]
n = len(payments)
months = [i+1 for i in range(n)]

def psc_equation(psc):
    total = 0.0
    for t in range(n):
        total += payments[t] / (1 + psc) ** (months[t] / 12)
    return total - loan_amount

def psc_derivative(psc):
    total = 0.0
    for t in range(n):
        total += -payments[t] * (months[t] / 12) / (1 + psc) ** (months[t] / 12 + 1)
    return total

rate_nominal = float(rows[0]['interest_rate']) / 100
psc = rate_nominal

for _ in range(100):
    f = psc_equation(psc)
    f_prime = psc_derivative(psc)
    if f_prime == 0:
        break
    psc_new = psc - f / f_prime
    if abs(psc_new - psc) < 1e-8:
        psc = psc_new
        break
    psc = psc_new

return _round_money(psc * 100)
$$ LANGUAGE plpython3u;

-- Функция экспорта графика в JSON
CREATE FUNCTION export_schedule_json(
    accountid integer,
    calcid integer
)
RETURNS jsonb
AS $$
import json
from datetime import datetime

qry = """
    SELECT payment_date, mea, interest_amount, principal_amount, remaining_balance, interest_rate
    FROM payment_schedules
    WHERE accountid = """ + str(accountid) + " AND calcid = " + str(calcid) + """
    ORDER BY payment_date
"""
rows = plpy.execute(qry)

if not rows:
    plpy.error("Schedule not found")

schedule = []
for row in rows:
    schedule.append({
        'payment_date': datetime.strptime(row['payment_date'], '%Y-%m-%d').date().isoformat(),
        'mea': str(row['mea']),
        'interest_amount': str(row['interest_amount']),
        'principal_amount': str(row['principal_amount']),
        'remaining_balance': str(row['remaining_balance']),
        'interest_rate': str(row['interest_rate'])
    })

return json.dumps(schedule, indent=2)
$$ LANGUAGE plpython3u;

COMMENT ON FUNCTION export_schedule_json(integer, integer)
IS 'Возвращает график погашения в формате JSON для указанного расчёта.';