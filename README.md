# SmartShop Inventory - Starter Project

This small starter project contains SQL schema, sample data, and example queries for the SmartShop Inventory System.

What is included
- `schema.sql` — table definitions for Products, Categories, Suppliers, Stores, Inventory, Sales (generic SQL, adapt types to your DBMS).
- `sample_data.sql` — a few INSERTs to test queries locally.
- `queries.sql` — basic SELECTs, filters, joins, and sorting examples.
- `.vscode/extensions.json` — recommended VS Code extensions for SQL development.

Quick steps to get started :
1. Open the project in VS Code:

2. Install recommended extensions (from Extensions view):
   - SQL Server (ms-mssql.mssql) — if using Microsoft SQL Server
   - SQLTools (mtxr.sqltools) — general SQL client
   - SQLite (alexcvzz.vscode-sqlite) — if you want to use a local SQLite DB

3. Create or connect to a database. For quick local testing using SQLite (if you have sqlite3 installed):

```powershell
# Create a local SQLite DB file and load schema
sqlite3 smartshop.db ".read schema.sql" 
sqlite3 smartshop.db ".read sample_data.sql"
# Then use a VS Code SQLite extension to open smartshop.db, or use sqlite3 to run queries
```

Notes
- The SQL files are written to be clear and easy to adapt. Change types/constraints to your target DB (Postgres, SQL Server, MySQL, SQLite).


