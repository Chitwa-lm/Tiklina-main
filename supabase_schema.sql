-- Tiklina Waste Management Database Schema
-- This schema will auto-create tables as users interact with the app
-- Run this in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==================== PROFILES TABLE ====================
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('Admin', 'Company', 'Council', 'Client', 'Collector')),
  phone TEXT NOT NULL,
  email TEXT NOT NULL,
  company_name TEXT,
  market_name TEXT,
  location TEXT,
  contact_info TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  -- Gig Economy Fields
  service_radius_km INTEGER DEFAULT 5,
  is_online BOOLEAN DEFAULT FALSE,
  last_location_lat DECIMAL(10, 8),
  last_location_lng DECIMAL(11, 8),
  device_token TEXT,
  bank_account_number TEXT,
  bank_account_holder_name TEXT,
  UNIQUE(user_id)
);

-- ==================== WASTE REPORTS TABLE ====================
CREATE TABLE IF NOT EXISTS waste_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  market_name TEXT NOT NULL,
  location_lat DOUBLE PRECISION NOT NULL,
  location_lng DOUBLE PRECISION NOT NULL,
  description TEXT NOT NULL,
  est_volume TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'Submitted' CHECK (status IN ('Submitted', 'Accepted', 'In Progress', 'Completed')),
  accepted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  accepted_at TIMESTAMPTZ,
  reported_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==================== REPORT EVIDENCE TABLE ====================
CREATE TABLE IF NOT EXISTS report_evidence (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  report_id UUID REFERENCES waste_reports(id) ON DELETE CASCADE NOT NULL,
  photo_url TEXT NOT NULL,
  location_lat DOUBLE PRECISION NOT NULL,
  location_lng DOUBLE PRECISION NOT NULL,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- ==================== COLLECTION REQUESTS TABLE ====================
CREATE TABLE IF NOT EXISTS collection_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  report_id UUID REFERENCES waste_reports(id) ON DELETE CASCADE NOT NULL,
  status TEXT NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending', 'Accepted', 'Completed')),
  requested_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==================== JOB ASSIGNMENTS TABLE ====================
CREATE TABLE IF NOT EXISTS job_assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  request_id UUID REFERENCES collection_requests(id) ON DELETE CASCADE NOT NULL,
  company_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  accepted_at TIMESTAMPTZ DEFAULT NOW(),
  scheduled_pickup_at TIMESTAMPTZ NOT NULL
);

-- ==================== COLLECTION VERIFICATIONS TABLE ====================
CREATE TABLE IF NOT EXISTS collection_verifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id UUID REFERENCES job_assignments(id) ON DELETE CASCADE NOT NULL,
  collector_photo_url TEXT NOT NULL,
  admin_confirmed BOOLEAN DEFAULT FALSE,
  confirmed_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==================== REVIEWS TABLE ====================
CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id UUID REFERENCES job_assignments(id) ON DELETE CASCADE NOT NULL,
  reviewer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  company_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==================== GIG ECONOMY TABLES ====================

-- ==================== WASTE REQUESTS TABLE (Gig Model) ====================
CREATE TABLE IF NOT EXISTS waste_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  location_lat DECIMAL(10, 8) NOT NULL,
  location_lng DECIMAL(11, 8) NOT NULL,
  location_address TEXT,
  waste_type VARCHAR(50) NOT NULL,
  volume_category VARCHAR(20) NOT NULL,
  description TEXT NOT NULL,
  estimated_cost DECIMAL(10, 2) NOT NULL,
  status VARCHAR(20) DEFAULT 'Pending' CHECK (status IN ('Pending', 'Accepted', 'In_Transit', 'Completed', 'Cancelled')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  accepted_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  collector_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  cancellation_reason TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==================== REQUEST PHOTOS TABLE ====================
CREATE TABLE IF NOT EXISTS request_photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  request_id UUID NOT NULL REFERENCES waste_requests(id) ON DELETE CASCADE,
  photo_url TEXT NOT NULL,
  photo_type VARCHAR(20),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==================== COLLECTOR SESSIONS TABLE ====================
CREATE TABLE IF NOT EXISTS collector_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  collector_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  online_at TIMESTAMPTZ DEFAULT NOW(),
  offline_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  last_location_lat DECIMAL(10, 8),
  last_location_lng DECIMAL(11, 8),
  last_updated_at TIMESTAMPTZ DEFAULT NOW(),
  requests_notified INT DEFAULT 0,
  requests_accepted INT DEFAULT 0
);

-- ==================== REQUEST NOTIFICATIONS TABLE ====================
CREATE TABLE IF NOT EXISTS request_notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  request_id UUID NOT NULL REFERENCES waste_requests(id) ON DELETE CASCADE,
  collector_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  notified_at TIMESTAMPTZ DEFAULT NOW(),
  seen_at TIMESTAMPTZ,
  notification_status VARCHAR(20) DEFAULT 'Notified' CHECK (notification_status IN ('Notified', 'Seen', 'Accepted', 'Rejected', 'Expired')),
  notification_reason VARCHAR(50),
  distance_km DECIMAL(6, 2),
  UNIQUE(request_id, collector_id)
);

-- ==================== WASTE PICKUPS TABLE (Gig Job) ====================
CREATE TABLE IF NOT EXISTS waste_pickups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  request_id UUID NOT NULL REFERENCES waste_requests(id) ON DELETE CASCADE,
  collector_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status VARCHAR(20) DEFAULT 'Accepted' CHECK (status IN ('Accepted', 'In_Transit', 'Completed', 'Cancelled')),
  accepted_at TIMESTAMPTZ DEFAULT NOW(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  completion_photo_url TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==================== WALLETS TABLE ====================
CREATE TABLE IF NOT EXISTS wallets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  balance DECIMAL(12, 2) DEFAULT 0.00,
  currency VARCHAR(3) DEFAULT 'USD',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==================== TRANSACTIONS TABLE ====================
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('Payment', 'Earning', 'Withdrawal', 'Refund', 'Bonus')),
  amount DECIMAL(10, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  status VARCHAR(20) DEFAULT 'Completed' CHECK (status IN ('Pending', 'Completed', 'Failed', 'Rejected')),
  related_request_id UUID REFERENCES waste_requests(id) ON DELETE SET NULL,
  related_pickup_id UUID REFERENCES waste_pickups(id) ON DELETE SET NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- ==================== RATINGS TABLE (Gig Ratings) ====================
CREATE TABLE IF NOT EXISTS ratings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  request_id UUID NOT NULL REFERENCES waste_requests(id) ON DELETE CASCADE,
  rated_by_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rated_to_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  rated_role VARCHAR(20) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==================== INDEXES ====================
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_waste_reports_reporter_id ON waste_reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_waste_reports_status ON waste_reports(status);
CREATE INDEX IF NOT EXISTS idx_report_evidence_report_id ON report_evidence(report_id);
CREATE INDEX IF NOT EXISTS idx_collection_requests_report_id ON collection_requests(report_id);
CREATE INDEX IF NOT EXISTS idx_collection_requests_status ON collection_requests(status);
CREATE INDEX IF NOT EXISTS idx_job_assignments_company_id ON job_assignments(company_id);
CREATE INDEX IF NOT EXISTS idx_job_assignments_request_id ON job_assignments(request_id);
CREATE INDEX IF NOT EXISTS idx_reviews_company_id ON reviews(company_id);
CREATE INDEX IF NOT EXISTS idx_reviews_job_id ON reviews(job_id);
-- GIG ECONOMY INDEXES
CREATE INDEX IF NOT EXISTS idx_waste_requests_client_id ON waste_requests(client_id);
CREATE INDEX IF NOT EXISTS idx_waste_requests_collector_id ON waste_requests(collector_id);
CREATE INDEX IF NOT EXISTS idx_waste_requests_status ON waste_requests(status);
CREATE INDEX IF NOT EXISTS idx_waste_requests_location ON waste_requests(location_lat, location_lng);
CREATE INDEX IF NOT EXISTS idx_request_photos_request_id ON request_photos(request_id);
CREATE INDEX IF NOT EXISTS idx_collector_sessions_collector_id ON collector_sessions(collector_id);
CREATE INDEX IF NOT EXISTS idx_collector_sessions_is_active ON collector_sessions(is_active);
CREATE INDEX IF NOT EXISTS idx_request_notifications_request_id ON request_notifications(request_id);
CREATE INDEX IF NOT EXISTS idx_request_notifications_collector_id ON request_notifications(collector_id);
CREATE INDEX IF NOT EXISTS idx_waste_pickups_request_id ON waste_pickups(request_id);
CREATE INDEX IF NOT EXISTS idx_waste_pickups_collector_id ON waste_pickups(collector_id);
CREATE INDEX IF NOT EXISTS idx_waste_pickups_status ON waste_pickups(status);
CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_request_id ON transactions(related_request_id);
CREATE INDEX IF NOT EXISTS idx_ratings_request_id ON ratings(request_id);
CREATE INDEX IF NOT EXISTS idx_ratings_rated_by_id ON ratings(rated_by_id);
CREATE INDEX IF NOT EXISTS idx_ratings_rated_to_id ON ratings(rated_to_id);

-- ==================== ROW LEVEL SECURITY (RLS) ====================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE waste_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_evidence ENABLE ROW LEVEL SECURITY;
ALTER TABLE collection_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE collection_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
-- GIG ECONOMY RLS
ALTER TABLE waste_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE request_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE collector_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE request_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE waste_pickups ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can read all profiles, but only update their own
CREATE POLICY "Public profiles are viewable by everyone" ON profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile" ON profiles
  FOR UPDATE USING (auth.uid() = user_id);

-- Waste Reports: Admins can create, everyone can read, collectors can update status
CREATE POLICY "Waste reports are viewable by everyone" ON waste_reports
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create waste reports" ON waste_reports
  FOR INSERT WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "Reporters and collectors can update reports" ON waste_reports
  FOR UPDATE USING (auth.uid() = reporter_id OR auth.uid() = accepted_by OR auth.uid() IS NOT NULL);

-- Report Evidence: Linked to waste reports
CREATE POLICY "Report evidence is viewable by everyone" ON report_evidence
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert report evidence" ON report_evidence
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Collection Requests: Everyone can read, authenticated users can create
CREATE POLICY "Collection requests are viewable by everyone" ON collection_requests
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create collection requests" ON collection_requests
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update collection requests" ON collection_requests
  FOR UPDATE USING (auth.uid() IS NOT NULL);

-- Job Assignments: Everyone can read, companies can create
CREATE POLICY "Job assignments are viewable by everyone" ON job_assignments
  FOR SELECT USING (true);

CREATE POLICY "Companies can create job assignments" ON job_assignments
  FOR INSERT WITH CHECK (auth.uid() = company_id);

-- Collection Verifications: Everyone can read, authenticated users can create
CREATE POLICY "Collection verifications are viewable by everyone" ON collection_verifications
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create verifications" ON collection_verifications
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can update verifications" ON collection_verifications
  FOR UPDATE USING (auth.uid() IS NOT NULL);

-- Reviews: Everyone can read, authenticated users can create
CREATE POLICY "Reviews are viewable by everyone" ON reviews
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create reviews" ON reviews
  FOR INSERT WITH CHECK (auth.uid() = reviewer_id);

-- ==================== GIG ECONOMY POLICIES ====================

-- Waste Requests (Gig Model)
CREATE POLICY "Waste requests are viewable by everyone" ON waste_requests
  FOR SELECT USING (true);

CREATE POLICY "Clients can create their own requests" ON waste_requests
  FOR INSERT WITH CHECK (auth.uid() = client_id);

CREATE POLICY "Clients can update their own requests" ON waste_requests
  FOR UPDATE USING (auth.uid() = client_id);

-- Request Photos
CREATE POLICY "Request photos are viewable by everyone" ON request_photos
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create request photos" ON request_photos
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Collector Sessions
CREATE POLICY "Collector sessions are viewable by everyone" ON collector_sessions
  FOR SELECT USING (true);

CREATE POLICY "Collectors can create their own sessions" ON collector_sessions
  FOR INSERT WITH CHECK (auth.uid() = collector_id);

CREATE POLICY "Collectors can update their own sessions" ON collector_sessions
  FOR UPDATE USING (auth.uid() = collector_id);

-- Request Notifications
CREATE POLICY "Request notifications are viewable by everyone" ON request_notifications
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create notifications" ON request_notifications
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Waste Pickups (Gig Jobs)
CREATE POLICY "Waste pickups are viewable by everyone" ON waste_pickups
  FOR SELECT USING (true);

CREATE POLICY "Collectors can create pickups" ON waste_pickups
  FOR INSERT WITH CHECK (auth.uid() = collector_id);

CREATE POLICY "Collectors can update their own pickups" ON waste_pickups
  FOR UPDATE USING (auth.uid() = collector_id);

-- Wallets
CREATE POLICY "Users can view their own wallet" ON wallets
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own wallet" ON wallets
  FOR UPDATE USING (auth.uid() = user_id);

-- Transactions
CREATE POLICY "Users can view their own transactions" ON transactions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Authenticated users can create transactions" ON transactions
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Ratings (Gig Ratings)
CREATE POLICY "Ratings are viewable by everyone" ON ratings
  FOR SELECT USING (true);

CREATE POLICY "Users can create ratings" ON ratings
  FOR INSERT WITH CHECK (auth.uid() = rated_by_id);

-- ==================== FUNCTIONS ====================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for profiles table
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Triggers for gig economy tables
CREATE TRIGGER update_waste_requests_updated_at
  BEFORE UPDATE ON waste_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_waste_pickups_updated_at
  BEFORE UPDATE ON waste_pickups
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wallets_updated_at
  BEFORE UPDATE ON wallets
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ==================== SAMPLE DATA (Optional) ====================
-- Uncomment to insert sample data for testing

-- INSERT INTO profiles (user_id, role, phone, email, market_name, location) VALUES
-- (uuid_generate_v4(), 'Admin', '+254712345678', 'admin@market.com', 'Gikomba Market', 'Nairobi, Kenya');
