-- Migration: Education Categories Table and Storage Setup
-- Run this manually on Supabase SQL Editor

-- 1. Create the education_categories table
CREATE TABLE IF NOT EXISTS public.education_categories (
    id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
    name character varying(255) NOT NULL,
    description text NULL,
    icon_name character varying(100) NULL,
    image_path text NULL,
    is_active boolean NULL DEFAULT true,
    sort_order integer NULL,
    created_at timestamp with time zone NULL DEFAULT now(),
    updated_at timestamp with time zone NULL DEFAULT now(),
    CONSTRAINT education_categories_pkey PRIMARY KEY (id)
) TABLESPACE pg_default;

-- 2. Create the updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 3. Create the trigger for education_categories
DROP TRIGGER IF EXISTS update_education_categories_updated_at ON public.education_categories;
CREATE TRIGGER update_education_categories_updated_at 
    BEFORE UPDATE ON public.education_categories 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 4. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_education_categories_is_active ON public.education_categories(is_active);
CREATE INDEX IF NOT EXISTS idx_education_categories_sort_order ON public.education_categories(sort_order);
CREATE INDEX IF NOT EXISTS idx_education_categories_created_at ON public.education_categories(created_at);

-- 5. Set up Row Level Security (RLS) policies
ALTER TABLE public.education_categories ENABLE ROW LEVEL SECURITY;

-- Policy for reading categories (public read access)
CREATE POLICY "Allow public read access to education_categories" ON public.education_categories
    FOR SELECT USING (true);

-- Policy for admin users to manage categories
CREATE POLICY "Allow admin users to manage education_categories" ON public.education_categories
    FOR ALL USING (
        auth.role() = 'authenticated' AND 
        EXISTS (
            SELECT 1 FROM admin_users 
            WHERE admin_users.user_id = auth.uid() 
            AND admin_users.is_active = true
        )
    );

-- 6. Grant necessary permissions
GRANT ALL ON public.education_categories TO authenticated;
GRANT SELECT ON public.education_categories TO anon;

-- 7. Insert some sample categories (optional)
INSERT INTO public.education_categories (name, description, icon_name, sort_order, is_active) VALUES
    ('Diabetes Basics', 'Learn the fundamentals of diabetes management', 'fas fa-book-medical', 1, true),
    ('Nutrition Guide', 'Healthy eating tips for diabetes', 'fas fa-apple-alt', 2, true),
    ('Exercise & Fitness', 'Physical activity recommendations', 'fas fa-dumbbell', 3, true),
    ('Medication Management', 'Understanding your medications', 'fas fa-pills', 4, true),
    ('Blood Sugar Monitoring', 'How to track your glucose levels', 'fas fa-tint', 5, true),
    ('Complications Prevention', 'Preventing diabetes complications', 'fas fa-shield-alt', 6, true)
ON CONFLICT (id) DO NOTHING;

-- 8. Storage bucket setup instructions (run these in Supabase Dashboard)
-- Note: You'll need to create the storage bucket manually in the Supabase Dashboard
-- Go to Storage > Create a new bucket
-- Bucket name: "educationcategories"
-- Public bucket: Yes (to allow public access to images)
-- File size limit: 5MB
-- Allowed MIME types: image/*

-- 9. Storage policies (run these after creating the bucket)
-- Go to Storage > Policies and add these policies for the "educationcategories" bucket:

-- Policy for public read access to educationcategories bucket
-- Name: "Public read access"
-- Type: SELECT
-- Target roles: anon, authenticated
-- Policy definition: true

-- Policy for authenticated users to upload to educationcategories bucket
-- Name: "Authenticated users can upload"
-- Type: INSERT
-- Target roles: authenticated
-- Policy definition: auth.role() = 'authenticated'

-- Policy for authenticated users to update their uploads
-- Name: "Authenticated users can update"
-- Type: UPDATE
-- Target roles: authenticated
-- Policy definition: auth.role() = 'authenticated'

-- Policy for authenticated users to delete their uploads
-- Name: "Authenticated users can delete"
-- Type: DELETE
-- Target roles: authenticated
-- Policy definition: auth.role() = 'authenticated'

-- 10. Verify the setup
SELECT 
    'education_categories table created successfully' as status,
    COUNT(*) as category_count
FROM public.education_categories; 