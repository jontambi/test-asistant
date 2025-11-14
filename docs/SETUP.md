# Complete Setup Guide

This guide will walk you through setting up the Kids Growing Pediatric Clinic Assistant from scratch.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [N8N Installation](#n8n-installation)
3. [Database Setup](#database-setup)
4. [Redis Setup](#redis-setup)
5. [Google Cloud Setup](#google-cloud-setup)
6. [Anthropic Claude Setup](#anthropic-claude-setup)
7. [Twilio Setup](#twilio-setup)
8. [WhatsApp Business Setup](#whatsapp-business-setup)
9. [SMTP Email Setup](#smtp-email-setup)
10. [Import Workflows](#import-workflows)
11. [Configure Credentials](#configure-credentials)
12. [Testing](#testing)
13. [Going Live](#going-live)

---

## Prerequisites

### Required Services

- **N8N** (v1.0+): Workflow automation platform
- **PostgreSQL** (v12+): Database
- **Redis** (v6+): Session storage
- **Node.js** (v18+): For N8N

### Required Accounts

- Anthropic account (Claude AI)
- Google Cloud Platform account
- Twilio account (for SMS)
- SMTP email provider (Gmail, SendGrid, etc.)
- WhatsApp Business account (optional)

### System Requirements

- **Server**: 2GB RAM minimum (4GB recommended)
- **Storage**: 10GB minimum
- **OS**: Linux (Ubuntu 20.04+ recommended), macOS, or Windows
- **Network**: Public IP or domain for webhooks

---

## N8N Installation

### Option 1: Docker (Recommended)

```bash
# Create docker-compose.yml
version: '3.8'
services:
  n8n:
    image: n8nio/n8n:latest
    restart: always
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=your_secure_password
      - N8N_HOST=your-domain.com
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=https://your-domain.com/
    volumes:
      - n8n_data:/home/node/.n8n

volumes:
  n8n_data:
```

```bash
# Start N8N
docker-compose up -d
```

### Option 2: npm

```bash
# Install N8N globally
npm install n8n -g

# Start N8N
n8n start

# Or with environment variables
N8N_BASIC_AUTH_ACTIVE=true \
N8N_BASIC_AUTH_USER=admin \
N8N_BASIC_AUTH_PASSWORD=your_password \
n8n start
```

### Option 3: N8N Cloud

1. Go to [n8n.cloud](https://n8n.cloud)
2. Sign up for an account
3. Create a new instance
4. No installation needed!

### Verify Installation

Access N8N at: `http://localhost:5678` (or your domain)

---

## Database Setup

### PostgreSQL Installation

#### Ubuntu/Debian
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
```

#### macOS (Homebrew)
```bash
brew install postgresql
brew services start postgresql
```

#### Docker
```bash
docker run --name postgres-clinic \
  -e POSTGRES_PASSWORD=your_password \
  -e POSTGRES_DB=kids_growing_clinic \
  -p 5432:5432 \
  -d postgres:14
```

### Create Database and User

```bash
# Connect to PostgreSQL
sudo -u postgres psql

# Create database and user
CREATE DATABASE kids_growing_clinic;
CREATE USER clinic_admin WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE kids_growing_clinic TO clinic_admin;
\q
```

### Import Schema

```bash
# Navigate to project directory
cd test-asistant

# Import the database schema
psql -U clinic_admin -d kids_growing_clinic -f config/database-schema.sql

# Verify tables were created
psql -U clinic_admin -d kids_growing_clinic -c "\dt"
```

### Expected Output

You should see these tables:
- `patients`
- `appointments`
- `patient_activity_log`
- `reminder_log`
- `conversation_sessions`
- `faq_categories`
- `faqs`
- `clinic_settings`

---

## Redis Setup

### Installation

#### Ubuntu/Debian
```bash
sudo apt update
sudo apt install redis-server
sudo systemctl enable redis-server
sudo systemctl start redis-server
```

#### macOS (Homebrew)
```bash
brew install redis
brew services start redis
```

#### Docker
```bash
docker run --name redis-clinic \
  -p 6379:6379 \
  -d redis:7-alpine redis-server --requirepass your_redis_password
```

### Configure Redis

Edit `/etc/redis/redis.conf`:

```conf
# Set password
requirepass your_secure_redis_password

# Set max memory (adjust based on your needs)
maxmemory 256mb
maxmemory-policy allkeys-lru

# Enable persistence (optional)
save 900 1
save 300 10
save 60 10000
```

Restart Redis:
```bash
sudo systemctl restart redis-server
```

### Test Redis

```bash
redis-cli
AUTH your_redis_password
PING
# Should return: PONG
```

---

## Google Cloud Setup

### 1. Create a Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a project" → "New Project"
3. Name: "Kids Growing Clinic"
4. Click "Create"

### 2. Enable APIs

```bash
# Navigate to APIs & Services → Library
# Enable these APIs:
- Google Calendar API
- Google Sheets API
```

Or use gcloud CLI:
```bash
gcloud services enable calendar-json.googleapis.com
gcloud services enable sheets.googleapis.com
```

### 3. Create Service Account

1. Go to "IAM & Admin" → "Service Accounts"
2. Click "Create Service Account"
3. Name: "lucia-clinic-assistant"
4. Role: "Editor"
5. Click "Done"

### 4. Create Service Account Key

1. Click on the service account
2. Go to "Keys" tab
3. "Add Key" → "Create new key"
4. Select "JSON"
5. Download the key file
6. **IMPORTANT**: Keep this file secure!

### 5. Set Up Google Calendar

1. Open [Google Calendar](https://calendar.google.com)
2. Create a new calendar: "Kids Growing - Citas"
3. Click settings (gear icon) → "Settings for my calendars"
4. Select your calendar → "Share with specific people"
5. Add your service account email (from the JSON file)
6. Give "Make changes to events" permission
7. Copy the Calendar ID (under "Integrate calendar")

### 6. Set Up Google Sheets

Follow the detailed guide in `config/google-sheets-pricing-template.md`

**Quick steps**:
1. Create a new Google Sheet
2. Name it "Kids Growing - Tarifas"
3. Add pricing data (see template)
4. Share with service account email (Editor permission)
5. Copy the Sheet ID from URL

---

## Anthropic Claude Setup

### 1. Create Account

1. Go to [Anthropic Console](https://console.anthropic.com/)
2. Sign up or log in
3. Navigate to "API Keys"

### 2. Generate API Key

1. Click "Create API Key"
2. Name: "Kids Growing Clinic - Production"
3. Copy the key immediately (won't be shown again)
4. Store securely in your `.env` file

### 3. Set Up Billing

1. Go to "Billing" section
2. Add payment method
3. Set usage limits (recommended: $50-100/month for small clinic)

### 4. Test API Access

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-3-haiku-20240307",
    "max_tokens": 1024,
    "messages": [{
      "role": "user",
      "content": "Hola"
    }]
  }'
```

---

## Twilio Setup

### 1. Create Account

1. Go to [Twilio](https://www.twilio.com)
2. Sign up for an account
3. Verify your email and phone

### 2. Get Credentials

1. Go to Console Dashboard
2. Copy these values:
   - Account SID
   - Auth Token

### 3. Get Phone Number

1. Go to "Phone Numbers" → "Buy a number"
2. Select country (Mexico for Kids Growing)
3. Check "SMS" capability
4. Purchase number
5. Copy the phone number (format: +1234567890)

### 4. Configure SMS

1. Click on your phone number
2. Under "Messaging Configuration":
   - Set webhook for incoming SMS (if you want two-way SMS)
   - URL: `https://your-n8n-instance.com/webhook/lucia-chat`
   - Method: POST

### 5. Add Credits

1. Go to "Billing"
2. Add funds (recommended: $20-50 to start)
3. Enable auto-recharge (optional)

---

## WhatsApp Business Setup

### Option 1: Twilio (Easier)

1. In Twilio Console, go to "Messaging" → "Try WhatsApp"
2. Follow setup wizard
3. Get WhatsApp-enabled phone number
4. Use same credentials as SMS

### Option 2: Meta Business (More features)

1. Go to [Facebook Business](https://business.facebook.com)
2. Create Business Manager account
3. Add WhatsApp Business Account
4. Complete verification process
5. Get credentials:
   - Phone Number ID
   - Access Token
   - Business Account ID

**Note**: Meta WhatsApp requires business verification (can take 1-2 weeks)

---

## SMTP Email Setup

### Option 1: Gmail

1. Enable 2-factor authentication on your Google account
2. Generate App Password:
   - Go to Google Account → Security
   - "2-Step Verification" → "App passwords"
   - Select "Mail" and "Other (Custom name)"
   - Copy the 16-character password

Configuration:
```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

### Option 2: SendGrid

1. Sign up at [SendGrid](https://sendgrid.com)
2. Create API Key
3. Verify sender email

Configuration:
```env
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=apikey
SMTP_PASSWORD=your-sendgrid-api-key
```

### Option 3: Amazon SES

1. Go to AWS SES Console
2. Verify domain or email
3. Create SMTP credentials

---

## Import Workflows

### 1. Download Workflows

If you haven't cloned the repository:
```bash
git clone https://github.com/jontambi/test-asistant.git
cd test-asistant
```

### 2. Import to N8N

#### Via UI:
1. Open N8N interface
2. Click "Workflows" in sidebar
3. Click "Import from File"
4. Select workflow JSON file
5. Click "Import"

Repeat for all 5 workflows in order:
1. `01-main-conversation-handler.json`
2. `02-appointment-management.json`
3. `03-pricing-lookup.json`
4. `04-patient-data-management.json`
5. `05-appointment-reminders.json`

#### Via CLI:
```bash
# Copy workflows to N8N directory
cp workflows/*.json ~/.n8n/workflows/
```

### 3. Verify Import

Check that all workflows appear in N8N:
- Go to "Workflows"
- You should see 5 workflows
- Each should show "Inactive" status initially

---

## Configure Credentials

### 1. Create .env File

```bash
cp config/.env.example config/.env
nano config/.env  # Or use your preferred editor
```

Fill in all values from previous steps.

### 2. Add Credentials to N8N

#### Anthropic (Claude AI)

1. Go to "Credentials" → "Create New"
2. Select "Anthropic API"
3. Name: "Anthropic API"
4. API Key: [Your Anthropic API key]
5. Save

#### PostgreSQL

1. "Create New" → "PostgreSQL"
2. Name: "PostgreSQL Account"
3. Fill in:
   - Host: localhost (or your host)
   - Database: kids_growing_clinic
   - User: clinic_admin
   - Password: [your password]
   - Port: 5432
4. Test connection
5. Save

#### Redis

1. "Create New" → "Redis"
2. Name: "Redis Account"
3. Fill in:
   - Host: localhost
   - Port: 6379
   - Password: [your Redis password]
   - Database: 0
4. Save

#### Google Calendar

1. "Create New" → "Google Calendar OAuth2 API"
2. Name: "Google Calendar Account"
3. Select "Service Account"
4. Upload JSON key file
5. Save

#### Google Sheets

1. "Create New" → "Google Sheets API"
2. Name: "Google Sheets Account"
3. Select "Service Account"
4. Upload same JSON key file
5. Save

#### Twilio

1. "Create New" → "Twilio API"
2. Name: "Twilio Account"
3. Fill in:
   - Account SID
   - Auth Token
4. Save

#### SMTP Email

1. "Create New" → "SMTP"
2. Name: "SMTP Account"
3. Fill in your SMTP details
4. Test connection
5. Save

### 3. Update Workflow Credentials

For each workflow:
1. Open the workflow
2. Click on nodes that show "No credentials selected"
3. Select the appropriate credential
4. Save workflow

---

## Testing

### 1. Test Database Connection

```bash
psql -U clinic_admin -d kids_growing_clinic -c "SELECT * FROM clinic_settings;"
```

### 2. Test Redis

```bash
redis-cli -a your_password PING
```

### 3. Test Main Conversation Workflow

```bash
curl -X POST https://your-n8n-instance.com/webhook/lucia-chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hola",
    "sessionId": "test-session-001",
    "userId": "test-user-001",
    "channel": "web"
  }'
```

Expected response:
```json
{
  "success": true,
  "sessionId": "test-session-001",
  "response": "¡Hola! Soy Lucía, asistente virtual de Kids Growing...",
  "responseType": "normal",
  "timestamp": "2025-11-13T..."
}
```

### 4. Test Pricing Lookup

```bash
curl -X POST https://your-n8n-instance.com/webhook/lucia-pricing \
  -H "Content-Type: application/json" \
  -d '{
    "searchQuery": "consulta",
    "sessionId": "test-session-002"
  }'
```

### 5. Test Appointment Check

```bash
curl -X POST https://your-n8n-instance.com/webhook/lucia-appointments \
  -H "Content-Type: application/json" \
  -d '{
    "action": "check_availability",
    "appointmentData": {
      "preferredDate": "2025-11-20"
    },
    "sessionId": "test-session-003"
  }'
```

### 6. Activate All Workflows

1. Open each workflow in N8N
2. Click "Active" toggle in top right
3. Verify webhook URLs are accessible

---

## Going Live

### 1. Security Checklist

- [ ] Change all default passwords
- [ ] Enable HTTPS/SSL on N8N
- [ ] Set up firewall rules
- [ ] Enable N8N webhook authentication
- [ ] Review database permissions
- [ ] Set up backup automation
- [ ] Enable error monitoring (Sentry, etc.)

### 2. Production Settings

Update `.env`:
```env
NODE_ENV=production
TEST_MODE=false
LOG_LEVEL=info
```

### 3. Set Up Monitoring

```bash
# Set up automated backups
0 2 * * * pg_dump -U clinic_admin kids_growing_clinic > /backup/clinic_$(date +\%Y\%m\%d).sql

# Monitor N8N logs
tail -f ~/.n8n/logs/n8n.log
```

### 4. Launch Checklist

- [ ] All workflows active
- [ ] All credentials configured
- [ ] Database populated with initial data
- [ ] Google Sheets pricing up-to-date
- [ ] Test all features end-to-end
- [ ] Verify reminders are working
- [ ] Document webhook URLs for integration
- [ ] Train staff on system usage

### 5. Integration with Website

Add chat widget to your website:

```html
<!-- Add to your website -->
<script>
window.luciaChat = {
  webhookUrl: 'https://your-n8n-instance.com/webhook/lucia-chat',
  sessionId: generateSessionId(), // Your implementation
  userId: getCurrentUserId() // Your implementation
};
</script>
<script src="https://your-cdn.com/lucia-chat-widget.js"></script>
```

---

## Next Steps

1. Read `docs/DEPLOYMENT.md` for production deployment best practices
2. Review `docs/API.md` for integration documentation
3. Check `docs/TESTING.md` for comprehensive testing procedures

## Support

If you encounter issues:
1. Check N8N execution logs
2. Review database logs
3. Verify all credentials are correct
4. Consult troubleshooting section in README.md
5. Open an issue on GitHub

---

**Congratulations! Your Kids Growing Clinic Assistant is now set up! 🎉**
