# n8n Google Calendar Integration - Skill Reference

> **Purpose:** This document provides complete technical reference for AI agents working with the n8n-calendar project.

## Overview

This project provides a **REST API layer** over Google Calendar via n8n (workflow automation tool). It enables full CRUD operations on calendar events through HTTP webhooks.

**Architecture:**
```
User Request → n8n Webhook → Google Calendar API → Response
```

## Project Structure

```
/home/kat/
├── google_calendar_create_event_workflow.json   # POST /webhook/events/create
├── google_calendar_list_events_workflow.json    # GET /webhook/events/list
├── google_calendar_update_event_workflow.json   # PUT /webhook/events/update
├── google_calendar_delete_event_workflow.json   # DELETE /webhook/events/delete
├── google_calendar_workflow_fixed.json          # Legacy version (ignore)
├── test_event_crud.sh                           # Bash test suite
├── README.md                                    # Human documentation
├── SKILL.md                                     # This file
├── n8n-start.sh                                 # Start n8n service
├── n8n-stop.sh                                  # Stop n8n service
├── n8n-restart.sh                               # Restart n8n service
├── n8n-status.sh                                # Check n8n status
├── n8n-logs.sh                                  # View n8n logs
└── .n8n/                                        # n8n data directory
    ├── database.sqlite                          # Workflow storage
    └── ...
```

## Prerequisites

- **n8n** installed at `~/.npm-global/bin/n8n`
- **Node.js** (comes with n8n)
- **Google Calendar OAuth2 credentials** configured in n8n
- **systemd** user service support (for auto-start)

## Service Management

n8n runs as a **systemd user service** with auto-restart enabled.

### Status Check
```bash
systemctl --user status n8n.service
# or
~/n8n-status.sh
```

### Start/Stop/Restart
```bash
# Start
systemctl --user start n8n.service
~/n8n-start.sh

# Stop
systemctl --user stop n8n.service
~/n8n-stop.sh

# Restart
systemctl --user restart n8n.service
~/n8n-restart.sh
```

### View Logs
```bash
# Live logs
journalctl --user -u n8n.service -f
~/n8n-logs.sh

# Recent logs
journalctl --user -u n8n.service --since "1 hour ago"
```

### Auto-start on Boot
```bash
# Check if enabled
systemctl --user is-enabled n8n.service

# Enable (usually already done)
systemctl --user enable n8n.service

# Disable
systemctl --user disable n8n.service
```

## API Endpoints

Base URL: `http://localhost:5678`

### 1. Create Event
**Endpoint:** `POST /webhook/events/create`

**Request Body:**
```json
{
  "summary": "Meeting Title",
  "description": "Meeting description",
  "location": "Conference Room A",
  "start": "2026-03-05T10:00:00-03:00",
  "end": "2026-03-05T11:00:00-03:00"
}
```

**Required Fields:**
- `summary` - Event title
- `start` - Start time (ISO 8601 format with timezone)
- `end` - End time (ISO 8601 format with timezone)

**Optional Fields:**
- `description` - Event description
- `location` - Physical location

**Success Response:**
```json
{
  "success": true,
  "eventId": "abc123xyz",
  "htmlLink": "https://www.google.com/calendar/event?eid=...",
  "message": "Event created successfully"
}
```

**cURL Example:**
```bash
curl -X POST http://localhost:5678/webhook/events/create \
  -H "Content-Type: application/json" \
  -d '{
    "summary": "Team Meeting",
    "description": "Weekly sync",
    "location": "Zoom",
    "start": "2026-03-05T10:00:00-03:00",
    "end": "2026-03-05T11:00:00-03:00"
  }'
```

---

### 2. List Events
**Endpoint:** `GET /webhook/events/list`

**Query Parameters:**
- `timeMin` - Start of date range (ISO 8601)
- `timeMax` - End of date range (ISO 8601)
- `maxResults` - Maximum number of events (default: 10)

**Success Response:**
```json
{
  "success": true,
  "events": [...],
  "count": 5,
  "message": "Events retrieved successfully"
}
```

**cURL Examples:**
```bash
# List upcoming events (default)
curl "http://localhost:5678/webhook/events/list"

# List with limit
curl "http://localhost:5678/webhook/events/list?maxResults=5"

# List date range
curl "http://localhost:5678/webhook/events/list?timeMin=2026-03-01T00:00:00-03:00&timeMax=2026-03-31T23:59:59-03:00"
```

---

### 3. Update Event
**Endpoint:** `PUT /webhook/events/update`

**Request Body:**
```json
{
  "eventId": "abc123xyz",
  "summary": "Updated Title",
  "description": "Updated description",
  "location": "New Location",
  "start": "2026-03-05T14:00:00-03:00",
  "end": "2026-03-05T15:00:00-03:00"
}
```

**Required Fields:**
- `eventId` - ID of event to update

**Optional Fields:** (all other fields are optional, only provided fields are updated)
- `summary`
- `description`
- `location`
- `start`
- `end`

**Success Response:**
```json
{
  "success": true,
  "eventId": "abc123xyz",
  "htmlLink": "https://www.google.com/calendar/event?eid=...",
  "summary": "Updated Title",
  "message": "Event updated successfully"
}
```

**cURL Example:**
```bash
curl -X PUT http://localhost:5678/webhook/events/update \
  -H "Content-Type: application/json" \
  -d '{
    "eventId": "YOUR_EVENT_ID",
    "summary": "Updated Meeting",
    "start": "2026-03-05T14:00:00-03:00",
    "end": "2026-03-05T15:00:00-03:00"
  }'
```

---

### 4. Delete Event
**Endpoint:** `DELETE /webhook/events/delete`

**Query Parameters:**
- `eventId` - ID of event to delete

**Success Response:**
```json
{
  "success": true,
  "eventId": "abc123xyz",
  "message": "Event deleted successfully"
}
```

**cURL Example:**
```bash
curl -X DELETE "http://localhost:5678/webhook/events/delete?eventId=YOUR_EVENT_ID"
```

---

## Testing

### Quick Test Script
```bash
# Run full CRUD test suite
chmod +x ~/test_event_crud.sh
~/test_event_crud.sh
```

This script:
1. Creates a test event
2. Lists events to verify
3. Updates the event
4. Deletes the event
5. Verifies deletion

### Manual Testing
```bash
# 1. Create
curl -X POST http://localhost:5678/webhook/events/create \
  -H "Content-Type: application/json" \
  -d '{"summary":"Test","start":"2026-03-05T10:00:00-03:00","end":"2026-03-05T11:00:00-03:00"}'

# 2. List
curl http://localhost:5678/webhook/events/list

# 3. Update (replace EVENT_ID)
curl -X PUT http://localhost:5678/webhook/events/update \
  -H "Content-Type: application/json" \
  -d '{"eventId":"EVENT_ID","summary":"Updated"}'

# 4. Delete (replace EVENT_ID)
curl -X DELETE "http://localhost:5678/webhook/events/delete?eventId=EVENT_ID"
```

## Workflow Management

### Import Workflows (via n8n UI)
1. Open http://localhost:5678
2. Login: `admin` / `admin`
3. Click **Workflows** → **Import from File**
4. Import each JSON file
5. Configure **Google Calendar credentials**
6. **Save** and **Activate** each workflow

### Import Workflows (via API)
```bash
# Requires N8N_API_KEY environment variable
curl -X POST http://localhost:5678/rest/workflows \
  -H "Content-Type: application/json" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -d @google_calendar_create_event_workflow.json
```

### Workflow Activation Check
```bash
# Check if webhooks are registered
curl -s http://localhost:5678/rest/webhooks

# Check active workflows
curl -s http://localhost:5678/rest/workflows | jq '.data[] | {name: .name, active: .active}'
```

## Common Issues & Troubleshooting

### Issue: "Connection refused" or "Cannot connect"
```bash
# Check if n8n is running
systemctl --user status n8n.service

# If not running, start it
systemctl --user start n8n.service

# Check for errors
journalctl --user -u n8n.service -n 50
```

### Issue: Webhook returns 404
```bash
# Workflows not activated - check n8n UI
# Each workflow must be SAVED and ACTIVATED
```

### Issue: Google Calendar authentication errors
```bash
# Check credentials in n8n UI
# Settings → Credentials → Google Calendar OAuth2 API
# May need to re-authenticate (token expired)
```

### Issue: Permission denied on systemd commands
```bash
# User services don't need sudo
# Use --user flag: systemctl --user ...
```

### Issue: Service won't start
```bash
# Check if port 5678 is in use
lsof -i :5678

# Check n8n binary exists
ls -la ~/.npm-global/bin/n8n

# Check logs for errors
journalctl --user -u n8n.service -n 100 --no-pager
```

## Environment Variables

Service configuration in `~/.config/systemd/user/n8n.service`:

| Variable | Value | Description |
|----------|-------|-------------|
| `N8N_BASIC_AUTH_ACTIVE` | `true` | Enable basic auth |
| `N8N_BASIC_AUTH_USER` | `admin` | Login username |
| `N8N_BASIC_AUTH_PASSWORD` | `admin` | Login password |
| `N8N_PORT` | `5678` | Web UI port |
| `N8N_PROTOCOL` | `http` | Protocol |
| `WEBHOOK_URL` | `http://localhost:5678/` | Webhook base URL |
| `HOME` | `/home/kat` | Home directory |
| `PATH` | `...` | System path |

To modify:
1. Edit `~/.config/systemd/user/n8n.service`
2. Run: `systemctl --user daemon-reload`
3. Run: `systemctl --user restart n8n.service`

## Date/Time Format Reference

All dates must be in **ISO 8601 format** with timezone:

```
2026-03-05T10:00:00-03:00
│    │ │ │  │ │ │  │
│    │ │ │  │ │ │  └── Timezone offset (-03:00 = UTC-3)
│    │ │ │  │ │ └───── Seconds
│    │ │ │  │ └─────── Minutes
│    │ │ │  └───────── Hours
│    │ │ └──────────── Separator
│    │ └────────────── Day
│    └──────────────── Month
└───────────────────── Year
```

**Common Timezones:**
- `-03:00` - Brasília (BRT)
- `-05:00` - Eastern Standard Time (EST)
- `+00:00` - UTC
- `+01:00` - Central European Time (CET)

**Generate current time:**
```bash
# Current time in ISO 8601
date -Iseconds  # Linux

# Tomorrow same time
date -d "+1 day" -Iseconds

# Specific time tomorrow
date -d "tomorrow 14:00" -Iseconds
```

## Quick Reference Commands

```bash
# === SERVICE CONTROL ===
~/n8n-status.sh                 # Check status
~/n8n-start.sh                  # Start n8n
~/n8n-stop.sh                   # Stop n8n
~/n8n-restart.sh                # Restart n8n
~/n8n-logs.sh                   # View logs

# === API TESTING ===
curl http://localhost:5678/healthz

# Create
curl -X POST http://localhost:5678/webhook/events/create \
  -H "Content-Type: application/json" \
  -d '{"summary":"Test","start":"'$(date -d "+1 hour" -Iseconds)'","end":"'$(date -d "+2 hours" -Iseconds)'"}'

# List
curl http://localhost:5678/webhook/events/list?maxResults=5

# Update (replace ID)
curl -X PUT http://localhost:5678/webhook/events/update \
  -H "Content-Type: application/json" \
  -d '{"eventId":"ID","summary":"Updated"}'

# Delete (replace ID)
curl -X DELETE "http://localhost:5678/webhook/events/delete?eventId=ID"

# === FULL TEST ===
~/test_event_crud.sh
```

## Important Notes

1. **Credentials Required:** Google Calendar OAuth2 must be configured in n8n UI before workflows work
2. **Workflows Must Be Active:** Import + Save + Activate each workflow
3. **Event IDs:** Google Calendar event IDs are opaque strings like `abc123xyz_20260305T130000Z`
4. **Timezone Matters:** Always include timezone offset in dates (`-03:00`)
5. **Webhook URLs:** Paths are relative to `http://localhost:5678/webhook/`
6. **Auto-restart:** Service restarts automatically on crash
7. **Logs:** Use `journalctl` to view service logs

## Security Considerations

- Default credentials are `admin`/`admin` - change in production
- OAuth2 tokens stored in n8n database (`~/.n8n/database.sqlite`)
- No HTTPS by default (set `N8N_PROTOCOL=https` for production)
- Webhooks are publicly accessible once activated

## Support Resources

- n8n Docs: https://docs.n8n.io
- Google Calendar API: https://developers.google.com/calendar/api/v3/reference
- This project's README.md for human-friendly setup instructions
