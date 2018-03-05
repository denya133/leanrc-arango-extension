# Folder for database migrations

All migrations must be in format `<YYYYDDMMhhmmss>_<undescored_name_of_migration>.coffee`

For example
`20161214210544_create_cucumbers_migration.coffee`

В этом фолдере должен быть пример ядра (самодостаточного) которое позволит запустить инстанс приложения с подгруженными миграциями (для их выполнения)

Возможно это должно быть похоже на `core` или `app` содержимое.
