# Changelog

All notable changes to the Tiklina Waste Management App project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added - Backend Integration

#### Supabase Integration
- Added `supabase_flutter: ^2.5.0` package for backend database and authentication
- Created `lib/services/supabase_service.dart` with authentication methods:
  - Email/password sign up and sign in
  - Phone OTP authentication
  - Session management
  - User state tracking
- Created `lib/services/database_service.dart` with complete CRUD operations:
  - User profile management (upsert, get)
  - Waste report operations (create, get by user, get by ID, update status)
  - Report evidence handling (photo URLs with location data)
  - Collection request management (create, get pending, update status)
  - Job assignment operations (create, get by company)
  - Collection verification (create, confirm)
  - Review system (create, get by company, calculate average rating)
- Created `supabase_schema.sql` with complete database schema:
  - 7 main tables: profiles, waste_reports, report_evidence, collection_requests, job_assignments, collection_verifications, reviews
  - Row Level Security (RLS) policies for all tables
  - Indexes for performance optimization
  - Automatic timestamp updates
  - Foreign key relationships with cascade deletes
- Created `lib/config/supabase_config.dart` for configuration management

#### Cloudinary Integration
- Added `cloudinary_public: ^0.21.0` package for image storage
- Added `http: ^1.2.0` package for HTTP requests
- Created `lib/services/cloudinary_service.dart` with image operations:
  - Single image upload with folder and public ID support
  - Multiple image upload (batch processing)
  - Image deletion by public ID
  - Error handling for upload failures
- Created `lib/config/cloudinary_config.dart` for configuration management

#### Environment Variables
- Added `flutter_dotenv: ^5.1.0` package for secure credential management
- Created `.env.development` template for development environment
- Updated `lib/config/supabase_config.dart` to read from environment variables
- Updated `lib/config/cloudinary_config.dart` to read from environment variables
- Updated `lib/main.dart` to:
  - Load `.env` file on startup
  - Validate credentials before initialization
  - Show clear error messages if configuration is missing
- Added `.env` to assets in `pubspec.yaml`
- Updated `.gitignore` to exclude `.env` files

### Changed - Configuration

#### Dependencies
- **Removed Firebase dependencies:**
  - `firebase_core: ^4.6.0`
  - `firebase_auth: ^6.3.0`
  - `cloud_firestore: ^6.2.0`
  - `firebase_storage: ^13.2.0`
- **Updated Flutter SDK requirement:**
  - Changed from `^3.11.3` to `>=3.0.0 <4.0.0` for broader compatibility
- **Kept existing dependencies:**
  - `provider: ^6.1.5+1` (state management)
  - `image_picker: ^1.2.1` (camera/gallery access)
  - `geolocator: ^14.0.2` (GPS location)
  - `intl: ^0.20.2` (date formatting)

#### Android Configuration
- Updated `android/app/src/main/AndroidManifest.xml`:
  - Added `INTERNET` permission for Supabase and Cloudinary
  - Added `WRITE_EXTERNAL_STORAGE` permission (API 28 and below)
  - Added `ACCESS_FINE_LOCATION` permission for GPS tracking
  - Added `ACCESS_COARSE_LOCATION` permission for GPS tracking
  - Added camera and location hardware features (not required)
  - Changed app label from "tiklini" to "Tiklina"
- Updated `android/gradle.properties`:
  - Removed hardcoded Java home path: `org.gradle.java.home=C:/Program Files/Android/Android Studio/jbr`
  - Reduced JVM memory allocation from 8G to 4G
  - Reduced MaxMetaspaceSize from 4G to 2G
  - Removed ReservedCodeCacheSize parameter

#### Git Configuration
- Updated `.gitignore`:
  - Added `.env` file exclusion
  - Added `.env.local` exclusion
  - Added `.env.*.local` pattern exclusion

### Changed - UI/UX

#### Login Screen
- Updated `lib/screens/auth/login_screen.dart`:
  - Changed "EMAIL" and "PASSWORD" labels from center-aligned to left-aligned
  - Wrapped labels in `Align` widget with `Alignment.centerLeft`

#### Company Dashboard
- Updated `lib/screens/company/company_dashboard_screen.dart`:
  - **Home Tab:** Replaced hardcoded statistics with real data from JobStore
    - "Jobs Available" now shows actual count from `store.availableJobs.length`
    - "Completed Today" now shows actual count from completed jobs
    - "Efficiency Rate" changed to "--" (placeholder for future calculation)
  - **Recent Jobs:** Removed mock data ("Green Valley Market", "Coastal Bistro")
  - **Recent Jobs:** Now displays actual jobs from JobStore or empty state
  - Added empty state UI when no recent jobs exist

#### Complaint Details Screen
- Updated `lib/screens/admin/complaint_details_screen.dart`:
  - Removed hardcoded status: "Status: Collected by Company"
  - Removed hardcoded date: "Reported on: 24 Mar 2026"
  - Removed mock photo placeholders with text labels
  - Redesigned with modern UI matching app theme
  - Added proper empty state for photos
  - Updated button styling to match app design system

#### Verification Screen
- Updated `lib/screens/admin/verification_screen.dart`:
  - Removed hardcoded job details: "Job ID: #TK-8829 • Collected by Alex Green"
  - Removed hardcoded impact message: "This collection diverted 12.4kg of waste from local landfills"
  - Removed gamification mock data: "+15 Green Points for verifying"
  - Changed to generic success message: "Verification submitted successfully"
  - Simplified impact section to generic message: "Help keep the environment clean"
  - Updated success notification styling

### Added - Documentation

#### Setup and Configuration Guides
- Created `SETUP_GUIDE.md`:
  - Step-by-step Supabase project setup
  - Step-by-step Cloudinary account setup
  - Environment variable configuration instructions
  - Android permissions verification
  - Troubleshooting section
- Created `ENV_SETUP.md`:
  - Comprehensive environment variables guide
  - Why use .env files (security, flexibility, best practices)
  - Quick setup instructions
  - How environment variables work in the app
  - Security best practices (DO's and DON'Ts)
  - Troubleshooting common issues
  - Multiple environment setup (dev, staging, production)
  - Team collaboration guidelines
  - CI/CD integration examples



#### Project Overview
- Updated `README.md`:
  - Added comprehensive project description
  - Added features list with emojis
  - Added tech stack section
  - Added quick start guide
  - Added documentation links
  - Added project structure overview
  - Added user roles description
  - Added database schema overview
  - Added security section
  - Added contributing guidelines
  - Added support section
  - Added acknowledgments
- Created `implementation_plan.md` (if not existing):
  - Database schema (ERD) with Mermaid diagram
  - UI screens overview
  - User flows for Admin and Company roles

### Removed - Mock Data

#### Data Stores
- Verified `lib/services/auth_store.dart`:
  - `_users` list starts empty (no mock users)
- Verified `lib/services/job_store.dart`:
  - `_jobs` list starts empty (no mock jobs)

#### UI Components
- Removed from Company Dashboard Home Tab:
  - Hardcoded "12" jobs available
  - Hardcoded "4" completed today
  - Hardcoded "82%" efficiency rate
  - Mock job: "Green Valley Market" - Completed
  - Mock job: "Coastal Bistro" - In Progress
- Removed from Complaint Details Screen:
  - Hardcoded status text
  - Hardcoded date "24 Mar 2026"
  - Mock photo placeholder labels
- Removed from Verification Screen:
  - Hardcoded job ID "#TK-8829"
  - Hardcoded collector name "Alex Green"
  - Hardcoded waste amount "12.4kg"
  - Mock gamification "+15 Green Points"

### Fixed

#### Build Issues
- Fixed Gradle build failure:
  - Removed invalid Java home path from `gradle.properties`
  - Gradle now auto-detects system Java installation
- Fixed Flutter SDK compatibility:
  - Changed SDK constraint from `^3.11.3` to `>=3.0.0 <4.0.0`
  - Allows app to run on Flutter SDK 3.0.0 and above
- Fixed Cloudinary service compilation error:
  - Removed `deleteFile` method (not supported in cloudinary_public package)
  - Added `UnimplementedError` with helpful message
  - Image deletion must be done via Cloudinary dashboard or admin API

#### Security
- Fixed credential exposure risk:
  - Moved all credentials to `.env` file
  - Added `.env` to `.gitignore`
  - Removed hardcoded credentials from config files
  - Config files now read from environment variables

### Technical Details

#### File Structure Changes
```
Tiklina-main/
├── .env                              # NEW - Environment variables (gitignored)
├── .env.example                      # NEW - Environment template
├── .env.development                  # NEW - Development template
├── CHANGELOG.md                      # NEW - This file
├── CHECKLIST.md                      # NEW - Setup checklist
├── ENV_SETUP.md                      # NEW - Environment guide
├── IMPLEMENTATION_STATUS.md          # NEW - Project status
├── QUICK_REFERENCE.md                # NEW - Developer reference
├── SETUP_GUIDE.md                    # NEW - Setup instructions
├── supabase_schema.sql               # NEW - Database schema
├── README.md                         # UPDATED - Enhanced documentation
├── pubspec.yaml                      # UPDATED - Dependencies changed
├── .gitignore                        # UPDATED - Added .env exclusion
├── android/
│   ├── app/src/main/AndroidManifest.xml  # UPDATED - Permissions added
│   └── gradle.properties             # UPDATED - Removed Java path
└── lib/
    ├── config/
    │   ├── cloudinary_config.dart    # NEW - Cloudinary configuration
    │   └── supabase_config.dart      # NEW - Supabase configuration
    ├── services/
    │   ├── cloudinary_service.dart   # NEW - Image upload service
    │   ├── database_service.dart     # NEW - Database operations
    │   ├── supabase_service.dart     # NEW - Auth service
    │   ├── auth_store.dart           # EXISTING - No changes
    │   └── job_store.dart            # EXISTING - No changes
    ├── screens/
    │   ├── auth/
    │   │   └── login_screen.dart     # UPDATED - Label alignment
    │   ├── admin/
    │   │   ├── complaint_details_screen.dart  # UPDATED - Removed mock data
    │   │   └── verification_screen.dart       # UPDATED - Removed mock data
    │   └── company/
    │       └── company_dashboard_screen.dart  # UPDATED - Removed mock data
    └── main.dart                     # UPDATED - Added env loading
```

#### Database Schema
- **Tables Created:** 7
  - `profiles` - User profiles with role-based data
  - `waste_reports` - Waste reports from market admins
  - `report_evidence` - Photo evidence for reports
  - `collection_requests` - Marketplace collection requests
  - `job_assignments` - Jobs accepted by companies
  - `collection_verifications` - Completion proof
  - `reviews` - Company ratings and reviews
- **Indexes Created:** 10 (for performance optimization)
- **RLS Policies:** Enabled on all tables with appropriate access controls
- **Relationships:** Foreign keys with CASCADE delete

#### API Endpoints (via Supabase)
- Authentication: Sign up, sign in, sign out, OTP verification
- Profiles: Upsert, get by user ID
- Waste Reports: Create, get by user, get by ID, update status
- Collection Requests: Create, get pending, update status
- Job Assignments: Create, get by company
- Collection Verifications: Create, confirm
- Reviews: Create, get by company, calculate average rating

### Migration Notes

#### From Firebase to Supabase
- **Authentication:**
  - Firebase Auth → Supabase Auth
  - Email/password supported
  - Phone OTP supported (requires SMS provider setup)
- **Database:**
  - Cloud Firestore → PostgreSQL (via Supabase)
  - NoSQL documents → SQL tables with relationships
  - Real-time listeners → Supabase subscriptions (not yet implemented)
- **Storage:**
  - Firebase Storage → Cloudinary
  - Direct file upload → URL-based storage
  - Automatic CDN delivery

#### Breaking Changes
- **Environment Variables Required:**
  - App will not run without `.env` file
  - Must configure Supabase and Cloudinary credentials
- **Database Schema:**
  - Must run `supabase_schema.sql` before first use
  - No automatic migration from Firebase
- **Authentication:**
  - Existing Firebase users will need to re-register
  - No user data migration provided

### Known Issues
- **Flutter Path with Spaces:** If Flutter is installed in `C:\Program Files\flutter`, some build tools may have issues with the space in the path. Workaround: Run `flutter clean` and `flutter pub get` before building.
- **Cloudinary Image Deletion:** The `cloudinary_public` package doesn't support image deletion with unsigned uploads. Use Cloudinary dashboard for manual deletion or implement signed uploads with admin API.

### Deprecated
- Firebase integration (completely removed)
- Hardcoded configuration values (replaced with environment variables)
- Mock data in UI components (replaced with real data or empty states)

### Security
- Added Row Level Security (RLS) policies to all database tables
- Moved sensitive credentials to environment variables
- Added `.env` to `.gitignore` to prevent credential leaks
- Implemented proper authentication checks in database operations

### Performance
- Added database indexes for frequently queried fields
- Optimized image uploads with quality and size constraints
- Reduced Gradle memory allocation for faster builds

---

## Version History

### [0.2.0] - 2024-01-XX (Current)
- Complete backend migration from Firebase to Supabase
- Added Cloudinary for image storage
- Implemented environment variable configuration
- Removed all mock data
- Enhanced documentation

### [0.1.0] - Initial Version
- Basic Flutter app structure
- Firebase integration (deprecated)
- Mock data for UI development
- Admin and Company user flows
- Local state management with Provider

---

## How to Update

### For Developers Already Working on This Project

1. **Pull Latest Changes:**
   ```bash
   git pull origin main
   ```

2. **Install New Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Set Up Environment Variables:**
   ```bash
   cp .env.example .env
   # Edit .env with your credentials
   ```

4. **Set Up Supabase:**
   - Create a Supabase project
   - Run the SQL in `supabase_schema.sql`
   - Add credentials to `.env`

5. **Set Up Cloudinary:**
   - Create a Cloudinary account
   - Create an unsigned upload preset
   - Add credentials to `.env`

6. **Clean and Rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### For New Developers

Follow the complete setup guide in `SETUP_GUIDE.md` or use the checklist in `CHECKLIST.md`.

---

## Contributing

When making changes to this project:

1. Update this CHANGELOG.md with your changes
2. Follow the format: Added, Changed, Deprecated, Removed, Fixed, Security
3. Include file paths and specific details
4. Update relevant documentation files
5. Test thoroughly before committing

---

## Questions or Issues?

- Check `SETUP_GUIDE.md` for setup issues
- Check `QUICK_REFERENCE.md` for code examples
- Check `CHECKLIST.md` to verify your setup
- Check `ENV_SETUP.md` for environment variable issues
- Review `IMPLEMENTATION_STATUS.md` for project status
