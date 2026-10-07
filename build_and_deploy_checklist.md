# Production Build & App Store Publishing Deployment Guide - Chefni AI

This guide contains complete release commands, Play Console Data Safety declarations, Apple Privacy Nutrition labels, and server deployment instructions for launching **Chefni AI**.

---

## 1. Production Build Commands

### Flutter Cross-Platform App (`chefni_flutter_app`)

```bash
# 1. Fetch dependencies
cd chefni_flutter_app
flutter pub get

# 2. Build Android Production App Bundle (AAB for Google Play Store)
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

# 3. Build Android APK (for direct testing/distribution)
flutter build apk --release

# 4. Build iOS IPA (for Apple App Store)
flutter build ipa --release

# 5. Build Web Bundle (for Web deployment)
flutter build web --release
```

### Laravel RESTful API Backend (`chefni_backend`)

```bash
cd chefni_backend
composer install --no-dev --optimize-autoloader
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan migrate --force

# Reels and thumbnails are served from the public disk.
php artisan storage:link
```

### Server prerequisites (video pipeline)

The upload pipeline will not run without these. Shared hosting is not enough —
this needs a VPS or container host.

1. **FFmpeg + ffprobe on PATH.** `ffmpeg -version` must succeed as the web user.
   If they live outside PATH, set `FFMPEG_BINARY` / `FFPROBE_BINARY` to absolute
   paths. Without them the upload endpoint returns `503` rather than queueing a
   job that cannot encode.

2. **A queue worker.** `QUEUE_CONNECTION=database` (or `redis`); encoding runs
   out of band. Under `sync` the upload request blocks until FFmpeg finishes and
   will exceed the client timeout on any real video.

   ```bash
   php artisan queue:work --queue=video,default --timeout=900 --tries=1
   ```

   Run it under supervisor/systemd so it restarts on failure. The worker timeout
   must stay below `DB_QUEUE_RETRY_AFTER` (900s) or jobs double-process.

3. **Upload limits.** Raw uploads are capped at 500 MB in the controller; PHP
   must allow at least that: `upload_max_filesize=512M`, `post_max_size=512M`,
   `max_execution_time=300`. Match `client_max_body_size 512M;` in nginx.

4. **Watermark asset.** Place the Chefni logo PNG at
   `storage/app/public/assets/chefni_logo_watermark.png`. If it is missing the
   encode still succeeds — the reel just carries no watermark.

5. **Disk headroom.** Raw uploads land in `storage/app/raw_uploads` and are
   deleted once the reel is produced, but concurrent jobs hold several at once.

---

## 2. Google Play Console Data Safety Declarations

When publishing to Google Play, declare the following data safety items:

- **Personal Info**: Email address (collected for Account authentication & 14-day free trial tracking).
- **User Generated Content**: Uploaded cooking videos. The raw upload is deleted
  once the 1-minute reel is produced; the reel, its transcript and the generated
  recipe card are retained privately in the user's dashboard.
- **App Activity**: Analytics & video watch completion metrics.
- **Financial Data**: In-App Purchase history & subscription tier status.
- **Data Security**: All data transferred over HTTPS TLS 1.3 encrypted connection.
- **Data Erasure**: In-App Account Deletion option provided in App Settings.

**Third-party processing — must be disclosed.** Uploaded video audio is sent to
OpenAI (Whisper) for transcription, and the resulting transcript is sent to
Anthropic (Claude) to generate the recipe card. Both are data processors for
this flow and belong in the privacy policy and the Play Console's data-sharing
declaration; the same disclosure is needed for App Store Connect. Confirm the
current retention terms of both providers before submitting.

---

## 3. Apple App Store Privacy Nutrition Labels

When submitting to App Store Connect:

- **Data Used to Track You**: None.
- **Data Linked to You**: User Contact Info (Email), Purchases, User Content (Private Cooking Videos).
- **Account Deletion Link**: Integrated directly in app settings per Guideline 5.1.1(v).

---

## 4. Environment Variables Checklist

Ensure the following variables are set in production `.env`:

```env
APP_NAME="Chefni AI"
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.chefni.com

# Video processing runs out of band — see "Server prerequisites" above.
QUEUE_CONNECTION=database
FILESYSTEM_DISK=local

# Media toolchain. Absolute paths when the web user has a trimmed PATH.
FFMPEG_BINARY=ffmpeg
FFPROBE_BINARY=ffprobe

# Recipe extraction: the video's audio is transcribed, then turned into a
# recipe card with per-ingredient cost estimates. Without these keys the
# pipeline still produces reels — it stops before the recipe card and records
# why on the video.
ANTHROPIC_API_KEY=sk-ant-xxx
ANTHROPIC_MODEL=claude-opus-5
OPENAI_API_KEY=sk-xxx
OPENAI_TRANSCRIPTION_MODEL=whisper-1

STRIPE_KEY=pk_live_chefni_xxx
STRIPE_SECRET=sk_live_chefni_xxx

ADMOB_APP_ID_ANDROID=ca-app-pub-xxx~xxx
ADMOB_APP_ID_IOS=ca-app-pub-xxx~xxx
```

### Per-upload AI cost

Transcription and extraction are billed per video, not per install. Budget
roughly **$0.02–0.05 per uploaded video** (Whisper on a 60-second clip plus one
Claude extraction call). Free-tier accounts are capped at 2 uploads/month, so
the exposure scales with paid subscribers rather than signups.
