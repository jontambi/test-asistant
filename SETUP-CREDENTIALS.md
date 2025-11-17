# n8n Credentials Setup Guide

## Required Credentials

### 1. Redis Account
**Credential ID**: `redis-credentials`
**Credential Name**: `Redis Account`
**Type**: Redis

**Configuration**:
- Host: Your Redis server hostname
- Port: 6379 (default)
- Password: Your Redis password (if required)
- Database: 0 (or your preferred database number)

### 2. Anthropic API (HTTP Header Auth)
**Credential ID**: `anthropic-api-header`
**Credential Name**: `Anthropic API Header Auth`
**Type**: HTTP Header Auth

**Configuration**:
- **Name**: `x-api-key`
- **Value**: Your Anthropic API key (get it from https://console.anthropic.com/)

### 3. PostgreSQL Account
**Credential ID**: `postgres-credentials`
**Credential Name**: `PostgreSQL Account`
**Type**: PostgreSQL

**Configuration**:
- Host: Your PostgreSQL server hostname
- Database: Your database name
- User: Your database user
- Password: Your database password
- Port: 5432 (default)
- SSL: Enable if required

---

## Setup Steps

1. **Import the workflow** into n8n
2. **Create Redis credential**:
   - Go to Credentials → New → Redis
   - Name it "Redis Account"
   - Configure connection details
   - Save

3. **Create Anthropic API credential**:
   - Go to Credentials → New → Header Auth
   - Name it "Anthropic API Header Auth"
   - Add header name: `x-api-key`
   - Add header value: Your Anthropic API key
   - Save

4. **Create PostgreSQL credential** (if using patient data management):
   - Go to Credentials → New → PostgreSQL
   - Name it "PostgreSQL Account"
   - Configure connection details
   - Save

5. **Assign credentials to nodes**:
   - Open the workflow
   - Click on "Get Conversation Memory" node → Assign "Redis Account" credential
   - Click on "Save Conversation Memory" node → Assign "Redis Account" credential
   - Click on "Claude AI - Lucía" node → Assign "Anthropic API Header Auth" credential

6. **Test the workflow**:
   - Activate the workflow
   - Use the webhook URL to send a test message
   - Check the execution log for any errors

---

## Troubleshooting

### Redis Connection Issues
- Verify Redis is running
- Check firewall rules
- Confirm credentials are correct

### Anthropic API Issues
- Verify API key is valid
- Check API key has sufficient credits
- Confirm header name is exactly `x-api-key`

### Webhook Not Responding
- Check workflow is activated
- Verify webhook URL is correct
- Look at execution history for errors
