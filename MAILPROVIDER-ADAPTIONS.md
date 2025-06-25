Following entries should be removed after deployment of mail-pool branch

```json      
{
        "name": "MAIL_SMTP_USERNAME",
        "valueFrom": "/runningdinner/ses/smtp/username"
      },
      {
        "name": "MAIL_SMTP_PASSWORD",
        "valueFrom": "/runningdinner/ses/smtp/password"
      },
      {
        "name": "MAILJET_API_KEY_PUBLIC",
        "valueFrom": "/runningdinner/mailjet/username"
      },
      {
        "name": "MAILJET_API_KEY_PRIVATE",
        "valueFrom": "/runningdinner/mailjet/password"
      }
```

Furthermore all SendGrid Entries after complete removal