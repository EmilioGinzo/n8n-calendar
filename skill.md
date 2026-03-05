# n8n-calendar Skill

You can manage Google Calendar events and tasks via HTTP calls to a local n8n instance.

**Base URL:** `http://localhost:5678/webhook`
**Calendar timezone:** America/Asuncion (UTC-3/UTC-4)
**Datetime format:** ISO 8601 — `YYYY-MM-DDTHH:MM:SS` or with offset `YYYY-MM-DDTHH:MM:SS-03:00`

---

## Events

### Create an event

```
POST /events/create
Content-Type: application/json
```

**Body:**

| Field | Type | Required | Description |
|---|---|---|---|
| `start` | string | ✅ | Start datetime. e.g. `"2026-03-10T09:00:00-03:00"` |
| `summary` | string | | Event title. Default: `"New Event"` |
| `duration` | number | | Duration in minutes. Default: `60` |
| `description` | string | | Event description |
| `location` | string | | Location string |

> `end` is computed as `start + duration`. You do not need to send `end` separately.

**Example — "On Monday I have a doctor appointment at 8":**

```bash
curl -s -X POST http://localhost:5678/webhook/events/create \
  -H "Content-Type: application/json" \
  -d '{
    "summary": "Doctor Appointment",
    "start": "2026-03-09T08:00:00-03:00",
    "duration": 60
  }'
```

**Response:**

```json
{
  "success": true,
  "eventId": "abc123xyz",
  "htmlLink": "https://www.google.com/calendar/event?eid=...",
  "summary": "Doctor Appointment",
  "start": { "dateTime": "2026-03-09T08:00:00-03:00", "timeZone": "America/Asuncion" },
  "end":   { "dateTime": "2026-03-09T09:00:00-03:00", "timeZone": "America/Asuncion" },
  "message": "Event created successfully"
}
```

Save `eventId` — you need it to update or delete the event.

---

### List events

```
GET /events/list
```

Returns all upcoming events from the primary calendar.

**Example:**

```bash
curl -s http://localhost:5678/webhook/events/list
```

**Response:**

```json
{
  "success": true,
  "count": 5,
  "events": [
    {
      "id": "abc123xyz",
      "summary": "Doctor Appointment",
      "start": { "dateTime": "2026-03-09T08:00:00-03:00" },
      "end":   { "dateTime": "2026-03-09T09:00:00-03:00" },
      "htmlLink": "https://...",
      "description": "",
      "location": "",
      "status": "confirmed"
    }
  ],
  "message": "Events retrieved successfully"
}
```

Use the `id` field from each event as the `eventId` for update/delete.

---

### Update an event

```
PUT /events/update
Content-Type: application/json
```

**Body:**

| Field | Type | Required | Description |
|---|---|---|---|
| `eventId` | string | ✅ | The event `id` returned by create or list |
| `start` | string | | New start datetime |
| `end` | string | | New end datetime |
| `summary` | string | | New title |
| `description` | string | | New description |

**Example — "Move the doctor appointment to 10am":**

```bash
curl -s -X PUT http://localhost:5678/webhook/events/update \
  -H "Content-Type: application/json" \
  -d '{
    "eventId": "abc123xyz",
    "summary": "Doctor Appointment",
    "start": "2026-03-09T10:00:00-03:00",
    "end": "2026-03-09T11:00:00-03:00"
  }'
```

**Response:**

```json
{
  "success": true,
  "eventId": "abc123xyz",
  "summary": "Doctor Appointment",
  "start": { "dateTime": "2026-03-09T10:00:00-03:00" },
  "end":   { "dateTime": "2026-03-09T11:00:00-03:00" },
  "htmlLink": "https://...",
  "message": "Event updated successfully"
}
```

---

### Delete an event

```
DELETE /events/delete?eventId=<id>
```

**Example:**

```bash
curl -s -X DELETE "http://localhost:5678/webhook/events/delete?eventId=abc123xyz"
```

**Response:**

```json
{ "success": true }
```

---

## Tasks

Tasks are stored as all-day Google Calendar events prefixed with 📝 on the primary calendar.

### Create a task

```
POST /tasks/create
Content-Type: application/json
```

**Body:**

| Field | Type | Required | Description |
|---|---|---|---|
| `title` | string | ✅ | Task title |
| `date` | string | | Date for the task. Format: `YYYY-MM-DD`. Default: today |
| `notes` | string | | Task notes/description |

**Example — "Add a task: buy groceries tomorrow":**

```bash
curl -s -X POST http://localhost:5678/webhook/tasks/create \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Buy groceries",
    "date": "2026-03-06",
    "notes": "Milk, eggs, bread"
  }'
```

### List tasks

```
GET /tasks/list
```

Returns all task-type calendar entries.

**Response:**

```json
{
  "success": true,
  "count": 2,
  "tasks": [ ... ],
  "message": "Tasks retrieved successfully"
}
```

### Update a task

```
PUT /tasks/update
Content-Type: application/json
```

| Field | Type | Required | Description |
|---|---|---|---|
| `taskId` | string | ✅ | The event `id` of the task (from list) |
| `title` | string | | New title |
| `date` | string | | New date (`YYYY-MM-DD`) |
| `notes` | string | | New notes |

### Delete a task

```
DELETE /tasks/delete?taskId=<id>
```

---

## Agent reasoning guide

When a user gives a natural language request:

1. **Resolve the date/time** — convert relative expressions ("Monday", "tomorrow", "next week") to absolute `YYYY-MM-DDTHH:MM:SS-03:00`. The local timezone offset is `-03:00`.

2. **Choose the right endpoint:**
   - "create / add / schedule / set up" → POST /events/create
   - "show / list / what do I have / check" → GET /events/list
   - "move / reschedule / change / update" → need the eventId first (GET /events/list), then PUT /events/update
   - "cancel / delete / remove" → need the eventId first (GET /events/list), then DELETE /events/delete

3. **Missing info:** If `start` time is ambiguous, ask the user before calling the API. Duration defaults to 60 minutes if not specified.

4. **Confirm with the user** by showing the `summary`, `start`, and `htmlLink` from the response.

### Example flow

> User: "On Monday I have a doctor appointment at 8, create an event for that"

```bash
# Assuming today is Thursday 2026-03-05, Monday = 2026-03-09
curl -s -X POST http://localhost:5678/webhook/events/create \
  -H "Content-Type: application/json" \
  -d '{
    "summary": "Doctor Appointment",
    "start": "2026-03-09T08:00:00-03:00",
    "duration": 60
  }'
```

Reply to user: "Done! I created **Doctor Appointment** on Monday March 9 from 8:00 to 9:00 AM. [View in Google Calendar](https://...)"
