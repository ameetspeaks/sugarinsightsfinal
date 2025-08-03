-- Migration: Articles Storage Bucket Setup
-- This migration sets up the storage bucket for articles images
-- Run this after creating the articles table and education_categories setup

-- 1. Storage bucket setup instructions (run these in Supabase Dashboard)
-- Note: You'll need to create the storage bucket manually in the Supabase Dashboard
-- Go to Storage > Create a new bucket
-- Bucket name: "articles"
-- Public bucket: Yes (to allow public access to images)
-- File size limit: 5MB
-- Allowed MIME types: image/*

-- 2. Storage policies (run these after creating the bucket)
-- Go to Storage > Policies and add these policies for the "articles" bucket:

-- Policy for public read access to articles bucket
-- Name: "Public read access"
-- Type: SELECT
-- Target roles: anon, authenticated
-- Policy definition: true

-- Policy for authenticated users to upload to articles bucket
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

-- 3. Verify the articles table exists and has the correct structure
-- This ensures the articles table is properly set up before configuring storage

-- Check if articles table exists and has required columns
DO $$
BEGIN
    -- Check if articles table exists
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'articles') THEN
        RAISE EXCEPTION 'Articles table does not exist. Please run the education tables migration first.';
    END IF;
    
    -- Check for required columns
    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'articles' AND column_name = 'image_url') THEN
        RAISE EXCEPTION 'Articles table missing image_url column. Please run the education tables migration first.';
    END IF;
    
    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'articles' AND column_name = 'summary') THEN
        RAISE EXCEPTION 'Articles table missing summary column. Please run the education tables migration first.';
    END IF;
    
    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'articles' AND column_name = 'author') THEN
        RAISE EXCEPTION 'Articles table missing author column. Please run the education tables migration first.';
    END IF;
    
    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'articles' AND column_name = 'read_time') THEN
        RAISE EXCEPTION 'Articles table missing read_time column. Please run the education tables migration first.';
    END IF;
    
    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'articles' AND column_name = 'is_featured') THEN
        RAISE EXCEPTION 'Articles table missing is_featured column. Please run the education tables migration first.';
    END IF;
    
    RAISE NOTICE 'Articles table structure verified successfully.';
END $$;

-- 4. Create indexes for better article performance (if they don't exist)
CREATE INDEX IF NOT EXISTS idx_articles_category_id ON public.articles(category_id);
CREATE INDEX IF NOT EXISTS idx_articles_is_published ON public.articles(is_published);
CREATE INDEX IF NOT EXISTS idx_articles_is_featured ON public.articles(is_featured);
CREATE INDEX IF NOT EXISTS idx_articles_created_at ON public.articles(created_at);
CREATE INDEX IF NOT EXISTS idx_articles_published_at ON public.articles(published_at) WHERE is_published = true;

-- 5. Verify the setup
SELECT 
    'Articles storage setup completed successfully' as status,
    COUNT(*) as article_count
FROM public.articles;

-- 6. Sample data verification (optional)
-- This helps verify that the articles table is working correctly
SELECT 
    'Articles table structure' as check_type,
    COUNT(*) as total_articles,
    COUNT(CASE WHEN is_published = true THEN 1 END) as published_articles,
    COUNT(CASE WHEN is_featured = true THEN 1 END) as featured_articles,
    COUNT(CASE WHEN image_url IS NOT NULL THEN 1 END) as articles_with_images
FROM public.articles; 