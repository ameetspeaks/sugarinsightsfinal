-- Migration: Create Videos Table
-- Run this manually on Supabase SQL Editor

-- 1. Create the videos table
CREATE TABLE IF NOT EXISTS public.videos (
    id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
    category_id uuid NULL,
    title character varying(255) NOT NULL,
    description text NULL,
    video_url text NOT NULL,
    thumbnail_url text NULL,
    duration integer NULL,
    author character varying(255) NULL,
    is_featured boolean NULL DEFAULT false,
    is_published boolean NULL DEFAULT false,
    published_at timestamp with time zone NULL,
    created_at timestamp with time zone NULL DEFAULT now(),
    updated_at timestamp with time zone NULL DEFAULT now(),
    CONSTRAINT videos_pkey PRIMARY KEY (id),
    CONSTRAINT videos_category_id_fkey FOREIGN KEY (category_id) REFERENCES education_categories (id) ON DELETE CASCADE
) TABLESPACE pg_default;

-- 2. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_videos_category ON public.videos USING btree (category_id) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_videos_published ON public.videos USING btree (is_published, published_at) TABLESPACE pg_default
WHERE (is_published = true);
CREATE INDEX IF NOT EXISTS idx_videos_is_featured ON public.videos (is_featured);
CREATE INDEX IF NOT EXISTS idx_videos_created_at ON public.videos (created_at);

-- 3. Create the trigger for videos table
DROP TRIGGER IF EXISTS update_videos_updated_at ON public.videos;
CREATE TRIGGER update_videos_updated_at 
    BEFORE UPDATE ON public.videos 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 4. Set up Row Level Security (RLS) policies
ALTER TABLE public.videos ENABLE ROW LEVEL SECURITY;

-- Policy for reading published videos (public read access)
CREATE POLICY "Allow public read access to published videos" ON public.videos
    FOR SELECT USING (is_published = true);

-- Policy for admin users to manage all videos
CREATE POLICY "Allow admin users to manage videos" ON public.videos
    FOR ALL USING (
        auth.role() = 'authenticated' AND 
        EXISTS (
            SELECT 1 FROM admin_users 
            WHERE admin_users.email = auth.jwt() ->> 'email'
            AND admin_users.status = 'active'
        )
    );

-- 5. Grant necessary permissions
GRANT ALL ON public.videos TO authenticated;
GRANT SELECT ON public.videos TO anon;

-- 6. Insert some sample videos (optional)
INSERT INTO public.videos (category_id, title, description, video_url, thumbnail_url, duration, author, is_featured, is_published, published_at) VALUES
    (
        (SELECT id FROM education_categories WHERE name = 'Diabetes Basics' LIMIT 1),
        'Understanding Type 2 Diabetes',
        'A comprehensive overview of Type 2 diabetes, its causes, symptoms, and management strategies.',
        'https://example.com/videos/understanding-type2-diabetes.mp4',
        'https://example.com/thumbnails/diabetes-basics.jpg',
        600,
        'Dr. Sarah Johnson',
        true,
        true,
        now()
    ),
    (
        (SELECT id FROM education_categories WHERE name = 'Nutrition Guide' LIMIT 1),
        'Healthy Eating for Diabetes',
        'Learn about the best foods to eat and avoid when managing diabetes.',
        'https://example.com/videos/healthy-eating-diabetes.mp4',
        'https://example.com/thumbnails/nutrition-guide.jpg',
        480,
        'Nutritionist Maria Rodriguez',
        true,
        true,
        now()
    ),
    (
        (SELECT id FROM education_categories WHERE name = 'Exercise & Fitness' LIMIT 1),
        'Safe Exercise for Diabetics',
        'Exercise routines and tips specifically designed for people with diabetes.',
        'https://example.com/videos/safe-exercise-diabetics.mp4',
        'https://example.com/thumbnails/exercise-fitness.jpg',
        720,
        'Fitness Trainer Mike Chen',
        false,
        true,
        now()
    )
ON CONFLICT (id) DO NOTHING;

-- 7. Verify the setup
SELECT 
    'videos table created successfully' as status,
    COUNT(*) as video_count
FROM public.videos; 