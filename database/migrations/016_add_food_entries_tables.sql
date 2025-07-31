-- Add food entries tables and related functionality
-- This migration creates the food tracking system

-- Create food_entries table
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'food_entries') THEN
        CREATE TABLE food_entries (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            name VARCHAR(255) NOT NULL,
            description TEXT,
            timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
            image_url TEXT,
            calories INTEGER NOT NULL,
            carbs DECIMAL(5,2) NOT NULL,
            protein DECIMAL(5,2) NOT NULL,
            fat DECIMAL(5,2) NOT NULL,
            meal_type VARCHAR(50) NOT NULL CHECK (meal_type IN ('Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert')),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        -- Add indexes for food_entries
        CREATE INDEX idx_food_entries_user ON food_entries(user_id);
        CREATE INDEX idx_food_entries_timestamp ON food_entries(timestamp);
        CREATE INDEX idx_food_entries_meal_type ON food_entries(meal_type);
        
        -- Enable RLS
        ALTER TABLE food_entries ENABLE ROW LEVEL SECURITY;
        
        -- Food entries policies
        CREATE POLICY "Users can view their own food entries" ON food_entries
            FOR SELECT USING (
                auth.uid() = user_id
            );

        CREATE POLICY "Users can create their own food entries" ON food_entries
            FOR INSERT WITH CHECK (
                auth.uid() = user_id
            );

        CREATE POLICY "Users can update their own food entries" ON food_entries
            FOR UPDATE USING (
                auth.uid() = user_id
            );

        CREATE POLICY "Users can delete their own food entries" ON food_entries
            FOR DELETE USING (
                auth.uid() = user_id
            );
            
        -- Add trigger for food_entries
        CREATE TRIGGER update_food_entries_updated_at
            BEFORE UPDATE ON food_entries
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- Create meal_types enum table for reference
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'meal_types') THEN
        CREATE TABLE meal_types (
            id SERIAL PRIMARY KEY,
            name VARCHAR(50) UNIQUE NOT NULL,
            description TEXT,
            sort_order INTEGER DEFAULT 0,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        -- Insert default meal types
        INSERT INTO meal_types (name, description, sort_order) VALUES
            ('Breakfast', 'Morning meal', 1),
            ('Lunch', 'Midday meal', 2),
            ('Dinner', 'Evening meal', 3),
            ('Snack', 'Light meal between main meals', 4),
            ('Dessert', 'Sweet treat after meals', 5)
        ON CONFLICT (name) DO NOTHING;
    END IF;
END $$;

-- Create food_categories table for organizing food items
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'food_categories') THEN
        CREATE TABLE food_categories (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            name VARCHAR(255) NOT NULL,
            description TEXT,
            icon_name VARCHAR(255),
            color VARCHAR(7), -- Hex color code
            is_active BOOLEAN DEFAULT true,
            sort_order INTEGER DEFAULT 0,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        -- Add indexes for food_categories
        CREATE INDEX idx_food_categories_active ON food_categories(is_active) WHERE is_active = true;
        CREATE INDEX idx_food_categories_sort ON food_categories(sort_order);
        
        -- Insert default food categories
        INSERT INTO food_categories (name, description, icon_name, color, sort_order) VALUES
            ('Grains & Cereals', 'Rice, wheat, oats, bread, pasta', 'assets/icons/food/grains.png', '#FFD700', 1),
            ('Vegetables', 'Fresh and cooked vegetables', 'assets/icons/food/vegetables.png', '#90EE90', 2),
            ('Fruits', 'Fresh fruits and dried fruits', 'assets/icons/food/fruits.png', '#FF6347', 3),
            ('Dairy & Eggs', 'Milk, cheese, yogurt, eggs', 'assets/icons/food/dairy.png', '#F0F8FF', 4),
            ('Meat & Fish', 'Chicken, fish, red meat', 'assets/icons/food/meat.png', '#CD5C5C', 5),
            ('Nuts & Seeds', 'Almonds, walnuts, seeds', 'assets/icons/food/nuts.png', '#D2691E', 6),
            ('Beverages', 'Tea, coffee, juices, water', 'assets/icons/food/beverages.png', '#87CEEB', 7),
            ('Sweets & Desserts', 'Cakes, cookies, ice cream', 'assets/icons/food/sweets.png', '#FF69B4', 8)
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- Create food_items table for common food database
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'food_items') THEN
        CREATE TABLE food_items (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            name VARCHAR(255) NOT NULL,
            description TEXT,
            category_id UUID REFERENCES food_categories(id),
            calories_per_100g INTEGER NOT NULL,
            carbs_per_100g DECIMAL(5,2) NOT NULL,
            protein_per_100g DECIMAL(5,2) NOT NULL,
            fat_per_100g DECIMAL(5,2) NOT NULL,
            fiber_per_100g DECIMAL(5,2) DEFAULT 0,
            sugar_per_100g DECIMAL(5,2) DEFAULT 0,
            sodium_per_100g DECIMAL(5,2) DEFAULT 0,
            is_verified BOOLEAN DEFAULT false,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        -- Add indexes for food_items
        CREATE INDEX idx_food_items_name ON food_items(name);
        CREATE INDEX idx_food_items_category ON food_items(category_id);
        CREATE INDEX idx_food_items_active ON food_items(is_active) WHERE is_active = true;
        
        -- Insert some common Indian food items
        INSERT INTO food_items (name, description, calories_per_100g, carbs_per_100g, protein_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g) VALUES
            ('Aloo Paratha', 'Potato stuffed flatbread', 300, 45, 8, 12, 3, 1),
            ('Milk Tea', 'Tea with milk and sugar', 80, 15, 2, 3, 0, 12),
            ('Dahi (Curd)', 'Plain yogurt', 60, 8, 6, 2, 0, 4),
            ('Gulab Jamun', 'Sweet dessert ball', 150, 25, 2, 5, 0, 20),
            ('Roti', 'Whole wheat flatbread', 120, 20, 4, 2, 3, 0),
            ('Dal', 'Lentil curry', 100, 18, 6, 2, 5, 1),
            ('Rice', 'Steamed white rice', 130, 28, 2, 0, 1, 0),
            ('Chicken Curry', 'Spiced chicken dish', 200, 8, 25, 10, 2, 2),
            ('Paneer', 'Indian cottage cheese', 265, 4, 18, 20, 0, 1),
            ('Lassi', 'Sweet yogurt drink', 120, 20, 4, 3, 0, 18)
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- Create functions for food analytics
DO $func$ 
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.routines WHERE routine_name = 'get_daily_nutrition_summary') THEN
        CREATE OR REPLACE FUNCTION get_daily_nutrition_summary(
            p_user_id UUID,
            p_date DATE
        ) RETURNS TABLE (
            total_calories BIGINT,
            total_carbs DECIMAL(10,2),
            total_protein DECIMAL(10,2),
            total_fat DECIMAL(10,2),
            meal_count BIGINT
        ) AS $function$
        BEGIN
            RETURN QUERY
            SELECT 
                COALESCE(SUM(fe.calories), 0) as total_calories,
                COALESCE(SUM(fe.carbs), 0) as total_carbs,
                COALESCE(SUM(fe.protein), 0) as total_protein,
                COALESCE(SUM(fe.fat), 0) as total_fat,
                COUNT(*) as meal_count
            FROM food_entries fe
            WHERE fe.user_id = p_user_id 
            AND DATE(fe.timestamp) = p_date;
        END;
        $function$ LANGUAGE plpgsql SECURITY DEFINER;
    END IF;
END $func$;

-- Create function to get nutrition by meal type
DO $func$ 
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.routines WHERE routine_name = 'get_nutrition_by_meal_type') THEN
        CREATE OR REPLACE FUNCTION get_nutrition_by_meal_type(
            p_user_id UUID,
            p_start_date DATE,
            p_end_date DATE
        ) RETURNS TABLE (
            meal_type VARCHAR(50),
            total_calories BIGINT,
            total_carbs DECIMAL(10,2),
            total_protein DECIMAL(10,2),
            total_fat DECIMAL(10,2),
            entry_count BIGINT
        ) AS $function$
        BEGIN
            RETURN QUERY
            SELECT 
                fe.meal_type,
                COALESCE(SUM(fe.calories), 0) as total_calories,
                COALESCE(SUM(fe.carbs), 0) as total_carbs,
                COALESCE(SUM(fe.protein), 0) as total_protein,
                COALESCE(SUM(fe.fat), 0) as total_fat,
                COUNT(*) as entry_count
            FROM food_entries fe
            WHERE fe.user_id = p_user_id 
            AND DATE(fe.timestamp) BETWEEN p_start_date AND p_end_date
            GROUP BY fe.meal_type
            ORDER BY fe.meal_type;
        END;
        $function$ LANGUAGE plpgsql SECURITY DEFINER;
    END IF;
END $func$; 