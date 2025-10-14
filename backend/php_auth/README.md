# PHP Auth Backend (Simple)

This folder contains a minimal PHP backend for user authentication using MySQL and bearer tokens.

## Endpoints
- POST `register.php` — body: `{ email, password, displayName }` → sends verification email
- POST `verify.php` — body: `{ email, code }` → verifies email and returns token
- POST `resend.php` — body: `{ email }` → resends verification code
- POST `login.php` — body: `{ email, password }` → requires verified email
- GET `me.php` — header: `Authorization: Bearer <token>`
- POST `logout.php` — header: `Authorization: Bearer <token>`

## Setup

### Using XAMPP (Recommended)
1. **Start XAMPP Services:**
   - Open XAMPP Control Panel
   - Start **Apache** and **MySQL** services

2. **Create Database:**
   - Open browser: `http://localhost/phpmyadmin`
   - Click "New" → Database name: `phishti_auth` → Collation: `utf8mb4_unicode_ci` → Create
   - Select `phishti_auth` database → Import tab → Choose `schema.sql` → Go

3. **Configure Connection:**
   - XAMPP default settings are already in `config.php`:
     - Host: `127.0.0.1`
     - User: `root`
     - Password: (empty)
     - Database: `phishti_auth`

4. **Configure Email (for verification):**
   - Edit `config.php` and set your email settings:
     - `$SMTP_USERNAME` - your Gmail address
     - `$SMTP_PASSWORD` - your Gmail app password
     - `$SMTP_FROM_EMAIL` - sender email
     - `$SMTP_FROM_NAME` - sender name

### Manual Setup
1. Create database and tables:
```sql
CREATE DATABASE phishti_auth CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE phishti_auth;
SOURCE schema.sql;
```

2. Configure DB connection in `config.php` or via environment variables:
- `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASS`

### Running the Backend

**Option A: XAMPP Apache (Recommended)**
- Copy `backend/php_auth` folder to `C:\xampp\htdocs\`
- Access via: `http://localhost/php_auth/register.php`

**Option B: PHP Built-in Server**
```bash
cd backend/php_auth
php -S 0.0.0.0:8081
```

4. Test endpoints:
```bash
# Register (sends verification email)
curl -X POST http://localhost:8081/register.php \
  -H 'Content-Type: application/json' \
  -d '{"email":"test@example.com","password":"password123","displayName":"Test"}'

# Verify email (check your email for the 6-digit code)
curl -X POST http://localhost:8081/verify.php \
  -H 'Content-Type: application/json' \
  -d '{"email":"test@example.com","code":"123456"}'

# Resend verification code
curl -X POST http://localhost:8081/resend.php \
  -H 'Content-Type: application/json' \
  -d '{"email":"test@example.com"}'

# Login (requires verified email)
curl -X POST http://localhost:8081/login.php \
  -H 'Content-Type: application/json' \
  -d '{"email":"test@example.com","password":"password123"}'

# Me
curl http://localhost:8081/me.php -H 'Authorization: Bearer <token>'

# Logout
curl -X POST http://localhost:8081/logout.php -H 'Authorization: Bearer <token>'
```

## Notes
- **Email Verification Flow:**
  1. User registers → receives 6-digit code via email
  2. User enters code → account is verified and gets login token
  3. User can login only after email verification
- **Verification codes expire in 15 minutes**
- **Passwords are stored using `password_hash` (bcrypt/argon2 depending on PHP config)**
- **Sessions table stores long-lived tokens (30 days)**
- **For production:**
  - Configure proper SMTP settings in `config.php`
  - Serve behind HTTPS
  - Restrict `Access-Control-Allow-Origin` in `config.php`
  - Use PHPMailer or similar for better email delivery
  - Consider refresh tokens and JWT if needed

## Flutter integration
Update your Flutter `AuthService` to call these endpoints (web and mobile). Example base URL:
```
const authBaseUrl = 'http://localhost:8081';
```
Then replace Firebase calls with HTTP POSTs to `/login.php`, `/register.php`, and use stored token for `/me.php`/`/logout.php`.
