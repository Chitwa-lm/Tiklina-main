-- Tiklina Waste Management Database Schema
-- This schema will auto-create tables as users interact with the app
-- Run this in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==================== PROFILES TABLE ====================
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('Admin', 'Company', 'Council')),
  phone TEXT NOT NULL,
  email TEXT NOT NULL,
  company_name TEXT,
  market_name TEXT,
  location TEXT,
  contact_info TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
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

-- ==================== ROW LEVEL SECURITY (RLS) ====================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE waste_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_evidence ENABLE ROW LEVEL SECURITY;
ALTER TABLE collection_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE collection_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can read all profiles, but only update their own
CREATE POLICY "Public profiles are viewable by everyone" ON profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile" ON profiles
  FOR UPDATE USING (auth.uid() = user_id);

-- Waste Reports: Admins can create, everyone can read
CREATE POLICY "Waste reports are viewable by everyone" ON waste_reports
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create waste reports" ON waste_reports
  FOR INSERT WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "Reporters can update their own reports" ON waste_reports
  FOR UPDATE USING (auth.uid() = reporter_id);

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

-- ==================== SAMPLE DATA (Optional) ====================
-- Uncomment to insert sample data for testing

-- INSERT INTO profiles (user_id, role, phone, email, market_name, location) VALUES
-- (uuid_generate_v4(), 'Admin', '+254712345678', 'admin@market.com', 'Gikomba Market', 'Nairobi, Kenya');
