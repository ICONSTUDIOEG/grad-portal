# Grad Portal — Setup Guide

## 1. Frontend (VPS)

**Live URL:** https://grad.iconstudio.tech

Deploy or redeploy from this folder:

```bash
# 1) Push static files to GitHub (one-time: gh auth login)
./scripts/push-github.sh

# 2) Deploy VPS container (pulls from GitHub raw — permanent)
./deploy-mini.sh
```

**Live:** https://grad.iconstudio.tech · **Dashboard:** `/dashboard.html` · **Presentation:** `/presentation.html` · **Balance simulation:** `/balance-simulation.html`

GitHub raw base (default): `https://raw.githubusercontent.com/ICONSTUDIOEG/grad-portal/main`

Override owner/repo/branch in `deploy.config.sh` if needed.

Legacy tmpfiles zip deploy (fallback):

```bash
./deploy-mini.sh zip-url 'https://example.com/bundle.zip'
```

Local dev (same network as n8n on VPS):

```bash
docker compose up -d
```

## 2. n8n Backend

Import **`n8n/grad-portal-api.json`** into [icon98.app.n8n.cloud](https://icon98.app.n8n.cloud):

1. **Workflows → Import from File**
2. Open the workflow and **Activate**
3. Confirm production URLs:
   - `GET  /webhook/grad/data`
   - `POST /webhook/grad/update`
   - `POST /webhook/grad/booking`
   - `POST /webhook/grad/claim`

### WhatsApp notifications (optional)

After each Process node, add a **Twilio** or **WhatsApp Business** node using:

- `notifyMessage` — message body
- `notifyPhones` — array of professor phones (update/booking)
- `studentPhone` — on claim

## 3. Data persistence

The workflow uses **Workflow Static Data** (in-memory on n8n Cloud). For production persistence, replace Code nodes with **Google Sheets**, **Airtable**, or **Postgres**.

Seed data: `n8n/seed-data.json`

## 4. Committee rules (enforced in UI + backend)

- Mandatory path: تصوير → مونتاج → الفولي → مراجعة استيريو → المكساج → DCP → جاهز للتحكيم
- No final mix before foley review confirmed
- Bookings require 48h advance notice
- One booking per date+slot
- First professor to claim gets supervision
