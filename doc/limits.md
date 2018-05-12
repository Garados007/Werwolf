# Limits

## DB Limits

**Ai Name Key:** 8
**Group Enter Key:** 12
**Phase Key:** 8 _(only usable: 6)_
**Role Key:** 8
**Chat Room Key:** 8
**Vote Setting Key:** 5

This limits are fixed in the implementation (in `setup/sql/createDatabase.sql`).

The usable phase key is smaller because the implementation adds a prefix of 2 chars. `d:` if its a phase at the day and `n:` if its a phase at the night.