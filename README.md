# 🗓️ n8n Google Calendar Workflow

Automated Google Calendar event creation using n8n workflows with webhook triggers.

## ✨ Features

- ✅ Create Google Calendar events via webhook API
- 🌎 Paraguay timezone support (America/Asuncion - UTC-3)
- 🔐 OAuth2 authentication with Google
- 📱 JSON API for easy integration
- 🧪 Test webhook included for debugging

## 📁 Project Structure

```
.
├── workflows/                  # n8n workflow JSON files
│   ├── complete_workflow.json       # Main workflow (summary, description, start, end)
│   ├── gcal_paraguay.json           # Paraguay timezone optimized
│   ├── google_calendar_event_creator.json  # Original working workflow
│   └── test_webhook.json            # Test/debug webhook
├── docs/
│   └── SETUP.md                     # Detailed setup instructions
└── README.md                        # This file
```

## 🚀 Quick Start

### 1. Import Workflows

```bash
n8n import:workflow --input=workflows/gcal_paraguay.json
```

### 2. Configure Google OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a project and enable **Google Calendar API**
3. Create OAuth 2.0 credentials
4. Add redirect URI: `http://localhost:5678/rest/oauth2-credential/callback`
5. Copy Client ID and Secret to n8n credentials

### 3. Activate Workflow

```bash
n8n publish:workflow --id=gcal-paraguay --active
```

### 4. Create an Event

```bash
curl -X POST http://localhost:5678/webhook/create-py \
  -H "Content-Type: application/json" \
  -d '{
    "summary": "Team Meeting",
    "description": "Weekly sync",
    "start": "2026-03-03T16:00:00-03:00",
    "end": "2026-03-03T16:30:00-03:00"
  }'
```

## 🌎 Timezone Support

For **Paraguay (Asunción, UTC-3)**, include the timezone offset in your request:

```json
{
  "start": "2026-03-03T16:00:00-03:00",
  "end": "2026-03-03T16:30:00-03:00"
}
```

## 📡 API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/webhook/create-py` | POST | Create event with Paraguay timezone |
| `/webhook/create-complete` | POST | Create event (all fields) |
| `/webhook/test-calendar` | POST | Test webhook (no Google auth needed) |

### Request Body Format

```json
{
  "summary": "Event Title",
  "description": "Event Description",
  "start": "2026-03-03T16:00:00-03:00",
  "end": "2026-03-03T16:30:00-03:00"
}
```

### Response Format

```json
{
  "kind": "calendar#event",
  "id": "event_id_here",
  "status": "confirmed",
  "summary": "Event Title",
  "description": "Event Description",
  "htmlLink": "https://www.google.com/calendar/event?eid=...",
  "start": {
    "dateTime": "2026-03-03T16:00:00-03:00"
  },
  "end": {
    "dateTime": "2026-03-03T16:30:00-03:00"
  }
}
```

## 🔧 Requirements

- [n8n](https://n8n.io/) >= 1.0
- Google Calendar API access
- OAuth 2.0 credentials

## 📝 License

MIT License - feel free to use and modify!

## 🙏 Credits

Created with n8n workflow automation platform.
