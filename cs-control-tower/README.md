# cs-control-tower
**AI-Powered ERP Control Tower — Flask + Anthropic Claude**

Python 3.12 · Flask 3.1 · SQLAlchemy · RabbitMQ · Port 5000

---

## What it does

Sits on top of the 7-service Burger Bliss Spring Boot ERP ecosystem.

- **Subscribes to `erp.#`** on RabbitMQ — captures every domain event into a local SQLite BI database
- **Two-pass Anthropic NL engine** — translates English questions into API calls and back into English answers
- **6-page Bootstrap 5 dark-theme UI** — Overview, Architecture, Explorer, AI Chat, Events, BI Dashboard

---

## Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| Python | 3.12+ | `python3 --version` to check |
| RabbitMQ | 4.x | `brew services start rabbitmq` |
| Spring Boot services | — | Ports 8081–8087 (optional — app runs without them) |
| Anthropic API key | — | https://console.anthropic.com |

---

## Setup in PyCharm

### Step 1 — Open the project

1. Open **PyCharm**
2. `File → Open` → select the `cs-control-tower` folder
3. PyCharm will detect `requirements.txt` automatically

### Step 2 — Create a virtual environment

**Option A: PyCharm UI (recommended)**

1. `PyCharm → Settings` (or `Preferences` on Mac) → `Project: cs-control-tower → Python Interpreter`
2. Click the gear icon → `Add Interpreter → Add Local Interpreter`
3. Choose **Virtualenv** → Base interpreter: **Python 3.12** → Location: `<project>/venv`
4. Click **OK**
5. PyCharm will prompt to install `requirements.txt` — click **Install**

**Option B: Terminal inside PyCharm**

```bash
# Open Terminal tab (Alt+F12 or View → Tool Windows → Terminal)
python3.12 -m venv venv
source venv/bin/activate          # Mac/Linux
# venv\Scripts\activate           # Windows

pip install --upgrade pip
pip install -r requirements.txt
```

### Step 3 — Create the `.env` file

```bash
cp .env.example .env
```

Open `.env` and fill in your values:

```env
ANTHROPIC_API_KEY=your_anthropic_api_key_here
FLASK_SECRET_KEY=any-random-string-here
FLASK_DEBUG=true
```

> **IMPORTANT:** `.env` is in `.gitignore` — it will NEVER be committed to git.
> Your API key is safe as long as you don't share the `.env` file directly.

### Step 4 — Configure PyCharm Run Configuration

1. Click `Run → Edit Configurations`
2. Click `+` → **Python**
3. Fill in:
   - **Name:** `cs-control-tower`
   - **Script path:** `app.py`
   - **Python interpreter:** the `venv` you created
   - **Working directory:** the `cs-control-tower` folder
4. Click **OK**

### Step 5 — Run

Press the green **▶ Run** button, or `Shift+F10`.

Then open your browser: **http://localhost:5000**

---

## Setup from the Terminal (without PyCharm)

```bash
cd ~/tms_enterprise_poc/cs-control-tower

# Create venv
python3.12 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Configure
cp .env.example .env
# Edit .env and add your ANTHROPIC_API_KEY

# Run
python app.py
```

---

## Full Service Startup Order

Start everything in this order for the full experience:

```bash
# Terminal 1 — RabbitMQ (if not already running)
brew services start rabbitmq

# Terminal 2 — Spring Boot services (each in its own terminal or background)
cd ~/tms_enterprise_poc/cs-crm-api         && java -jar target/*.jar &
cd ~/tms_enterprise_poc/cs-vendor-api       && java -jar target/*.jar &
cd ~/tms_enterprise_poc/cs-procurement-api  && java -jar target/*.jar &
cd ~/tms_enterprise_poc/cs-wms-inbound-api  && java -jar target/*.jar &
cd ~/tms_enterprise_poc/cs-oms-api          && java -jar target/*.jar &
cd ~/tms_enterprise_poc/cs-wms-outbound-api && java -jar target/*.jar &
cd ~/tms_enterprise_poc/cs-tms-api          && java -jar target/*.jar &

# Terminal 3 — UI Dashboard
cd ~/tms_enterprise_poc/cs-ui-dashboard && java -jar target/*.jar &

# Terminal 4 — Control Tower (this app)
cd ~/tms_enterprise_poc/cs-control-tower
source venv/bin/activate
python app.py
```

Then open:
- **Control Tower AI:**  http://localhost:5000
- **ERP Dashboard:**     http://localhost:8090
- **RabbitMQ Console:**  http://localhost:15672 (guest/guest)

---

## Pages

| URL | Description |
|---|---|
| `/` | Overview — health grid, campaign summary, quick AI ask |
| `/architecture` | Educational deep-dive: services, events, AI pipeline, use cases |
| `/explorer` | Live data browser — click any service to load its data |
| `/chat` | AI Chat — ask questions in plain English |
| `/events` | RabbitMQ event feed — every captured domain event |
| `/bi` | BI Dashboard — funnel analytics, delivery tracking |

---

## Example Questions for the AI Chat

```
How many campaigns are active?
What is the available inventory for TOY-DINO-MIX-001?
Show me all completed delivery loads.
Which delivery loads are currently in transit?
How many toys have been allocated to Midwest stores?
List all store orders in ALLOCATED status.
Show me all dispatched shipments.
What is the status of all purchase orders?
Which vendors submitted RFQ quotes?
How many stores have received toys?
```

---

## Project Structure

```
cs-control-tower/
├── app.py                      # Flask app factory + all routes
├── config.py                   # All config from .env
├── requirements.txt
├── .env.example                # Copy to .env — add your API key
├── .gitignore                  # .env is listed here — never committed
├── README.md
│
├── models/
│   ├── __init__.py
│   └── bi_models.py            # SQLAlchemy: ErpEvent, CampaignSummary, DeliveryTracking, ChatHistory
│
├── services/
│   ├── __init__.py
│   ├── anthropic_service.py    # Two-pass NL engine: parse + narrate
│   ├── api_client.py           # HTTP client for all 7 Spring Boot services
│   ├── bi_service.py           # BI query helpers
│   └── rabbitmq_subscriber.py  # Background daemon thread, auto-reconnects
│
└── templates/
    ├── partials/
    │   └── base.html           # Bootstrap 5 dark shared layout
    └── pages/
        ├── home.html           # Hero + health + BI summary + quick chat
        ├── architecture.html   # Educational: services, events, AI pipeline
        ├── explorer.html       # Live data browser
        ├── chat.html           # AI chat interface
        ├── events.html         # RabbitMQ event feed
        └── bi.html             # BI analytics dashboard
```

---

## Architecture: Two-Pass AI Pipeline

```
User types: "How many toys have been delivered?"
         │
         ▼
   Pass 1 — Claude PARSE
   System prompt describes all 7 service APIs
   Claude responds with JSON:
   { "service": "tms", "method": "GET",
     "path": "/api/v1/delivery-loads/status/COMPLETED" }
         │
         ▼
   Flask calls Spring Boot TMS API
   GET http://localhost:8087/api/v1/delivery-loads/status/COMPLETED
         │
         ▼
   Pass 2 — Claude NARRATE
   Raw JSON response + original question sent to Claude
   Claude responds in plain English:
   "Two delivery loads for SUMMER25-TOY are COMPLETED…"
         │
         ▼
   Answer displayed in chat bubble
   Raw JSON available in debug panel
   Interaction saved to chat_history table
```

---

## BI Database

SQLite file created automatically at `control_tower_bi.db` — zero setup needed.

| Table | Purpose |
|---|---|
| `erp_events` | Append-only log of every RabbitMQ message |
| `campaign_summaries` | Denormalised rollup updated per event |
| `delivery_tracking` | Per-load delivery data from POD events |
| `chat_history` | Every AI chat interaction for audit/replay |
