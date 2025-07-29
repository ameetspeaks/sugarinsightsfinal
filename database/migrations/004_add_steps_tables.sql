-- Add Steps Tables for Sugar Insights
-- This migration adds the missing tables for steps tracking functionality

-- Create steps_readings table
CREATE TABLE IF NOT EXISTS steps_readings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    steps_count INTEGER NOT NULL,
    activity_type TEXT DEFAULT 'walking',
    source TEXT DEFAULT 'manual',
    notes TEXT,
    reading_date DATE NOT NULL,
    reading_time TIME NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create steps_goals table
CREATE TABLE IF NOT EXISTS steps_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    daily_goal INTEGER NOT NULL DEFAULT 10000,
    weekly_goal INTEGER,
    monthly_goal INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    start_date DATE NOT NULL,
    end_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_steps_readings_user_id ON steps_readings(user_id);
CREATE INDEX idx_steps_readings_date ON steps_readings(reading_date);
CREATE INDEX idx_steps_goals_user_id ON steps_goals(user_id);
CREATE INDEX idx_steps_goals_active ON steps_goals(is_active);

-- Enable Row Level Security
ALTER TABLE steps_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE steps_goals ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for steps_readings
CREATE POLICY "Users can view own steps readings" ON steps_readings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own steps readings" ON steps_readings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own steps readings" ON steps_readings
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own steps readings" ON steps_readings
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for steps_goals
CREATE POLICY "Users can view own steps goals" ON steps_goals
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own steps goals" ON steps_goals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own steps goals" ON steps_goals
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own steps goals" ON steps_goals
    FOR DELETE USING (auth.uid() = user_id);

-- Create function to get monthly steps statistics
CREATE OR REPLACE FUNCTION get_monthly_steps(user_uuid UUID, target_month DATE)
RETURNS INTEGER AS $$
DECLARE
    total_steps INTEGER;
BEGIN
    SELECT COALESCE(SUM(steps_count), 0)
    INTO total_steps
    FROM steps_readings
    WHERE user_id = user_uuid
    AND reading_date >= target_month
    AND reading_date < target_month + INTERVAL '1 month';
    
    RETURN total_steps;
END;
$$ LANGUAGE plpgsql;

-- Create function to get steps statistics
CREATE OR REPLACE FUNCTION get_steps_statistics(
    user_uuid UUID,
    start_date DATE,
    end_date DATE
)
RETURNS TABLE(
    total_steps INTEGER,
    average_steps DECIMAL,
    max_steps INTEGER,
    min_steps INTEGER,
    days_with_data INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(SUM(sr.steps_count), 0)::INTEGER as total_steps,
        COALESCE(AVG(sr.steps_count), 0)::DECIMAL as average_steps,
        COALESCE(MAX(sr.steps_count), 0)::INTEGER as max_steps,
        COALESCE(MIN(sr.steps_count), 0)::INTEGER as min_steps,
        COUNT(DISTINCT sr.reading_date)::INTEGER as days_with_data
    FROM steps_readings sr
    WHERE sr.user_id = user_uuid
    AND sr.reading_date >= start_date
    AND sr.reading_date <= end_date;
END;
$$ LANGUAGE plpgsql;

-- Create triggers to update updated_at timestamp
CREATE TRIGGER update_steps_readings_updated_at 
    BEFORE UPDATE ON steps_readings 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_steps_goals_updated_at 
    BEFORE UPDATE ON steps_goals 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Grant necessary permissions
GRANT ALL ON steps_readings TO authenticated;
GRANT ALL ON steps_goals TO authenticated;
GRANT ALL ON steps_readings TO anon;
GRANT ALL ON steps_goals TO anon;

-- Success message
SELECT 'Steps tables created successfully!' as status; 