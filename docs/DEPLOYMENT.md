# Production Deployment Guide

This guide covers deploying the Kids Growing Clinic Assistant to a production environment.

## Table of Contents

1. [Infrastructure Options](#infrastructure-options)
2. [Pre-Deployment Checklist](#pre-deployment-checklist)
3. [Docker Deployment](#docker-deployment)
4. [Cloud Deployment](#cloud-deployment)
5. [SSL/HTTPS Setup](#sslhttps-setup)
6. [Monitoring & Logging](#monitoring--logging)
7. [Backup & Recovery](#backup--recovery)
8. [Scaling](#scaling)
9. [Security Hardening](#security-hardening)
10. [Maintenance](#maintenance)

---

## Infrastructure Options

### Option 1: Single Server (Small Clinic)

**Recommended for**: < 500 patients, < 50 appointments/day

- **Server**: 1 VPS (4GB RAM, 2 CPU, 40GB SSD)
- **Cost**: ~$20-40/month
- **Providers**: DigitalOcean, Linode, Hetzner, AWS Lightsail

### Option 2: Multi-Server (Medium Clinic)

**Recommended for**: 500-2000 patients, 50-200 appointments/day

- **App Server**: N8N (4GB RAM, 2 CPU)
- **Database Server**: PostgreSQL (4GB RAM, 2 CPU)
- **Cache Server**: Redis (2GB RAM, 1 CPU)
- **Cost**: ~$60-100/month

### Option 3: Managed Services (Large Clinic)

**Recommended for**: > 2000 patients, > 200 appointments/day

- **N8N**: N8N Cloud ($20-50/month)
- **Database**: AWS RDS PostgreSQL or Google Cloud SQL
- **Cache**: AWS ElastiCache or Google Cloud Memorystore
- **Cost**: ~$100-300/month

---

## Pre-Deployment Checklist

### Requirements

- [ ] Domain name registered (e.g., lucia.kidsgrowing.com)
- [ ] SSL certificate (Let's Encrypt recommended)
- [ ] All API credentials obtained and tested
- [ ] Database backups configured
- [ ] Monitoring tools set up
- [ ] Error tracking configured (Sentry, LogRocket, etc.)
- [ ] Team trained on system usage

### Environment Validation

```bash
# Create deployment checklist
./scripts/pre-deployment-check.sh
```

Create this script:

```bash
#!/bin/bash
# pre-deployment-check.sh

echo "=== Pre-Deployment Checklist ==="

# Check environment variables
echo "Checking environment variables..."
required_vars=(
  "ANTHROPIC_API_KEY"
  "POSTGRES_HOST"
  "REDIS_HOST"
  "GOOGLE_SHEET_PRICING_ID"
  "TELEGRAM_BOT_TOKEN"
)

for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "❌ $var not set"
  else
    echo "✅ $var set"
  fi
done

# Test database connection
echo ""
echo "Testing database connection..."
psql $DATABASE_URL -c "SELECT 1;" > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "✅ Database connection successful"
else
  echo "❌ Database connection failed"
fi

# Test Redis connection
echo ""
echo "Testing Redis connection..."
redis-cli -h $REDIS_HOST -a $REDIS_PASSWORD PING > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "✅ Redis connection successful"
else
  echo "❌ Redis connection failed"
fi

# Check N8N accessibility
echo ""
echo "Testing N8N accessibility..."
curl -s -o /dev/null -w "%{http_code}" http://localhost:5678 | grep -q "200\|302"
if [ $? -eq 0 ]; then
  echo "✅ N8N accessible"
else
  echo "❌ N8N not accessible"
fi

echo ""
echo "=== Checklist Complete ==="
```

---

## Docker Deployment

### Full Stack Docker Compose

Create `docker-compose.production.yml`:

```yaml
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:14-alpine
    container_name: clinic_postgres
    restart: always
    environment:
      POSTGRES_DB: ${POSTGRES_DATABASE}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./config/database-schema.sql:/docker-entrypoint-initdb.d/schema.sql
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: clinic_redis
    restart: always
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # N8N Workflow Automation
  n8n:
    image: n8nio/n8n:latest
    container_name: clinic_n8n
    restart: always
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}
      - N8N_HOST=${N8N_HOST}
      - N8N_PROTOCOL=https
      - N8N_PORT=5678
      - WEBHOOK_URL=https://${N8N_HOST}/
      - GENERIC_TIMEZONE=America/Mexico_City
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=${POSTGRES_DATABASE}
      - DB_POSTGRESDB_USER=${POSTGRES_USER}
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
      # Pass through all environment variables
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - GOOGLE_SHEET_PRICING_ID=${GOOGLE_SHEET_PRICING_ID}
      - TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
      - TELEGRAM_CHAT_ID=${TELEGRAM_CHAT_ID}
      - CLINIC_EMAIL=${CLINIC_EMAIL}
    volumes:
      - n8n_data:/home/node/.n8n
      - ./workflows:/workflows:ro
    ports:
      - "5678:5678"
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:5678/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Nginx Reverse Proxy
  nginx:
    image: nginx:alpine
    container_name: clinic_nginx
    restart: always
    depends_on:
      - n8n
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - nginx_cache:/var/cache/nginx
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_data:
  redis_data:
  n8n_data:
  nginx_cache:
```

### Nginx Configuration

Create `nginx/nginx.conf`:

```nginx
events {
    worker_connections 1024;
}

http {
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

    # Upstream N8N
    upstream n8n {
        server n8n:5678;
    }

    # Redirect HTTP to HTTPS
    server {
        listen 80;
        server_name lucia.kidsgrowing.com;

        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        location / {
            return 301 https://$server_name$request_uri;
        }
    }

    # HTTPS Server
    server {
        listen 443 ssl http2;
        server_name lucia.kidsgrowing.com;

        # SSL Configuration
        ssl_certificate /etc/nginx/ssl/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;

        # Security Headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        # Proxy to N8N
        location / {
            proxy_pass http://n8n;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # WebSocket support
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

            # Timeouts
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }

        # Webhook endpoints with rate limiting
        location /webhook/ {
            limit_req zone=api_limit burst=20 nodelay;

            proxy_pass http://n8n;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # Larger timeout for webhooks
            proxy_read_timeout 120s;
        }

        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
```

### Deploy

```bash
# Create .env file with production values
cp config/.env.example .env
nano .env

# Start all services
docker-compose -f docker-compose.production.yml up -d

# Check logs
docker-compose -f docker-compose.production.yml logs -f

# Verify all services are healthy
docker-compose -f docker-compose.production.yml ps
```

---

## Cloud Deployment

### AWS Deployment

#### 1. Provision Resources

```bash
# Install AWS CLI
aws configure

# Create VPC and Security Groups
aws ec2 create-vpc --cidr-block 10.0.0.0/16
aws ec2 create-security-group --group-name lucia-sg --description "Lucia Security Group"

# Allow HTTPS and SSH
aws ec2 authorize-security-group-ingress --group-name lucia-sg --protocol tcp --port 443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name lucia-sg --protocol tcp --port 22 --cidr YOUR_IP/32
```

#### 2. Launch EC2 Instance

```bash
# Launch instance (Ubuntu 22.04)
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.medium \
  --key-name your-key-pair \
  --security-groups lucia-sg \
  --block-device-mappings DeviceName=/dev/sda1,Ebs={VolumeSize=40}
```

#### 3. Set Up RDS (Managed PostgreSQL)

```bash
aws rds create-db-instance \
  --db-instance-identifier lucia-postgres \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --master-username admin \
  --master-user-password YourPassword \
  --allocated-storage 20 \
  --vpc-security-group-ids sg-xxx
```

#### 4. Set Up ElastiCache (Managed Redis)

```bash
aws elasticache create-cache-cluster \
  --cache-cluster-id lucia-redis \
  --cache-node-type cache.t3.micro \
  --engine redis \
  --num-cache-nodes 1
```

### Google Cloud Deployment

```bash
# Create project
gcloud projects create kids-growing-clinic

# Create Compute Engine instance
gcloud compute instances create lucia-server \
  --machine-type=e2-medium \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=40GB

# Create Cloud SQL instance
gcloud sql instances create lucia-postgres \
  --database-version=POSTGRES_14 \
  --tier=db-f1-micro \
  --region=us-central1

# Create Memorystore Redis
gcloud redis instances create lucia-redis \
  --size=1 \
  --region=us-central1 \
  --tier=basic
```

### DigitalOcean Deployment (Recommended for simplicity)

```bash
# Install doctl
brew install doctl  # macOS
# or
sudo snap install doctl  # Linux

# Authenticate
doctl auth init

# Create Droplet
doctl compute droplet create lucia-server \
  --size s-2vcpu-4gb \
  --image ubuntu-22-04-x64 \
  --region nyc3 \
  --ssh-keys YOUR_SSH_KEY_ID

# Create Managed Database
doctl databases create lucia-postgres \
  --engine pg \
  --version 14 \
  --size db-s-1vcpu-1gb \
  --region nyc3

# Create Managed Redis
doctl databases create lucia-redis \
  --engine redis \
  --version 7 \
  --size db-s-1vcpu-1gb \
  --region nyc3
```

---

## SSL/HTTPS Setup

### Using Let's Encrypt (Free)

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Obtain certificate
sudo certbot --nginx -d lucia.kidsgrowing.com

# Auto-renewal (already set up by certbot)
sudo certbot renew --dry-run
```

### Using Cloudflare (Free + DDoS Protection)

1. Sign up for Cloudflare
2. Add your domain
3. Update nameservers
4. Enable "Full (Strict)" SSL mode
5. Point DNS to your server IP
6. Cloudflare handles SSL automatically

---

## Monitoring & Logging

### Application Monitoring

#### Sentry Integration

```bash
# Install Sentry
npm install @sentry/node

# Add to N8N environment
N8N_SENTRY_DSN=your_sentry_dsn
```

#### UptimeRobot

1. Go to [UptimeRobot](https://uptimerobot.com)
2. Add monitors for:
   - Main webhook: `https://lucia.kidsgrowing.com/webhook/lucia-chat`
   - Health check: `https://lucia.kidsgrowing.com/health`
3. Set up alerts (email, SMS, Slack)

### Log Management

#### Centralized Logging

```bash
# Install Loki + Grafana
docker run -d --name=loki -p 3100:3100 grafana/loki
docker run -d --name=grafana -p 3000:3000 grafana/grafana
```

#### Log Aggregation

```bash
# Install Promtail for log shipping
wget https://github.com/grafana/loki/releases/download/v2.8.0/promtail-linux-amd64.zip
unzip promtail-linux-amd64.zip
sudo mv promtail-linux-amd64 /usr/local/bin/promtail
```

### Metrics

#### PostgreSQL Monitoring

```sql
-- Create monitoring user
CREATE USER monitoring WITH PASSWORD 'monitoring_password';
GRANT pg_monitor TO monitoring;

-- Install pg_stat_statements
CREATE EXTENSION pg_stat_statements;
```

#### Redis Monitoring

```bash
# Install redis-exporter
docker run -d --name redis_exporter \
  -p 9121:9121 \
  oliver006/redis_exporter \
  --redis.addr=redis://localhost:6379 \
  --redis.password=your_password
```

---

## Backup & Recovery

### Automated Backups

Create `/usr/local/bin/backup-clinic.sh`:

```bash
#!/bin/bash

BACKUP_DIR="/backups/clinic"
DATE=$(date +%Y%m%d_%H%M%S)

# PostgreSQL backup
pg_dump -U clinic_admin kids_growing_clinic | gzip > $BACKUP_DIR/postgres_$DATE.sql.gz

# Redis backup
redis-cli --rdb $BACKUP_DIR/redis_$DATE.rdb

# N8N workflows backup
cp -r ~/.n8n/workflows $BACKUP_DIR/n8n_workflows_$DATE

# Upload to S3 (optional)
aws s3 sync $BACKUP_DIR s3://kids-growing-backups/

# Cleanup old backups (keep last 30 days)
find $BACKUP_DIR -type f -mtime +30 -delete

echo "Backup completed: $DATE"
```

### Cron Schedule

```bash
# Edit crontab
crontab -e

# Add backup schedule (2 AM daily)
0 2 * * * /usr/local/bin/backup-clinic.sh >> /var/log/backup-clinic.log 2>&1
```

### Recovery Procedure

```bash
# Restore PostgreSQL
gunzip < postgres_20251113_020000.sql.gz | psql -U clinic_admin kids_growing_clinic

# Restore Redis
redis-cli --rdb redis_20251113_020000.rdb

# Restore N8N workflows
cp -r n8n_workflows_20251113_020000/* ~/.n8n/workflows/
```

---

## Scaling

### Vertical Scaling (Upgrade Server)

```bash
# DigitalOcean
doctl compute droplet-action resize DROPLET_ID --size s-4vcpu-8gb

# AWS
aws ec2 modify-instance-attribute --instance-id i-xxx --instance-type t3.large
```

### Horizontal Scaling (Multiple N8N Instances)

Use N8N queue mode with Redis:

```yaml
# docker-compose.scale.yml
services:
  n8n-main:
    # ... existing config
    environment:
      - EXECUTIONS_MODE=queue
      - QUEUE_BULL_REDIS_HOST=redis

  n8n-worker-1:
    image: n8nio/n8n
    environment:
      - EXECUTIONS_MODE=queue
      - QUEUE_BULL_REDIS_HOST=redis
    command: worker

  n8n-worker-2:
    image: n8nio/n8n
    environment:
      - EXECUTIONS_MODE=queue
      - QUEUE_BULL_REDIS_HOST=redis
    command: worker
```

---

## Security Hardening

### Firewall Setup

```bash
# UFW (Ubuntu)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw enable
```

### Fail2ban

```bash
# Install
sudo apt install fail2ban

# Configure
sudo nano /etc/fail2ban/jail.local
```

```ini
[DEFAULT]
bantime = 1h
maxretry = 5

[sshd]
enabled = true
port = 22
```

### Database Security

```sql
-- Restrict database access
CREATE ROLE clinic_readonly;
GRANT CONNECT ON DATABASE kids_growing_clinic TO clinic_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO clinic_readonly;

-- Encrypt sensitive columns (optional)
CREATE EXTENSION pgcrypto;
```

---

## Maintenance

### Regular Tasks

#### Weekly
- [ ] Review error logs
- [ ] Check disk space
- [ ] Review API usage
- [ ] Update pricing in Google Sheets

#### Monthly
- [ ] Update dependencies
- [ ] Review and optimize database
- [ ] Audit user access
- [ ] Test backup restoration
- [ ] Review Anthropic API costs

#### Quarterly
- [ ] Security audit
- [ ] Performance optimization
- [ ] Update SSL certificates (if not auto-renewed)
- [ ] Disaster recovery drill

### Update Procedure

```bash
# 1. Backup first!
./backup-clinic.sh

# 2. Pull latest code
git pull origin main

# 3. Update Docker images
docker-compose pull

# 4. Restart services with zero downtime
docker-compose up -d --no-deps --build n8n

# 5. Verify
curl https://lucia.kidsgrowing.com/health
```

---

## Troubleshooting Production Issues

### High Memory Usage

```bash
# Check memory
docker stats

# Restart specific service
docker-compose restart n8n
```

### Database Connection Issues

```bash
# Check connections
SELECT count(*) FROM pg_stat_activity;

# Kill idle connections
SELECT pg_terminate_backend(pid) FROM pg_stat_activity
WHERE datname = 'kids_growing_clinic' AND state = 'idle';
```

### Webhook Timeouts

- Increase nginx timeout
- Check N8N execution logs
- Verify external API response times

---

## Cost Optimization

### Estimated Monthly Costs

| Service | Provider | Cost |
|---------|----------|------|
| Server (4GB) | DigitalOcean | $24 |
| Managed Postgres | DigitalOcean | $15 |
| Managed Redis | DigitalOcean | $15 |
| Claude API | Anthropic | $10-50 |
| Telegram Bot | Telegram | $0 (free) |
| Domain + SSL | Cloudflare | $0 (free) |
| **Total** | | **$64-104/month** |

### Optimization Tips

1. Use Claude Haiku (cheapest model)
2. Cache frequent queries in Redis
3. Optimize Google Sheets reads
4. Use Telegram for all notifications (free)
5. Implement webhook request caching

---

**You're now ready for production! 🚀**
