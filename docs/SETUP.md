# Setup Guide

## Prerequisites

1. n8n installed and running
2. Google Cloud account

## Step 1: n8n Installation

If n8n is not installed:

```bash
npm install -g n8n
n8n start
```

Access n8n at: http://localhost:5678

## Step 2: Google Cloud Setup

### Create Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a project" → "New Project"
3. Name it "n8n-calendar-integration"
4. Click "Create"

### Enable Google Calendar API

1. Navigate to "APIs & Services" → "Library"
2. Search for "Google Calendar API"
3. Click "Enable"

### Create OAuth Credentials

1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "OAuth 2.0 Client ID"
3. Configure consent screen:
   - User Type: External
   - App name: "n8n Calendar"
   - User support email: your email
   - Developer contact: your email
4. Add scopes:
   - `https://www.googleapis.com/auth/calendar`
   - `https://www.googleapis.com/auth/calendar.events`
5. Add test users: your email
6. Create OAuth client ID:
   - Application type: Web application
   - Name: "n8n Webhook"
   - Authorized redirect URIs:
     - `http://localhost:5678/rest/oauth2-credential/callback`
   - Click "Create"
7. Copy **Client ID** and **Client Secret**

## Step 3: n8n Credentials Configuration

1. Open n8n: http://localhost:5678
2. Click **Settings** (left sidebar) → **Credentials**
3. Click **Add Credential**
4. Select **Google Calendar OAuth2 API**
5. Fill in:
   - Client ID: (from Google Cloud)
   - Client Secret: (from Google Cloud)
   - Scope: `https://www.googleapis.com/auth/calendar`
6. Click **Sign in with Google**
7. Complete OAuth flow and authorize

## Step 4: Import Workflows

```bash
# Import all workflows
n8n import:workflow --input=workflows/create_event.json
n8n import:workflow --input=workflows/list_events.json
n8n import:workflow --input=workflows/get_event.json
n8n import:workflow --input=workflows/test_webhook.json
```

## Step 5: Activate Workflows

```bash
# Activate all workflows
n8n publish:workflow --id=gcal-create-event --active
n8n publish:workflow --id=gcal-list-events --active
n8n publish:workflow --id=gcal-get-event --active
```

If n8n is running, restart it:

```bash
pkill -f "n8n start"
n8n start
```

## Step 6: Test

### Test Webhook (No Auth Required)

```bash
curl -X POST http://localhost:5678/webhook/test-calendar \
  -H "Content-Type: application/json" \
  -d '{
    "summary": "Test Event",
    "description": "Testing webhook",
    "start": "2026-03-03T16:00:00-03:00",
    "end": "2026-03-03T16:30:00-03:00"
  }'
```

### Test Create Event

```bash
curl -X POST http://localhost:5678/webhook/create-event \
  -H "Content-Type: application/json" \
  -d '{
    "summary": "My Event",
    "description": "Created via n8n",
    "start": "2026-03-03T16:00:00-03:00",
    "end": "2026-03-03T16:30:00-03:00"
  }'
```

### Test List Events

```bash
# Default (last 7 days to next 30 days)
curl http://localhost:5678/webhook/list-events

# With date range and search
curl "http://localhost:5678/webhook/list-events?start=2026-03-01T00:00:00-03:00&end=2026-03-31T23:59:59-03:00&limit=20&search=meeting"
```

### Test Get Event by ID

```bash
curl "http://localhost:5678/webhook/get-event?eventId=your_event_id_here"
```

## Troubleshooting

### "Not authenticated" Error

1. Check credential is connected in n8n UI
2. Re-authenticate via Settings → Credentials
3. Restart n8n after credential update

### Webhook Not Found

1. Ensure workflow is activated
2. Restart n8n after activation
3. Check webhook path matches exactly

### Wrong Timezone

Include timezone offset in datetime:
- Paraguay (UTC-3): `2026-03-03T16:00:00-03:00`
- UTC: `2026-03-03T19:00:00Z`

## API Endpoints Summary

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/webhook/create-event` | POST | Create a new calendar event |
| `/webhook/list-events` | GET/POST | List/search events |
| `/webhook/get-event` | GET | Get event by ID |
| `/webhook/test-calendar` | POST | Test webhook (no auth) |

## Additional Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Google Calendar API Docs](https://developers.google.com/calendar/api/guides/overview)
- [n8n Google Calendar Node](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.googlecalendar/)
