-- Add foreign key constraints to user_favorites table
-- This migration adds proper relationships between user_favorites and articles/videos tables

-- Add foreign key constraint for articles
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_user_favorites_articles' 
        AND table_name = 'user_favorites'
    ) THEN
        ALTER TABLE user_favorites 
        ADD CONSTRAINT fk_user_favorites_articles 
        FOREIGN KEY (content_id) REFERENCES articles(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Add foreign key constraint for videos
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_user_favorites_videos' 
        AND table_name = 'user_favorites'
    ) THEN
        ALTER TABLE user_favorites 
        ADD CONSTRAINT fk_user_favorites_videos 
        FOREIGN KEY (content_id) REFERENCES videos(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Add foreign key constraints to content_views table
-- Add foreign key constraint for articles in content_views
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_content_views_articles' 
        AND table_name = 'content_views'
    ) THEN
        ALTER TABLE content_views 
        ADD CONSTRAINT fk_content_views_articles 
        FOREIGN KEY (content_id) REFERENCES articles(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Add foreign key constraint for videos in content_views
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_content_views_videos' 
        AND table_name = 'content_views'
    ) THEN
        ALTER TABLE content_views 
        ADD CONSTRAINT fk_content_views_videos 
        FOREIGN KEY (content_id) REFERENCES videos(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Add foreign key constraints to content_shares table
-- Add foreign key constraint for articles in content_shares
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_content_shares_articles' 
        AND table_name = 'content_shares'
    ) THEN
        ALTER TABLE content_shares 
        ADD CONSTRAINT fk_content_shares_articles 
        FOREIGN KEY (content_id) REFERENCES articles(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Add foreign key constraint for videos in content_shares
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_content_shares_videos' 
        AND table_name = 'content_shares'
    ) THEN
        ALTER TABLE content_shares 
        ADD CONSTRAINT fk_content_shares_videos 
        FOREIGN KEY (content_id) REFERENCES videos(id) ON DELETE CASCADE;
    END IF;
END $$; 