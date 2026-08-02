# Harvest Backups

This branch holds nothing but automated database backups — it has no history in
common with `main`/`dev` and is never merged.

- `latest.json` is a full JSON dump of every business table in the Harvest
  production database, refreshed nightly by a scheduled GitHub Actions job
  that calls `POST /api/system/backup` on the API.
- Table *schema* isn't included here since it's already fully reproducible
  from the SQL scripts in `database/` on `main`.
- Every nightly run overwrites `latest.json`, so git's own commit history on
  this branch is what gives you point-in-time snapshots — use
  `git log -- latest.json` and `git show <commit>:latest.json` to pull an
  older backup.
- This complements, not replaces, Azure SQL's built-in 7-day point-in-time
  restore: PITR is for fast recovery from a recent mistake, this branch is
  the longer-term, off-platform safety net.
