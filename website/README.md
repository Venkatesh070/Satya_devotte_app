# Sathya Static Website

A complete static website for Sathya, including landing page, policy pages, and Paystack payment pages.

## 📁 Directory Structure
```
website/
├── index.html          # Main landing page
├── privacy.html        # Privacy Policy
├── terms.html          # Terms & Conditions
├── refund.html         # Refund & Cancellation Policy
├── paystack/
│   ├── index.html      # Payment processing page
│   ├── success.html    # Payment success page
│   └── cancel.html     # Payment canceled page
└── README.md           # This file
```

## 🚀 Deployment Instructions

### Option 1: Deploy to Netlify (Free)
1. Go to [netlify.com](https://www.netlify.com)
2. Drag & drop the entire `website/` folder
3. Your website is live!

### Option 2: Deploy to Vercel (Free)
1. Go to [vercel.com](https://vercel.com)
2. Create a new project and upload the `website/` folder
3. Deploy!

### Option 3: Any Static Hosting
Upload the `website/` folder to any static hosting provider (Firebase Hosting, AWS S3, etc.)

## 🔗 Paystack Configuration
In your Paystack Dashboard, set:
- **Callback URL**: `https://your-domain.com/paystack/success.html`
- **Cancel URL**: `https://your-domain.com/paystack/cancel.html`
