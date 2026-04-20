# Tiklina Waste Management App

A Flutter mobile application connecting market administrators with waste collection companies for efficient waste management.

## Features

- 📱 **Market Admin Portal**: Report waste with photos and GPS tracking
- 🚛 **Waste Collector Dashboard**: View and accept collection jobs
- 📸 **Photo Evidence**: Before and after collection documentation
- ⭐ **Rating System**: Review and rate waste collection services
- 🗺️ **GPS Integration**: Accurate location tracking for waste sites
- 🔐 **Secure Authentication**: Email/password and phone OTP support

## Tech Stack

- **Frontend**: Flutter/Dart
- **Backend**: Supabase (PostgreSQL + Auth)
- **Image Storage**: Cloudinary
- **State Management**: Provider
- **Location**: Geolocator
- **Image Capture**: Image Picker

## Quick Start

### Prerequisites

- Flutter SDK 3.0.0 or higher
- Android Studio / VS Code
- Supabase account (free tier available)
- Cloudinary account (free tier available)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Tiklina-main
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` and add your credentials:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your_anon_key
   CLOUDINARY_CLOUD_NAME=your_cloud_name
   CLOUDINARY_UPLOAD_PRESET=your_upload_preset
   ```

4. **Set up Supabase database**
   - Create a Supabase project
   - Run the SQL in `supabase_schema.sql` in your Supabase SQL Editor

5. **Run the app**
   ```bash
   flutter run
   ```

## Documentation

- ✅ [Setup Checklist](CHECKLIST.md) - Step-by-step setup verification
- 📖 [Setup Guide](SETUP_GUIDE.md) - Detailed setup instructions
- 🔐 [Environment Setup](ENV_SETUP.md) - .env configuration guide
- 📋 [Implementation Status](IMPLEMENTATION_STATUS.md) - Current progress and next steps
- 🗂️ [Implementation Plan](implementation_plan.md) - Database schema and UI flows
- ⚡ [Quick Reference](QUICK_REFERENCE.md) - Code snippets and common patterns

## Project Structure

```
lib/
├── config/              # Configuration files
│   ├── cloudinary_config.dart
│   └── supabase_config.dart
├── models/              # Data models
│   ├── user_model.dart
│   ├── waste_report.dart
│   ├── job_model.dart
│   └── review_model.dart
├── screens/             # UI screens
│   ├── auth/           # Authentication screens
│   ├── admin/          # Market admin screens
│   └── company/        # Waste collector screens
├── services/            # Business logic
│   ├── supabase_service.dart
│   ├── database_service.dart
│   ├── cloudinary_service.dart
│   ├── auth_store.dart
│   └── job_store.dart
└── main.dart           # App entry point
```

## User Roles

### Market Administrator
- Register market details
- Report waste with photos and GPS
- Track complaint status
- Request private collection
- Verify collection completion
- Rate waste collection companies

### Waste Collection Company
- View available collection requests
- Accept jobs in service area
- Upload completion photos
- Track job history
- View ratings and reviews

## Database Schema

The app uses 7 main tables:
- `profiles` - User profiles and role data
- `waste_reports` - Waste reports from admins
- `report_evidence` - Photo evidence
- `collection_requests` - Marketplace requests
- `job_assignments` - Accepted jobs
- `collection_verifications` - Completion proof
- `reviews` - Company ratings

See `supabase_schema.sql` for complete schema.

## Security

- Row Level Security (RLS) enabled on all tables
- Users can only modify their own data
- All API calls authenticated via Supabase
- Environment variables for sensitive credentials
- `.env` file gitignored

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## License

[Add your license here]

## Support

For issues and questions:
- Check the [Setup Guide](SETUP_GUIDE.md)
- Review [Implementation Status](IMPLEMENTATION_STATUS.md)
- Open an issue on GitHub

## Acknowledgments

- Built with Flutter
- Powered by Supabase
- Images hosted on Cloudinary
