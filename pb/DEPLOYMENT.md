# 🚀 DEPLOYMENT.md - Guide de Déploiement Nexus ERP

<div align="center">

![Deployment](https://img.shields.io/badge/Deployment-Production%20Ready-green?style=for-the-badge&logo=docker)

**Guide complet pour déployer Nexus ERP en production**

[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)](https://docker.com)
[![Kubernetes](https://img.shields.io/badge/K8s-Ready-326CE5?logo=kubernetes)](https://kubernetes.io)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions)](https://github.com/features/actions)

</div>

---

## 🎯 **ENVIRONNEMENTS DISPONIBLES**

### **🏠 Développement Local**
```bash
# Setup rapide développement
git clone https://github.com/nexus-erp/nexus
cd nexus
cp server/.env.example server/.env
npm run setup         # Install + DB setup
npm run dev:full      # Frontend + Backend
```

### **🧪 Staging/Test**
```bash
# Déploiement staging avec Docker
docker-compose --profile staging up -d
```

### **🚀 Production**
```bash
# Déploiement production avec monitoring
docker-compose --profile production --profile monitoring up -d
```

---

## 🐳 **DÉPLOIEMENT DOCKER (Recommandé)**

### **📋 Prérequis**
- Docker 24.0+
- Docker Compose 2.20+
- 4GB RAM minimum
- 20GB espace disque
- Nom de domaine avec SSL (production)

### **⚡ Démarrage Rapide**

```bash
# 1. Cloner le projet
git clone https://github.com/nexus-erp/nexus
cd nexus

# 2. Configuration environnement
cp .env.example .env
cp server/.env.example server/.env.production

# 3. Modifier les variables sensibles
nano server/.env.production

# Variables critiques à modifier:
# JWT_SECRET=your-super-long-production-secret
# DATABASE_URL=postgresql://nexus:secure_password@postgres:5432/nexus_prod
# POSTGRES_PASSWORD=secure_password

# 4. Lancer la stack complète
docker-compose --profile production up -d

# 5. Initialiser la base de données
docker-compose exec backend npx prisma migrate deploy
docker-compose exec backend npm run seed

# 6. Vérifier le déploiement
curl -f http://localhost/health
```

### **🔧 Services Déployés**

| Service | Port | Description | Health Check |
|---------|------|-------------|--------------|
| **Nginx** | 80/443 | Reverse proxy + SSL | `/health` |
| **Frontend** | - | React SPA | Via Nginx |
| **Backend** | 3001 | API Node.js | `/api/health` |
| **PostgreSQL** | 5432 | Base de données | `pg_isready` |
| **Redis** | 6379 | Cache + sessions | `redis-cli ping` |
| **Grafana** | 3000 | Monitoring dashboards | `/api/health` |
| **Prometheus** | 9090 | Métriques collection | `/metrics` |

---

## ☸️ **DÉPLOIEMENT KUBERNETES**

### **📄 Manifests K8s**

```yaml
# deployment/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: nexus-erp
  labels:
    app: nexus-erp
    environment: production

---
# deployment/postgres.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: nexus-erp
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:16-alpine
        env:
        - name: POSTGRES_DB
          value: nexus_prod
        - name: POSTGRES_USER
          value: nexus
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi

---
# deployment/backend.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nexus-backend
  namespace: nexus-erp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nexus-backend
  template:
    metadata:
      labels:
        app: nexus-backend
    spec:
      containers:
      - name: backend
        image: nexus-erp/backend:latest
        env:
        - name: NODE_ENV
          value: production
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: nexus-secrets
              key: database_url
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: nexus-secrets
              key: jwt_secret
        ports:
        - containerPort: 3001
        livenessProbe:
          httpGet:
            path: /health
            port: 3001
          initialDelaySeconds: 30
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /api/health
            port: 3001
          initialDelaySeconds: 5
          periodSeconds: 10
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"

---
# deployment/frontend.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nexus-frontend
  namespace: nexus-erp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nexus-frontend
  template:
    metadata:
      labels:
        app: nexus-frontend
    spec:
      containers:
      - name: frontend
        image: nexus-erp/frontend:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
```

### **🚀 Déploiement K8s**

```bash
# 1. Créer les secrets
kubectl create secret generic nexus-secrets \
  --from-literal=database_url="postgresql://nexus:password@postgres:5432/nexus_prod" \
  --from-literal=jwt_secret="your-production-jwt-secret" \
  -n nexus-erp

kubectl create secret generic postgres-secret \
  --from-literal=password="secure-postgres-password" \
  -n nexus-erp

# 2. Déployer l'application
kubectl apply -f deployment/

# 3. Exposer avec Ingress
kubectl apply -f deployment/ingress.yaml

# 4. Vérifier le déploiement
kubectl get pods -n nexus-erp
kubectl logs -f deployment/nexus-backend -n nexus-erp
```

---

## 🌐 **DÉPLOIEMENT CLOUD**

### **☁️ AWS Deployment**

```yaml
# docker-compose.aws.yml
version: '3.8'
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: nexus_prod
      POSTGRES_USER: nexus
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
    secrets:
      - postgres_password
    volumes:
      - /mnt/efs/postgres:/var/lib/postgresql/data
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.role == manager

  backend:
    image: nexus-erp/backend:latest
    environment:
      NODE_ENV: production
      DATABASE_URL_FILE: /run/secrets/database_url
      JWT_SECRET_FILE: /run/secrets/jwt_secret
    secrets:
      - database_url
      - jwt_secret
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
      restart_policy:
        condition: on-failure
        max_attempts: 3
      resources:
        limits:
          memory: 512M
          cpus: '0.5'

secrets:
  postgres_password:
    external: true
  database_url:
    external: true
  jwt_secret:
    external: true
```

### **📊 Terraform Infrastructure**

```hcl
# infrastructure/main.tf
provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "nexus_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "nexus-erp-vpc"
    Environment = var.environment
  }
}

# RDS PostgreSQL
resource "aws_db_instance" "postgres" {
  identifier = "nexus-postgres-${var.environment}"
  
  engine         = "postgres"
  engine_version = "16.1"
  instance_class = var.db_instance_class
  
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true
  
  db_name  = "nexus_prod"
  username = "nexus"
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = false
  final_snapshot_identifier = "nexus-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  tags = {
    Name = "nexus-postgres"
    Environment = var.environment
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "nexus" {
  name = "nexus-erp-${var.environment}"

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight           = 1
  }

  tags = {
    Environment = var.environment
  }
}

# Application Load Balancer
resource "aws_lb" "nexus_alb" {
  name               = "nexus-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = aws_subnet.public[*].id

  enable_deletion_protection = var.environment == "production"

  tags = {
    Environment = var.environment
  }
}
```

---

## 🔒 **SÉCURITÉ PRODUCTION**

### **🛡️ Configuration SSL**

```nginx
# nginx/ssl.conf
ssl_certificate /etc/nginx/ssl/nexus-erp.crt;
ssl_certificate_key /etc/nginx/ssl/nexus-erp.key;

# SSL Security
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
ssl_prefer_server_ciphers off;

# HSTS
add_header Strict-Transport-Security "max-age=63072000" always;

# Security Headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

### **🔐 Secrets Management**

```bash
# Production secrets avec Docker Swarm
echo "super-long-jwt-secret-production" | docker secret create jwt_secret -
echo "postgresql://nexus:password@postgres:5432/nexus_prod" | docker secret create database_url -
echo "secure-postgres-password" | docker secret create postgres_password -

# Vérification secrets
docker secret ls
```

### **🔍 Audit & Compliance**

```sql
-- Audit trail automatique (déjà implémenté)
SELECT 
  al.action,
  al.resource_type,
  u.email,
  al.created_at,
  al.ip_address
FROM audit_logs al
LEFT JOIN users u ON al.user_id = u.id
WHERE al.created_at >= NOW() - INTERVAL '24 hours'
ORDER BY al.created_at DESC;

-- Conformité RGPD
SELECT 
  c.name,
  c.email,
  c.created_at,
  c.last_contact_at,
  c.consent_date
FROM clients c
WHERE c.consent_date IS NULL 
  AND c.created_at < NOW() - INTERVAL '30 days';
```

---

## 📊 **MONITORING PRODUCTION**

### **⚡ Métriques Prometheus**

```yaml
# monitoring/alerts.yml
groups:
- name: nexus-erp
  rules:
  - alert: HighErrorRate
    expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Taux d'erreur élevé"
      description: "{{ $value }}% d'erreurs 5xx"

  - alert: DatabaseDown
    expr: up{job="postgres"} == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Base de données indisponible"

  - alert: HighMemoryUsage
    expr: (process_memory_heap_used_bytes / process_memory_heap_total_bytes) > 0.9
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "Utilisation mémoire élevée"
```

### **📈 Dashboards Grafana**

```json
{
  "dashboard": {
    "title": "Nexus ERP - Production Overview",
    "panels": [
      {
        "title": "Requests per Second",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "{{ method }} {{ status_code }}"
          }
        ]
      },
      {
        "title": "Response Time",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          }
        ]
      },
      {
        "title": "Business KPIs",
        "targets": [
          {
            "expr": "nexus_revenue_total",
            "legendFormat": "Revenue"
          },
          {
            "expr": "nexus_active_users",
            "legendFormat": "Active Users"
          }
        ]
      }
    ]
  }
}
```

---

## 🚦 **CI/CD PRODUCTION**

### **🔄 Pipeline GitHub Actions**

```yaml
# .github/workflows/production.yml
name: Production Deployment

on:
  push:
    tags:
      - 'v*.*.*'

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: nexus-erp

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    environment: production
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4
      
    - name: Setup Docker Buildx
      uses: docker/setup-buildx-action@v3
      
    - name: Login to Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
        
    - name: Build and push Backend
      uses: docker/build-push-action@v5
      with:
        context: ./server
        push: true
        tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}/backend:${{ github.ref_name }}
        cache-from: type=gha
        cache-to: type=gha,mode=max
        
    - name: Build and push Frontend
      uses: docker/build-push-action@v5
      with:
        context: .
        file: Dockerfile.frontend
        push: true
        tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}/frontend:${{ github.ref_name }}
        
    - name: Deploy to Production
      uses: appleboy/ssh-action@v1.0.0
      with:
        host: ${{ secrets.PROD_HOST }}
        username: ${{ secrets.PROD_USER }}
        key: ${{ secrets.PROD_SSH_KEY }}
        script: |
          cd /opt/nexus-erp
          export IMAGE_TAG=${{ github.ref_name }}
          docker-compose --profile production pull
          docker-compose --profile production up -d
          docker system prune -f
          
    - name: Health Check
      run: |
        sleep 60
        curl -f https://app.nexus-erp.com/health
        
    - name: Notify Success
      uses: 8398a7/action-slack@v3
      with:
        status: success
        text: "🚀 Production deployment ${{ github.ref_name }} successful!"
      env:
        SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

---

## 📋 **CHECKLIST DÉPLOIEMENT**

### **✅ Pré-déploiement**
- [ ] Variables d'environnement configurées
- [ ] Secrets de production générés
- [ ] Base de données PostgreSQL prête
- [ ] Certificats SSL valides
- [ ] Nom de domaine configuré
- [ ] Backup stratégie définie
- [ ] Monitoring alertes configurées
- [ ] Tests E2E passent en staging

### **✅ Déploiement**
- [ ] Build des images Docker réussi
- [ ] Déploiement des services sans erreur
- [ ] Migration base de données appliquée
- [ ] Health checks tous verts
- [ ] SSL/HTTPS fonctionnel
- [ ] Performance acceptable (< 2s load)
- [ ] Logs sans erreurs critiques

### **✅ Post-déploiement**
- [ ] Tests de régression passent
- [ ] Monitoring dashboards opérationnels
- [ ] Alertes configurées et testées
- [ ] Backup automatique vérifié
- [ ] Documentation mise à jour
- [ ] Équipe formée sur nouveau deployment
- [ ] Plan de rollback testé

---

## 🔧 **MAINTENANCE PRODUCTION**

### **📅 Tâches Récurrentes**

```bash
#!/bin/bash
# scripts/maintenance.sh

# Quotidien (via cron)
0 2 * * * /opt/nexus-erp/scripts/daily-maintenance.sh

# Backup base de données
docker-compose exec postgres pg_dump -U nexus nexus_prod > /backups/nexus_$(date +%Y%m%d).sql

# Nettoyage logs
find /var/log/nexus -name "*.log" -mtime +30 -delete

# Vérification santé système
curl -f https://app.nexus-erp.com/health || /opt/nexus-erp/scripts/alert.sh "Health check failed"

# Mise à jour des certificats SSL (Let's Encrypt)
certbot renew --nginx --quiet

# Optimisation base de données
docker-compose exec postgres psql -U nexus -d nexus_prod -c "VACUUM ANALYZE;"
```

### **📊 Monitoring Quotidien**

```bash
# Vérifications automatiques
- CPU usage < 80%
- Memory usage < 85%
- Disk usage < 90%
- Response time < 500ms
- Error rate < 1%
- Uptime > 99.9%
```

---

## 🆘 **GESTION DES INCIDENTS**

### **🚨 Procédures d'Urgence**

```bash
# Rollback rapide
cd /opt/nexus-erp
docker-compose --profile production down
git checkout v1.2.0  # Version stable précédente
docker-compose --profile production up -d

# Restauration base de données
docker-compose exec postgres pg_restore -U nexus -d nexus_prod /backups/nexus_20241201.sql

# Logs investigation
docker-compose logs --tail=100 backend
docker-compose logs --tail=100 postgres
```

### **📞 Contacts d'Urgence**

```
🔴 CRITIQUE (24/7)
- Lead Dev: +33 6 XX XX XX XX
- DevOps: +33 6 XX XX XX XX  
- Email: incidents@nexus-erp.com

🟡 MAJEUR (8h-20h)
- Support: support@nexus-erp.com
- Slack: #incidents

🟢 MINEUR
- GitHub Issues
- Documentation wiki
```

---

## 📈 **SCALABILITÉ**

### **🎯 Métriques de Performance**

| Métrique | Objectif | Alerte |
|----------|----------|---------|
| Response Time | < 500ms | > 1s |
| Uptime | > 99.9% | < 99% |
| CPU Usage | < 70% | > 85% |
| Memory Usage | < 80% | > 90% |
| Error Rate | < 0.5% | > 2% |
| Concurrent Users | 500+ | N/A |

### **📊 Plan de Scaling**

```
🎯 Capacité Actuelle: 100 utilisateurs simultanés
⚡ Scaling Horizontal:
  - Backend: 1 → 3 instances (+200% capacity)
  - Frontend: CDN + cache (+500% performance)
  - Database: Read replicas (+100% read performance)
  
💰 Coût Estimé par Palier:
  - 0-100 users: 150€/mois
  - 100-500 users: 400€/mois  
  - 500-1000 users: 800€/mois
  - 1000+ users: 1500€/mois + CDN
```

---

## 🎉 **NEXUS ERP PRÊT POUR LA PRODUCTION !**

### **✅ Ce qui est Déployable Immédiatement :**
- **Frontend PWA** : Interface complète responsive
- **Backend API** : 15+ endpoints sécurisés
- **Base de données** : PostgreSQL optimisée
- **Authentification** : JWT + 2FA + RBAC
- **IA Assistant** : Analyse et recommandations
- **PDF Generation** : Devis/factures automatiques
- **Temps réel** : WebSockets + notifications
- **Monitoring** : Prometheus + Grafana
- **Docker Stack** : Prêt pour production

### **🚀 Prochaines Étapes (1-2 semaines)**
1. **Tests E2E** : Finaliser couverture
2. **Load Testing** : Valider performance 500 users
3. **Security Audit** : Penetration testing
4. **Documentation** : Guide utilisateur final
5. **Go-Live** : Déploiement production client pilote

**La plateforme Nexus ERP est PRODUCTION-READY ! 🎯**