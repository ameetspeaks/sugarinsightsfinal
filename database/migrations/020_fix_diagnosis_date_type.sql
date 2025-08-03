-- Fix diagnosis_date column type to accept descriptive text
-- This migration changes the diagnosis_date column from DATE to TEXT
-- to accommodate the onboarding flow which sends descriptive text

-- Change the column type from DATE to TEXT
ALTER TABLE user_profiles 
ALTER COLUMN diagnosis_date TYPE TEXT;

-- Add a comment to document the change
COMMENT ON COLUMN user_profiles.diagnosis_date IS 'Diagnosis timeline as descriptive text (e.g., "Less than 6 months ago", "More than 5 year ago")';

-- Success message
SELECT 'Diagnosis date column type changed from DATE to TEXT successfully!' as status; 