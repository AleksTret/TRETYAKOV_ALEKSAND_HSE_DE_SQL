# Переключиться на пользователя postgres
sudo su - postgres

# в терминале postgres создать дамп базы
pg_dump -F c -b -v -f "bnk_backup_$(date +%Y%m%d).dump" bnk

# Проверить
ls -lh bnk_backup_*.dump

# Выйти из postgres
exit

# Скопировать в каталог mars17
sudo cp /var/lib/postgresql/bnk_backup_20251222.dump ~/sql_final_task/bnk/

# Скопировать дамп на хост машину
scp mars17@VM-mars17:/home/mars17/sql_final_task/bnk/bnk_backup_20251222.dump .