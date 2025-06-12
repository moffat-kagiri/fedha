# Google Cloud Hosting Guide for Fedha Finance App

## Overview
This guide provides comprehensive recommendations for hosting the Fedha Finance App on Google Cloud Platform (GCP) for live deployment.

## Architecture Components

### 1. Flutter Web Frontend
**Recommended Service:** Firebase Hosting
- **Why:** Built for Flutter web apps, global CDN, automatic SSL, custom domains
- **Cost:** Free tier: 10GB storage, 10GB/month transfer
- **Pricing:** $0.026/GB storage, $0.15/GB transfer

### 2. Django Backend API
**Option A: Cloud Run (Recommended)**
- **Why:** Serverless, automatic scaling, pay-per-use, Docker-based
- **Cost:** Free tier: 180,000 vCPU-seconds, 360,000 GiB-seconds, 2M requests/month
- **Pricing:** $0.00002400/vCPU-second, $0.00000250/GiB-second

**Option B: App Engine**
- **Why:** Fully managed, automatic scaling, integrated with GCP services
- **Cost:** Free tier: 28 frontend instance hours/day
- **Pricing:** $0.05/hour for standard instances

**Option C: Compute Engine + Load Balancer**
- **Why:** Full control, custom configurations, high performance
- **Cost:** e2-micro: $4.28/month (free tier eligible)
- **Pricing:** Varies by machine type

### 3. Database
**Option A: Cloud SQL (PostgreSQL) - Recommended**
- **Why:** Fully managed, automatic backups, high availability
- **Cost:** db-f1-micro: $7.67/month
- **Pricing:** $0.0150/hour + $0.090/GB/month storage

**Option B: Cloud Firestore**
- **Why:** NoSQL, real-time sync, offline support
- **Cost:** Free tier: 50,000 reads, 20,000 writes, 20,000 deletes/day
- **Pricing:** $0.18/100K reads, $0.18/100K writes

**Option C: Cloud Spanner**
- **Why:** Global distribution, strong consistency, horizontal scaling
- **Cost:** $0.90/hour/node + $0.30/GB/month storage
- **Note:** Expensive, suitable for large scale

### 4. File Storage
**Recommended Service:** Cloud Storage
- **Why:** Object storage for static files, images, documents
- **Cost:** Standard: $0.020/GB/month
- **Pricing:** Regional: $0.020/GB, Multi-regional: $0.026/GB

## Deployment Architecture

### Recommended Setup (Cost-Effective)
```
Frontend: Firebase Hosting → CDN
Backend: Cloud Run → Django API
Database: Cloud SQL PostgreSQL
Storage: Cloud Storage
Domain: Cloud DNS
SSL: Firebase Hosting (automatic)
```

### High-Performance Setup
```
Frontend: Firebase Hosting → CDN
Backend: App Engine → Django API
Database: Cloud SQL with Read Replicas
Storage: Cloud Storage + Cloud CDN
Monitoring: Cloud Monitoring + Logging
Load Balancer: Global Load Balancer
```

### Enterprise Setup
```
Frontend: Firebase Hosting → Global CDN
Backend: GKE (Kubernetes) → Django API
Database: Cloud SQL High Availability
Storage: Cloud Storage Multi-regional
Security: Cloud Armor, IAM
Monitoring: Cloud Monitoring, Alerting
CI/CD: Cloud Build, Cloud Deploy
```

## Cost Estimates

### Small Scale (MVP)
- Firebase Hosting: Free
- Cloud Run: $5-15/month
- Cloud SQL (db-f1-micro): $8/month
- Cloud Storage: $1-3/month
- **Total: $14-26/month**

### Medium Scale (Growing Business)
- Firebase Hosting: $10-25/month
- Cloud Run: $20-50/month
- Cloud SQL (db-g1-small): $25/month
- Cloud Storage: $5-15/month
- Cloud DNS: $0.50/month
- **Total: $60-115/month**

### Large Scale (Enterprise)
- Firebase Hosting: $50-100/month
- App Engine/GKE: $100-300/month
- Cloud SQL (High Availability): $100-200/month
- Cloud Storage + CDN: $20-50/month
- Additional Services: $50-100/month
- **Total: $320-750/month**

## Step-by-Step Deployment

### 1. Setup Google Cloud Project
```bash
# Install Google Cloud CLI
# Visit: https://cloud.google.com/sdk/docs/install

# Initialize project
gcloud init
gcloud projects create fedha-finance-app
gcloud config set project fedha-finance-app

# Enable required APIs
gcloud services enable run.googleapis.com
gcloud services enable sql-component.googleapis.com
gcloud services enable storage-component.googleapis.com
gcloud services enable cloudbuild.googleapis.com
```

### 2. Setup Database
```bash
# Create Cloud SQL instance
gcloud sql instances create fedha-db \
    --database-version=POSTGRES_14 \
    --tier=db-f1-micro \
    --region=us-central1

# Create database
gcloud sql databases create fedha_prod --instance=fedha-db

# Create user
gcloud sql users create fedha_user \
    --instance=fedha-db \
    --password=[SECURE_PASSWORD]
```

### 3. Setup Storage
```bash
# Create storage bucket
gsutil mb gs://fedha-finance-storage

# Set permissions
gsutil iam ch allUsers:objectViewer gs://fedha-finance-storage
```

### 4. Deploy Django Backend
```bash
# Create Dockerfile for Django
cat > Dockerfile << EOF
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

ENV PORT 8080
EXPOSE 8080

CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 fedha.wsgi:application
EOF

# Build and deploy to Cloud Run
gcloud builds submit --tag gcr.io/fedha-finance-app/django-api
gcloud run deploy fedha-api \
    --image gcr.io/fedha-finance-app/django-api \
    --platform managed \
    --region us-central1 \
    --allow-unauthenticated
```

### 5. Deploy Flutter Frontend
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Build Flutter web
flutter build web

# Initialize Firebase
firebase init hosting

# Deploy to Firebase Hosting
firebase deploy
```

### 6. Configure Domain (Optional)
```bash
# Setup custom domain in Firebase Console
# Configure DNS records with your domain provider
```

## Environment Configuration

### Django Production Settings
```python
# settings/production.py
import os
from .base import *

DEBUG = False
ALLOWED_HOSTS = ['your-api-domain.com', 'fedha-api-xxxxx.run.app']

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'fedha_prod',
        'USER': 'fedha_user',
        'PASSWORD': os.environ['DB_PASSWORD'],
        'HOST': '/cloudsql/fedha-finance-app:us-central1:fedha-db',
        'PORT': '',
    }
}

# Cloud Storage
DEFAULT_FILE_STORAGE = 'storages.backends.gcloud.GoogleCloudStorage'
GS_BUCKET_NAME = 'fedha-finance-storage'

# Security
SECURE_SSL_REDIRECT = True
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
```

### Flutter Web Configuration
```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'https://fedha-api-xxxxx.run.app/api';
  static const String environment = 'production';
}
```

## Security Recommendations

### 1. Identity and Access Management (IAM)
- Use service accounts with minimal permissions
- Enable audit logging
- Implement role-based access control

### 2. Cloud Armor (Web Application Firewall)
- Protect against DDoS attacks
- Rate limiting
- Geographic restrictions

### 3. VPC Security
- Use private IPs for database
- Configure firewall rules
- Enable VPC Flow Logs

### 4. SSL/TLS
- Use Firebase Hosting for automatic SSL
- Configure HSTS headers
- Use Cloud Load Balancer with managed certificates

## Monitoring and Alerting

### 1. Cloud Monitoring
- Set up uptime checks
- Monitor response times
- Track error rates

### 2. Cloud Logging
- Centralized log management
- Log-based metrics
- Error reporting

### 3. Alerting Policies
- CPU and memory usage
- Database connections
- API response times
- Error rates

## Backup and Disaster Recovery

### 1. Database Backups
- Automated daily backups
- Point-in-time recovery
- Cross-region replication

### 2. Application Backup
- Source code in Git
- Container images in Container Registry
- Configuration in Secret Manager

### 3. Recovery Testing
- Regular backup restoration tests
- Disaster recovery procedures
- RTO/RPO objectives

## Performance Optimization

### 1. Content Delivery Network (CDN)
- Firebase Hosting global CDN
- Cloud CDN for API responses
- Image optimization

### 2. Caching
- Redis for session storage
- Database query caching
- API response caching

### 3. Auto-scaling
- Cloud Run automatic scaling
- Cloud SQL read replicas
- Load balancing

## CI/CD Pipeline

### 1. Cloud Build Configuration
```yaml
# cloudbuild.yaml
steps:
  # Test Django
  - name: 'python:3.11'
    entrypoint: pip
    args: ['install', '-r', 'requirements.txt']
  
  - name: 'python:3.11'
    entrypoint: python
    args: ['manage.py', 'test']
  
  # Build and deploy
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/django-api', '.']
  
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/django-api']
  
  - name: 'gcr.io/cloud-builders/gcloud'
    args: ['run', 'deploy', 'fedha-api', 
           '--image', 'gcr.io/$PROJECT_ID/django-api',
           '--region', 'us-central1']
```

### 2. Flutter Build Pipeline
```yaml
# .github/workflows/deploy.yml
name: Deploy to Firebase
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      
      - run: flutter build web
      
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          projectId: fedha-finance-app
```

## Cost Optimization Tips

### 1. Resource Management
- Use preemptible instances for development
- Right-size your resources
- Monitor usage with billing alerts

### 2. Storage Optimization
- Use lifecycle policies for old data
- Compress static assets
- Use appropriate storage classes

### 3. Network Optimization
- Use regional resources when possible
- Minimize cross-region traffic
- Implement effective caching

## Getting Started Checklist

- [ ] Create Google Cloud Project
- [ ] Enable required APIs
- [ ] Setup Cloud SQL database
- [ ] Create storage bucket
- [ ] Deploy Django backend to Cloud Run
- [ ] Build and deploy Flutter frontend to Firebase
- [ ] Configure custom domain (optional)
- [ ] Setup monitoring and alerting
- [ ] Configure backup strategy
- [ ] Implement CI/CD pipeline
- [ ] Security hardening
- [ ] Performance testing
- [ ] Documentation update

## Support and Resources

### Google Cloud Support
- Basic: Free (community support)
- Developer: $29/month
- Production: $500/month
- Enterprise: Contact sales

### Documentation
- [Google Cloud Documentation](https://cloud.google.com/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Web Deployment](https://flutter.dev/docs/deployment/web)

### Community
- [Google Cloud Community](https://cloud.google.com/community)
- [Flutter Community](https://flutter.dev/community)
- [Django Community](https://www.djangoproject.com/community/)

---

**Next Steps:** 
1. Start with the cost-effective setup for MVP
2. Monitor usage and costs
3. Scale up as user base grows
4. Implement additional features as needed
