-- Migration to add missing education tables (only if they don't exist)
-- This migration handles the case where some tables already exist

-- Check if articles table exists, if not create it
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'articles') THEN
        CREATE TABLE articles (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            category_id UUID REFERENCES education_categories(id) ON DELETE CASCADE,
            title VARCHAR(255) NOT NULL,
            content TEXT NOT NULL,
            summary TEXT,
            image_url TEXT,
            author VARCHAR(255),
            read_time INTEGER, -- in minutes
            is_featured BOOLEAN DEFAULT false,
            is_published BOOLEAN DEFAULT false,
            published_at TIMESTAMP WITH TIME ZONE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        -- Add indexes for articles
        CREATE INDEX idx_articles_category ON articles(category_id);
        CREATE INDEX idx_articles_published ON articles(is_published, published_at) WHERE is_published = true;
        
        -- Enable RLS
        ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
        
        -- Articles policies
        CREATE POLICY "Published articles are viewable by everyone" ON articles
            FOR SELECT USING (
                is_published = true
                OR auth.role() = 'admin'
            );

        CREATE POLICY "Articles are editable by admin" ON articles
            FOR ALL USING (
                auth.role() = 'admin'
            );
            
        -- Add trigger for articles
        CREATE TRIGGER update_articles_updated_at
            BEFORE UPDATE ON articles
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- Check if videos table exists, if not create it
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'videos') THEN
        CREATE TABLE videos (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            category_id UUID REFERENCES education_categories(id) ON DELETE CASCADE,
            title VARCHAR(255) NOT NULL,
            description TEXT,
            video_url TEXT NOT NULL,
            thumbnail_url TEXT,
            duration INTEGER, -- in seconds
            author VARCHAR(255),
            is_featured BOOLEAN DEFAULT false,
            is_published BOOLEAN DEFAULT false,
            published_at TIMESTAMP WITH TIME ZONE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        -- Add indexes for videos
        CREATE INDEX idx_videos_category ON videos(category_id);
        CREATE INDEX idx_videos_published ON videos(is_published, published_at) WHERE is_published = true;
        
        -- Enable RLS
        ALTER TABLE videos ENABLE ROW LEVEL SECURITY;
        
        -- Videos policies
        CREATE POLICY "Published videos are viewable by everyone" ON videos
            FOR SELECT USING (
                is_published = true
                OR auth.role() = 'admin'
            );

        CREATE POLICY "Videos are editable by admin" ON videos
            FOR ALL USING (
                auth.role() = 'admin'
            );
            
        -- Add trigger for videos
        CREATE TRIGGER update_videos_updated_at
            BEFORE UPDATE ON videos
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- Check if user_favorites table exists, if not create it
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_favorites') THEN
        CREATE TABLE user_favorites (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID NOT NULL,
            content_type VARCHAR(50) NOT NULL CHECK (content_type IN ('article', 'video')),
            content_id UUID NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            UNIQUE(user_id, content_type, content_id)
        );
        
        -- Add indexes for user_favorites
        CREATE INDEX idx_favorites_user ON user_favorites(user_id);
        CREATE INDEX idx_favorites_content ON user_favorites(content_type, content_id);
        
        -- Enable RLS
        ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;
        
        -- User favorites policies
        CREATE POLICY "Users can view their own favorites" ON user_favorites
            FOR SELECT USING (
                auth.uid() = user_id
            );

        CREATE POLICY "Users can manage their own favorites" ON user_favorites
            FOR ALL USING (
                auth.uid() = user_id
            );
    END IF;
END $$;

-- Check if content_views table exists, if not create it
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'content_views') THEN
        CREATE TABLE content_views (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID NOT NULL,
            content_type VARCHAR(50) NOT NULL CHECK (content_type IN ('article', 'video')),
            content_id UUID NOT NULL,
            view_duration INTEGER, -- in seconds, especially useful for videos
            completed BOOLEAN DEFAULT false, -- track if article was fully read or video fully watched
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        -- Add indexes for content_views
        CREATE INDEX idx_views_user ON content_views(user_id);
        CREATE INDEX idx_views_content ON content_views(content_type, content_id);
        CREATE INDEX idx_views_completed ON content_views(completed) WHERE completed = true;
        
        -- Enable RLS
        ALTER TABLE content_views ENABLE ROW LEVEL SECURITY;
        
        -- Content views policies
        CREATE POLICY "Users can view their own view history" ON content_views
            FOR SELECT USING (
                auth.uid() = user_id
            );

        CREATE POLICY "Users can create their own view records" ON content_views
            FOR INSERT WITH CHECK (
                auth.uid() = user_id
            );

        CREATE POLICY "Users can update their own view records" ON content_views
            FOR UPDATE USING (
                auth.uid() = user_id
            );
            
        -- Add trigger for content_views
        CREATE TRIGGER update_content_views_updated_at
            BEFORE UPDATE ON content_views
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- Check if content_shares table exists, if not create it
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'content_shares') THEN
        CREATE TABLE content_shares (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID NOT NULL,
            content_type VARCHAR(50) NOT NULL CHECK (content_type IN ('article', 'video')),
            content_id UUID NOT NULL,
            share_platform VARCHAR(50) NOT NULL, -- e.g., 'whatsapp', 'email', etc.
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        -- Add indexes for content_shares
        CREATE INDEX idx_shares_user ON content_shares(user_id);
        CREATE INDEX idx_shares_content ON content_shares(content_type, content_id);
        
        -- Enable RLS
        ALTER TABLE content_shares ENABLE ROW LEVEL SECURITY;
        
        -- Content shares policies
        CREATE POLICY "Users can view their own share history" ON content_shares
            FOR SELECT USING (
                auth.uid() = user_id
            );

        CREATE POLICY "Users can create their own share records" ON content_shares
            FOR INSERT WITH CHECK (
                auth.uid() = user_id
            );
    END IF;
END $$;

-- Add analytics functions if they don't exist
DO $func$ 
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.routines WHERE routine_name = 'get_content_view_stats') THEN
        CREATE OR REPLACE FUNCTION get_content_view_stats(
            p_content_type VARCHAR,
            p_content_id UUID
        )
        RETURNS TABLE (
            total_views BIGINT,
            unique_viewers BIGINT,
            avg_view_duration NUMERIC,
            completion_rate NUMERIC
        ) AS $function$
        BEGIN
            RETURN QUERY
            SELECT 
                COUNT(*)::BIGINT as total_views,
                COUNT(DISTINCT user_id)::BIGINT as unique_viewers,
                COALESCE(AVG(view_duration)::NUMERIC, 0) as avg_view_duration,
                COALESCE((SUM(CASE WHEN completed THEN 1 ELSE 0 END)::NUMERIC / COUNT(*)::NUMERIC) * 100, 0) as completion_rate
            FROM content_views
            WHERE content_type = p_content_type
            AND content_id = p_content_id;
        END;
        $function$ LANGUAGE plpgsql SECURITY DEFINER;
    END IF;
END $func$;

DO $func$ 
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.routines WHERE routine_name = 'get_trending_content') THEN
        CREATE OR REPLACE FUNCTION get_trending_content(
            p_content_type VARCHAR,
            p_days INTEGER DEFAULT 7
        )
        RETURNS TABLE (
            content_id UUID,
            view_count BIGINT,
            share_count BIGINT,
            engagement_score NUMERIC
        ) AS $function$
        BEGIN
            RETURN QUERY
            WITH view_stats AS (
                SELECT 
                    cv.content_id,
                    COUNT(*) as views,
                    COUNT(DISTINCT cv.user_id) as unique_views
                FROM content_views cv
                WHERE cv.content_type = p_content_type
                AND cv.created_at >= NOW() - (p_days || ' days')::INTERVAL
                GROUP BY cv.content_id
            ),
            share_stats AS (
                SELECT 
                    cs.content_id,
                    COUNT(*) as shares
                FROM content_shares cs
                WHERE cs.content_type = p_content_type
                AND cs.created_at >= NOW() - (p_days || ' days')::INTERVAL
                GROUP BY cs.content_id
            )
            SELECT 
                COALESCE(v.content_id, s.content_id) as content_id,
                COALESCE(v.views, 0) as view_count,
                COALESCE(s.shares, 0) as share_count,
                (COALESCE(v.views, 0) * 1.0 + COALESCE(v.unique_views, 0) * 2.0 + COALESCE(s.shares, 0) * 3.0) as engagement_score
            FROM view_stats v
            FULL OUTER JOIN share_stats s ON v.content_id = s.content_id
            ORDER BY engagement_score DESC;
        END;
        $function$ LANGUAGE plpgsql SECURITY DEFINER;
    END IF;
END $func$; 