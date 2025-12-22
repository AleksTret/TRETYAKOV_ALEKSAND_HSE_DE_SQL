# запусти скрипт
sudo -u postgres psql -f create_all.sql

# Или 

# Добавь mars17 как суперпользователя в PostgreSQL
sudo -u postgres createuser --superuser mars17

# Запускать от mars17
psql -U mars17 -d postgres -f create_all.sql

# Удалить базу
sudo -u postgres psql -c "DROP DATABASE IF EXISTS bnk;"

# Запуск файлов по отдельности

# скрипт создания базы
sudo -u postgres psql -f create_db.sql

scp mars17@UBUNTU_IP:/home/mars17/sql_final_task/bnk/bnk_backup_20251222.dump .