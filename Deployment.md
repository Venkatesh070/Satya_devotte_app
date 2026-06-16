# Sathya Deployment & Infrastructure Handover Document

## Server Information

### EC2 Server

* Hosting Provider: AWS EC2
* Web Server: Nginx
* Backend Runtime: Node.js
* Process Manager: PM2
* SSL: Let's Encrypt (Certbot)

---

# Domains

## Production Environment

| Service     | URL                        |
| ----------- | -------------------------- |
| Admin Panel | https://admin.sathya.co.za |
| API         | https://api.sathya.co.za   |

## Test Environment

| Service     | URL                             |
| ----------- | ------------------------------- |
| Admin Panel | https://admin-test.sathya.co.za |
| API         | https://api-test.sathya.co.za   |

---

# Required Access

The developer should have access to:

## AWS

* EC2 Console
* Security Groups
* Route53 (DNS)
* SSH PEM Key

## MongoDB

* Production Database
* Test Database

## Firebase

* Authentication
* FCM Push Notifications
* Project Settings

## Google Cloud Console

* OAuth Credentials
* Firebase Linked Services

## Paystack

* API Keys
* Webhooks
* Transactions

## Brevo

* SMTP Credentials
* Transactional Emails

## GoDaddy / DNS

* DNS Records
* Domain Management

---

# SSH Access

Connect to EC2:

```bash
ssh -i ~/.ssh/sathya-backend-prod.pem ubuntu@<EC2_IP>
```

---

# Project Structure

## Production Backend

Location:

```bash
~/satya_server_app
```

Port:

```txt
3080
```

Domain:

```txt
https://api.sathya.co.za
```

---

## Test Backend

Location:

```bash
~/satya_server_app_test
```

Port:

```txt
3081
```

Domain:

```txt
https://api-test.sathya.co.za
```

---

## Production Admin

Location:

```bash
/var/www/admin_prod
```

Domain:

```txt
https://admin.sathya.co.za
```

---

## Test Admin

Location:

```bash
/var/www/admin_test
```

Domain:

```txt
https://admin-test.sathya.co.za
```

---

# Flutter Admin Deployment

## Build Flutter Web

Navigate to project:

```bash
cd /Users/<username>/Desktop/Sathya/Satya_devotte_app
```

Build:

```bash
flutter clean
flutter pub get
flutter build web --release
```

Output:

```bash
build/web
```

---

## Deploy Test Admin

```bash
scp -i ~/.ssh/sathya-backend-prod.pem -r build/web/. ubuntu@<EC2_IP>:/var/www/admin_test/
```

Verify:

```txt
https://admin-test.sathya.co.za
```

---

## Deploy Production Admin

```bash
scp -i ~/.ssh/sathya-backend-prod.pem -r build/web/. ubuntu@<EC2_IP>:/var/www/admin_prod/
```

Verify:

```txt
https://admin.sathya.co.za
```

---

# Node Backend Deployment

## Test Backend

```bash
ssh -i ~/.ssh/sathya-backend-prod.pem ubuntu@<EC2_IP>

cd ~/satya_server_app_test

git pull

npm install

npm run build

pm2 restart all
```

Verify:

```txt
https://api-test.sathya.co.za
```

---

## Production Backend

```bash
ssh -i ~/.ssh/sathya-backend-prod.pem ubuntu@<EC2_IP>

cd ~/satya_server_app

git pull

npm install

npm run build

pm2 restart all
```

Verify:

```txt
https://api.sathya.co.za
```

---

# Environment Variables

## Test

```bash
cd ~/satya_server_app_test

nano .env
```

## Production

```bash
cd ~/satya_server_app

nano .env
```

Save:

```txt
Ctrl + O
Enter
Ctrl + X
```

Restart:

```bash
pm2 restart all
```

---

# PM2 Commands

View Processes:

```bash
pm2 list
```

View Logs:

```bash
pm2 logs
```

Restart All:

```bash
pm2 restart all
```

Restart Specific App:

```bash
pm2 restart <app-name>
```

Save Configuration:

```bash
pm2 save
```

---

# Nginx Configuration

## Test Admin

Config File:

```bash
/etc/nginx/sites-enabled/admin-test
```

Root:

```bash
/var/www/admin_test
```

---

## Production Admin

Config File:

```bash
/etc/nginx/sites-enabled/admin-prod
```

Root:

```bash
/var/www/admin_prod
```

---

## Test API

Config File:

```bash
/etc/nginx/sites-enabled/api-test
```

Proxy:

```txt
localhost:3081
```

---

## Production API

Config File:

```bash
/etc/nginx/sites-enabled/default
```

Proxy:

```txt
localhost:3080
```

---

# Nginx Commands

Validate:

```bash
sudo nginx -t
```

Reload:

```bash
sudo systemctl reload nginx
```

Restart:

```bash
sudo systemctl restart nginx
```

Status:

```bash
sudo systemctl status nginx
```

---

# SSL Certificates

View Certificates:

```bash
sudo certbot certificates
```

Generate SSL:

```bash
sudo certbot --nginx -d admin.sathya.co.za
sudo certbot --nginx -d admin-test.sathya.co.za
sudo certbot --nginx -d api.sathya.co.za
sudo certbot --nginx -d api-test.sathya.co.za
```

If certificate already exists:

```txt
Choose Option 1 - Reinstall Existing Certificate
```

Verify HTTPS:

```bash
curl -I https://admin.sathya.co.za
curl -I https://admin-test.sathya.co.za
curl -I https://api.sathya.co.za
curl -I https://api-test.sathya.co.za
```

---

# Security Group Requirements

Inbound Rules:

| Type  | Port |
| ----- | ---- |
| SSH   | 22   |
| HTTP  | 80   |
| HTTPS | 443  |

Source:

```txt
0.0.0.0/0
```

---

# Paystack Configuration

Webhook URL:

Production:

```txt
https://api.sathya.co.za/api/v1/payments/webhook
```

Test:

```txt
https://api-test.sathya.co.za/api/v1/payments/webhook
```

Requirements:

* HTTPS enabled
* Port 443 open
* Nginx proxy working
* Node application running

---

# Deployment Checklist

## Admin

* Login
* Dashboard
* Products
* Books
* Orders
* Notifications
* Settings

## Backend

* Login APIs
* Registration
* OTP
* Profile
* Orders
* Payments
* Push Notifications

## Payments

* Paystack Payment
* Payment Verification
* Webhook Processing

## SSL

* Verify all domains load over HTTPS
* Verify certificate validity

---

# Important Notes

* Always deploy to Test environment first.
* Validate all critical flows before Production deployment.
* Never commit .env files to Git.
* Keep AWS, MongoDB, Firebase, Paystack and Brevo credentials secure.
* Maintain backups before major deployments.
* Ensure SSL certificates are renewed before expiry.
