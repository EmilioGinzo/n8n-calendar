# 🗓️ n8n Google Calendar Workflow

Automated Google Calendar event management using n8n workflows with webhook triggers.

## ✨ Features

- ✅ **Create** Google Calendar events via webhook API
- 🔍 **List** events with date range, search filters, and pagination
- 📖 **Get** single event details with full error handling
- 🌎 Paraguay timezone support (America/Asuncion - UTC-3)
- 🔐 OAuth2 authentication with Google
- 📱 JSON API for easy integration
- 🧪 Test webhook included for debugging

## 📁 Project Structure

```
.
├── workflows/                  # n8n workflow JSON files
│   ├── create_event.json            # Create calendar events
│   ├── list_events.json             # List/search events
│   ├── get_event.json               # Get single event by ID
│   └── test_webhook.json            # Test/debug webhook
├── docs/
│   └── SETUP.md                     # Detailed setup instructions
└── README.md                        # This file
```

## 🚀 Quick Start

### 1. Import Workflows

```bash
n8n import:workflow --input=workflows/create_event.json
n8n import:workflow --input=workflows/list_events.json
n8n import:workflow --input=workflows/get_event.json
```

### 2. Configure Google OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a project and enable **Google Calendar API**
3. Create OAuth 2.0 credentials
4. Add redirect URI: `http://localhost:5678/rest/oauth2-credential/callback`
5. Copy Client ID and Secret to n8n credentials

### 3. Activate Workflows

```bash
n8n publish:workflow --id=gcal-create-event --active
n8n publish:workflow --id=gcal-list-events --active
n8n publish:workflow --id=gcal-get-event --active
```

## 📡 API Reference

### Create Event

**Endpoint:** `POST /webhook/create-event`

```bash
curl -X POST http://localhost:5678/webhook/create-event \
  -H "Content-Type: application/json" \
  -d '{
    "summary": "Team Meeting",
    "description": "Weekly sync",
    "start": "2026-03-03T16:00:00-03:00",
    "end": "2026-03-03T16:30:00-03:00"
  }'
```

**Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `summary` | string | ✅ | Event title |
| `description` | string | ❌ | Event description |
| `start` | string | ✅ | Start time (ISO 8601 with timezone) |
| `end` | string | ✅ | End time (ISO 8601 with timezone) |
| `location` | string | ❌ | Event location |
| `attendees` | array | ❌ | List of attendee emails |

---

### List Events

**Endpoint:** `GET /webhook/list-events` or `POST /webhook/list-events`

**GET Request (query parameters):**
```bash
curl "http://localhost:5678/webhook/list-events?start=2026-03-01T00:00:00-03:00&end=2026-03-31T23:59:59-03:00&limit=20&search=meeting"
```

**POST Request (JSON body):**
```bash
curl -X POST http://localhost:5678/webhook/list-events \
  -H "Content-Type: application/json" \
  -d '{
    "start": "2026-03-01T00:00:00-03:00",
    "end": "2026-03-31T23:59:59-03:00",
    "limit": 20,
    "search": "meeting",
    "calendar": "primary"
  }'
```

**Parameters:**
| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `start` | string | 7 days ago | Start of date range (ISO 8601) |
| `end` | string | 30 days ahead | End of date range (ISO 8601) |
| `limit` | number | 10 | Max events to return (max 250) |
| `search` | string | - | Search term for event title/description |
| `calendar` | string | primary | Calendar ID to search |

**Response:**
```json
{
  "success": true,
  "timezone": "America/Asuncion",
  "count": 2,
  "events": [
    {
      "id": "abc123",
      "summary": "Team Meeting",
      "description": "Weekly sync",
      "location": "Conference Room A",
      "start": "2026-03-03T16:00:00-03:00",
      "end": "2026-03-03T16:30:00-03:00",
      "htmlLink": "https://www.google.com/calendar/event?eid=...",
      "status": "confirmed",
      "creator": "user@example.com",
      "attendees": [...]
    }
  ]
}
```

---

### Get Event by ID

**Endpoint:** `GET /webhook/get-event`

```bash
curl "http://localhost:5678/webhook/get-event?eventId=abc123"
```

**Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `eventId` or `id` | string | ✅ | The event ID from Google Calendar |
| `calendar` | string | ❌ | Calendar ID (default: primary) |

**Error Response (event not found):**
```json
{
  "success": false,
  "error": "Event not found",
  "code": "EVENT_NOT_FOUND",
  "message": "The requested event could not be found"
}
```

**Success Response:**
```json
{
  "success": true,
  "timezone": "America/Asuncion",
  "event": {
    "id": "abc123",
    "summary": "Team Meeting",
    "description": "Weekly sync",
    "location": "Conference Room A",
    "start": "2026-03-03T16:00:00-03:00",
    "end": "2026-03-03T16:30:00-03:00",
    "htmlLink": "https://www.google.com/calendar/event?eid=...",
    "status": "confirmed",
    "creator": "user@example.com",
    "organizer": "user@example.com",
    "attendees": [...],
    "hangoutLink": "https://meet.google.com/...",
    "conferenceData": {...},
    "recurringEventId": "...",
    "attachments": [...]
  }
}
```

---

### Test Webhook

**Endpoint:** `POST /webhook/test-calendar`

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

## 🌎 Timezone Support

For **Paraguay (Asunción, UTC-3)**, include the timezone offset in your datetimes:

```json
{
  "start": "2026-03-03T16:00:00-03:00",
  "end": "2026-03-03T16:30:00-03:00"
}
```

Or use UTC format:
```json
{
  "start": "2026-03-03T19:00:00Z",
  "end": "2026-03-03T19:30:00Z"
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
