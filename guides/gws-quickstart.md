# gws CLI Quick Start

## Common Operations

```bash
# Read a spreadsheet
gws sheets spreadsheets values get --params '{
  "spreadsheetId": "<ID>",
  "range": "Sheet1!A1:Z100"
}'

# Write data
gws sheets spreadsheets values update --params '{
  "spreadsheetId": "<ID>",
  "range": "Sheet1!A1",
  "valueInputOption": "USER_ENTERED"
}' --json '{"values": [["Header1", "Header2"], ["Value1", "Value2"]]}'

# Append rows
gws sheets spreadsheets values append --params '{
  "spreadsheetId": "<ID>",
  "range": "Sheet1!A1",
  "valueInputOption": "USER_ENTERED"
}' --json '{"values": [["NewRow1", "NewRow2"]]}'

# Search Drive for spreadsheets
gws drive files list --params '{
  "q": "mimeType=\"application/vnd.google-apps.spreadsheet\" and name contains \"KPI\"",
  "pageSize": 10
}'

# Create a spreadsheet
gws sheets spreadsheets create --json '{
  "properties": {"title": "My Sheet"},
  "sheets": [{"properties": {"title": "Sheet1"}}]
}'
```

---

## Authentication

- OAuth credentials stored at `~/.config/gws/` (client_secret.json, credentials.enc, token_cache.json)
- Authenticated via `gws auth login -s sheets,drive`
- Tokens auto-refresh; if expired, re-run `gws auth login -s sheets,drive`
- API quotas: Sheets 500 req/min, Drive 1000 q/sec

### Credential Handling

- If a credential fails, test with a real API call first (`gws drive files list`), then report the specific error.
- If auth is genuinely broken: "The gws CLI returned error [specific error]. Re-authenticate with `gws auth login -s sheets,drive`."
