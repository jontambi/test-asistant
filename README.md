# Kids Growing - AI-Powered Pediatric Clinic Assistant

**Lucía**: Your intelligent virtual assistant for pediatric clinic management, powered by Claude AI and N8N.

## Overview

This project provides a complete, production-ready N8N workflow system for managing a pediatric clinic's patient interactions, appointments, and information delivery through multiple channels (web chat, Telegram, and voice).

### Key Features

- **Multi-Channel Support**: Web chat widget, Telegram, and voice calls
- **Intelligent Conversation**: Powered by Claude Haiku for fast, cost-effective responses
- **Appointment Management**: Full integration with Google Calendar
- **Dynamic Pricing**: Real-time pricing lookups from Google Sheets
- **Patient Data Management**: Secure storage with GDPR/HIPAA compliance features
- **Automated Reminders**: 24-hour and 1-hour appointment reminders via email and Telegram
- **Emergency Detection**: Automatic identification of urgent medical situations
- **Conversation Memory**: Context-aware conversations using Redis
- **Bilingual Ready**: Spanish by default, easily adaptable to other languages

## Architecture

```
┌─────────────────┐
│   User Input    │ (Web, Telegram, Voice)
└────────┬────────┘
         │
         v
┌─────────────────────────────────────────┐
│  Main Conversation Handler (N8N)        │
│  - Webhook receiver                     │
│  - Emergency detection                  │
│  - Claude AI integration                │
│  - Conversation memory (Redis)          │
└──────────┬──────────────────────────────┘
           │
           v
┌──────────────────────────────────────────────┐
│  Sub-Workflows (Called as needed)            │
├──────────────────────────────────────────────┤
│  1. Appointment Management                   │
│     - Google Calendar integration            │
│     - Availability checking                  │
│     - Create/Update/Cancel appointments      │
│                                              │
│  2. Pricing Lookup                           │
│     - Google Sheets integration              │
│     - Service search and matching            │
│                                              │
│  3. Patient Data Management                  │
│     - PostgreSQL database                    │
│     - CRUD operations                        │
│     - Compliance logging                     │
│                                              │
│  4. Appointment Reminders                    │
│     - Scheduled trigger (every 30 min)       │
│     - Multi-channel notifications            │
│     - Delivery tracking                      │
└──────────────────────────────────────────────┘
```

## Project Structure

```
test-asistant/
├── workflows/              # N8N workflow JSON files
│   ├── 01-main-conversation-handler.json
│   ├── 02-appointment-management.json
│   ├── 03-pricing-lookup.json
│   ├── 04-patient-data-management.json
│   └── 05-appointment-reminders.json
├── config/                 # Configuration files
│   ├── .env.example
│   ├── database-schema.sql
│   └── google-sheets-pricing-template.md
├── docs/                   # Documentation
│   ├── SETUP.md
│   ├── DEPLOYMENT.md
│   ├── API.md
│   └── TESTING.md
└── README.md
```

## Quick Start

### Prerequisites

- [N8N](https://n8n.io/) instance (self-hosted or cloud)
- PostgreSQL database (version 12+)
- Redis server (for session management)
- Anthropic API key (Claude AI)
- Google Cloud account (for Calendar and Sheets APIs)
- Telegram Bot (via @BotFather)
- SMTP server (for email)

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/jontambi/test-asistant.git
   cd test-asistant
   ```

2. **Set up the database**
   ```bash
   psql -U your_user -d your_database -f config/database-schema.sql
   ```

3. **Configure environment variables**
   ```bash
   cp config/.env.example config/.env
   # Edit .env and fill in your actual credentials
   ```

4. **Set up Google Sheets pricing**
   - Follow the guide in `config/google-sheets-pricing-template.md`
   - Create your pricing sheet and get the Sheet ID

5. **Import N8N workflows**
   - Open your N8N instance
   - Go to Workflows → Import from File
   - Import each workflow from the `workflows/` folder
   - **Import order**: Start with `01-main-conversation-handler.json`, then the others

6. **Configure N8N credentials**
   - Anthropic API (Claude)
   - Google Calendar OAuth2
   - Google Sheets OAuth2
   - PostgreSQL
   - Redis
   - SMTP

7. **Activate workflows**
   - Enable all imported workflows in N8N
   - Test each webhook endpoint

8. **Test the system**
   ```bash
   curl -X POST https://your-n8n-instance.com/webhook/lucia-chat \
     -H "Content-Type: application/json" \
     -d '{
       "message": "Hola, necesito información sobre consultas",
       "sessionId": "test-123",
       "userId": "user-456",
       "channel": "web"
     }'
   ```

## Workflows Overview

### 1. Main Conversation Handler
**File**: `01-main-conversation-handler.json`

**Purpose**: Core conversation management with Claude AI

**Features**:
- Receives messages from all channels
- Manages conversation memory (Redis)
- Detects emergencies
- Routes to appropriate sub-workflows
- Returns AI-generated responses

**Webhook**: `/lucia-chat`

### 2. Appointment Management
**File**: `02-appointment-management.json`

**Purpose**: Google Calendar integration for appointments

**Features**:
- Check availability
- Create appointments
- Update appointments
- Cancel appointments

**Webhook**: `/lucia-appointments`

### 3. Pricing Lookup
**File**: `03-pricing-lookup.json`

**Purpose**: Real-time pricing from Google Sheets

**Features**:
- Search by service name
- Filter by category
- Free-text search
- Formatted responses

**Webhook**: `/lucia-pricing`

### 4. Patient Data Management
**File**: `04-patient-data-management.json`

**Purpose**: Patient information CRUD operations

**Features**:
- Create patient records
- Update patient information
- Search patients
- GDPR/HIPAA compliance logging
- Data privacy controls

**Webhook**: `/lucia-patient-data`

### 5. Appointment Reminders
**File**: `05-appointment-reminders.json`

**Purpose**: Automated appointment reminders

**Features**:
- Runs every 30 minutes
- 24-hour reminders
- 1-hour reminders
- Multi-channel delivery (Email, Telegram)
- Delivery tracking

**Trigger**: Scheduled (cron: `0 */30 * * * *`)

## Configuration

### Environment Variables

All configuration is managed through environment variables. See `config/.env.example` for the complete list.

**Critical variables**:
- `ANTHROPIC_API_KEY`: Your Claude AI API key
- `GOOGLE_SHEET_PRICING_ID`: Your pricing Google Sheet ID
- `POSTGRES_*`: Database connection details
- `REDIS_*`: Redis connection details
- `TELEGRAM_BOT_TOKEN`: Telegram bot credentials

### Customization

#### Modify the AI Personality

Edit the system prompt in `01-main-conversation-handler.json`:

```json
{
  "parameters": {
    "systemMessage": "Your custom prompt here..."
  }
}
```

#### Adjust Clinic Information

Update clinic details in the database:

```sql
UPDATE clinic_settings
SET setting_value = 'New Value'
WHERE setting_key = 'clinic_name';
```

#### Modify Reminder Schedule

Change the cron expression in `05-appointment-reminders.json`:

```json
{
  "parameters": {
    "rule": {
      "interval": [
        {
          "field": "cronExpression",
          "expression": "0 */15 * * * *"  // Every 15 minutes
        }
      ]
    }
  }
}
```

## API Documentation

### Chat Webhook

**Endpoint**: `POST /webhook/lucia-chat`

**Request**:
```json
{
  "message": "Hola, quiero agendar una cita",
  "sessionId": "unique-session-id",
  "userId": "user-identifier",
  "channel": "web"
}
```

**Response**:
```json
{
  "success": true,
  "sessionId": "unique-session-id",
  "response": "¡Hola! Con gusto te ayudo a agendar una cita...",
  "responseType": "normal",
  "timestamp": "2025-11-13T00:00:00.000Z"
}
```

### Appointments Webhook

**Endpoint**: `POST /webhook/lucia-appointments`

**Check Availability**:
```json
{
  "action": "check_availability",
  "appointmentData": {
    "preferredDate": "2025-11-15"
  },
  "sessionId": "session-123"
}
```

**Create Appointment**:
```json
{
  "action": "create",
  "appointmentData": {
    "patientName": "Juan Pérez",
    "patientAge": 5,
    "parentName": "María Pérez",
    "parentEmail": "maria@example.com",
    "parentPhone": "+1234567890",
    "reasonForVisit": "Control de niño sano",
    "preferredDate": "2025-11-15",
    "preferredTime": "10:00"
  },
  "sessionId": "session-123"
}
```

See `docs/API.md` for complete API documentation.

## Security & Compliance

### Data Privacy

- Patient data is encrypted at rest
- Access logging for GDPR/HIPAA compliance
- Automatic session expiration
- Sensitive data masking in responses

### Best Practices

1. **Never commit `.env` files** - Always use `.env.example` as template
2. **Rotate credentials regularly** - Update API keys and tokens periodically
3. **Enable webhook authentication** - Use `N8N_WEBHOOK_AUTH_TOKEN`
4. **Monitor access logs** - Review `patient_activity_log` table regularly
5. **Backup database** - Schedule regular PostgreSQL backups
6. **Use HTTPS** - Always use SSL/TLS for webhooks
7. **Limit API access** - Use CORS and IP whitelisting

## Monitoring & Maintenance

### Health Checks

Monitor these endpoints regularly:
- Database connectivity
- Redis availability
- Google APIs status
- Telegram Bot API status
- N8N workflow execution logs

### Logs

Check N8N execution logs for:
- Failed workflows
- API errors
- Database connection issues
- Reminder delivery failures

### Performance

Monitor:
- Webhook response times
- Database query performance
- Redis memory usage
- API rate limits (Anthropic, Google, Telegram)

## Troubleshooting

### Common Issues

**Issue**: Workflows not triggering
- **Solution**: Check that workflows are activated in N8N
- Verify webhook URLs are correct
- Check firewall/network settings

**Issue**: Claude AI not responding
- **Solution**: Verify `ANTHROPIC_API_KEY` is valid
- Check API quota and rate limits
- Review error logs in N8N

**Issue**: Reminders not sending
- **Solution**: Check cron schedule is active
- Verify Telegram Bot Token and SMTP credentials
- Check database connection
- Review `reminder_log` table for errors

**Issue**: Google Calendar not syncing
- **Solution**: Re-authenticate Google Calendar OAuth2
- Verify calendar sharing with service account
- Check API quotas

## Support & Contributing

### Getting Help

- **Documentation**: Check `docs/` folder
- **Issues**: Open an issue on GitHub
- **Discussions**: Use GitHub Discussions

### Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- **Anthropic** for Claude AI
- **N8N** for workflow automation
- **Google** for Calendar and Sheets APIs
- **Telegram** for Bot API

## Roadmap

- [ ] Voice call integration
- [ ] Multi-language support (English, Portuguese)
- [ ] Payment processing integration
- [ ] Advanced analytics dashboard
- [ ] Mobile app for clinic staff
- [ ] AI-powered appointment optimization
- [ ] Integration with electronic health records (EHR)
- [ ] Telemedicine video consultations

---

**Built with ❤️ for Kids Growing Pediatric Clinic**

For detailed setup instructions, see `docs/SETUP.md`
