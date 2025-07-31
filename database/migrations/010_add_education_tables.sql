-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Education Categories Table
CREATE TABLE education_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    icon_name VARCHAR(100),
    image_path TEXT,
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Articles Table
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

-- Videos Table
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

-- User Favorites Table (simplified without complex foreign key constraints)
CREATE TABLE user_favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    content_type VARCHAR(50) NOT NULL CHECK (content_type IN ('article', 'video')),
    content_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, content_type, content_id)
);

-- Add indexes for better query performance
CREATE INDEX idx_articles_category ON articles(category_id);
CREATE INDEX idx_videos_category ON videos(category_id);
CREATE INDEX idx_articles_published ON articles(is_published, published_at) WHERE is_published = true;
CREATE INDEX idx_videos_published ON videos(is_published, published_at) WHERE is_published = true;
CREATE INDEX idx_favorites_user ON user_favorites(user_id);
CREATE INDEX idx_favorites_content ON user_favorites(content_type, content_id);

-- Add RLS (Row Level Security) policies
ALTER TABLE education_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;

-- Categories policies (anyone can read, only admin can modify)
CREATE POLICY "Categories are viewable by everyone" ON education_categories
    FOR SELECT USING (true);

CREATE POLICY "Categories are editable by admin" ON education_categories
    FOR ALL USING (
        auth.role() = 'admin'
    );

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

-- User favorites policies - Allow users to view their own favorites
CREATE POLICY "Users can view their own favorites" ON user_favorites
    FOR SELECT USING (
        auth.uid() = user_id
    );

CREATE POLICY "Users can manage their own favorites" ON user_favorites
    FOR ALL USING (
        auth.uid() = user_id
    );

-- Create trigger function for updating timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers for updating timestamps
CREATE TRIGGER update_education_categories_updated_at
    BEFORE UPDATE ON education_categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_articles_updated_at
    BEFORE UPDATE ON articles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_videos_updated_at
    BEFORE UPDATE ON videos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();