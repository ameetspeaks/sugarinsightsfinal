-- Content Views Table
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

-- Content Shares Table
CREATE TABLE content_shares (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    content_type VARCHAR(50) NOT NULL CHECK (content_type IN ('article', 'video')),
    content_id UUID NOT NULL,
    share_platform VARCHAR(50) NOT NULL, -- e.g., 'whatsapp', 'email', etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for better query performance
CREATE INDEX idx_views_user ON content_views(user_id);
CREATE INDEX idx_views_content ON content_views(content_type, content_id);
CREATE INDEX idx_views_completed ON content_views(completed) WHERE completed = true;
CREATE INDEX idx_shares_user ON content_shares(user_id);
CREATE INDEX idx_shares_content ON content_shares(content_type, content_id);

-- Enable RLS
ALTER TABLE content_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_shares ENABLE ROW LEVEL SECURITY;

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

-- Content shares policies
CREATE POLICY "Users can view their own share history" ON content_shares
    FOR SELECT USING (
        auth.uid() = user_id
    );

CREATE POLICY "Users can create their own share records" ON content_shares
    FOR INSERT WITH CHECK (
        auth.uid() = user_id
    );

-- Add trigger for updating timestamps
CREATE TRIGGER update_content_views_updated_at
    BEFORE UPDATE ON content_views
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add functions for analytics
CREATE OR REPLACE FUNCTION get_content_view_stats(
    p_content_type VARCHAR,
    p_content_id UUID
)
RETURNS TABLE (
    total_views BIGINT,
    unique_viewers BIGINT,
    avg_view_duration NUMERIC,
    completion_rate NUMERIC
) AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add function to get trending content
CREATE OR REPLACE FUNCTION get_trending_content(
    p_content_type VARCHAR,
    p_days INTEGER DEFAULT 7
)
RETURNS TABLE (
    content_id UUID,
    view_count BIGINT,
    share_count BIGINT,
    engagement_score NUMERIC
) AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER;