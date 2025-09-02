# config

- 동작하지 않음
- psql -U user로 들어가서 수동으로 반영
- ALTER SYSTEM SET max_connections = 200;
- pod restart
- SHOW max_connections; 