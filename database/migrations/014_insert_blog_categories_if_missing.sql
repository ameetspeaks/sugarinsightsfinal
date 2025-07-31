-- Insert blog categories only if they don't already exist
-- This migration handles the case where categories might already be present

-- Insert default blog categories if they don't exist
INSERT INTO education_categories (name, description, icon_name, image_path, is_active, sort_order, created_at, updated_at)
SELECT 
    'Medical Nutrition Therapy',
    'Learn about proper nutrition for diabetes management',
    'assets/icons/blog_category/1.png',
    NULL,
    true,
    1,
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM education_categories WHERE name = 'Medical Nutrition Therapy'
);

INSERT INTO education_categories (name, description, icon_name, image_path, is_active, sort_order, created_at, updated_at)
SELECT 
    'Physical Activity & Exercise',
    'Exercise routines and physical activities for diabetes patients',
    'assets/icons/blog_category/2.png',
    NULL,
    true,
    2,
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM education_categories WHERE name = 'Physical Activity & Exercise'
);

INSERT INTO education_categories (name, description, icon_name, image_path, is_active, sort_order, created_at, updated_at)
SELECT 
    'Yoga & Diabetes',
    'Yoga practices and meditation techniques for diabetes management',
    'assets/icons/blog_category/3.png',
    NULL,
    true,
    3,
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM education_categories WHERE name = 'Yoga & Diabetes'
);

INSERT INTO education_categories (name, description, icon_name, image_path, is_active, sort_order, created_at, updated_at)
SELECT 
    'Insulin Management Education',
    'Understanding insulin types, administration, and management',
    'assets/icons/blog_category/4.png',
    NULL,
    true,
    4,
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM education_categories WHERE name = 'Insulin Management Education'
);

INSERT INTO education_categories (name, description, icon_name, image_path, is_active, sort_order, created_at, updated_at)
SELECT 
    'Weight Management',
    'Strategies for maintaining healthy weight with diabetes',
    'assets/icons/blog_category/5.png',
    NULL,
    true,
    5,
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM education_categories WHERE name = 'Weight Management'
);

INSERT INTO education_categories (name, description, icon_name, image_path, is_active, sort_order, created_at, updated_at)
SELECT 
    'Good Sleep Habits',
    'Importance of sleep and healthy sleep practices for diabetes',
    'assets/icons/blog_category/6.png',
    NULL,
    true,
    6,
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM education_categories WHERE name = 'Good Sleep Habits'
);

INSERT INTO education_categories (name, description, icon_name, image_path, is_active, sort_order, created_at, updated_at)
SELECT 
    'Diabetes Complications',
    'Understanding and preventing diabetes-related complications',
    'assets/icons/blog_category/7.png',
    NULL,
    true,
    7,
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM education_categories WHERE name = 'Diabetes Complications'
);

INSERT INTO education_categories (name, description, icon_name, image_path, is_active, sort_order, created_at, updated_at)
SELECT 
    'Psychosocial Care',
    'Mental health and emotional well-being for diabetes patients',
    'assets/icons/blog_category/8.png',
    NULL,
    true,
    8,
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM education_categories WHERE name = 'Psychosocial Care'
);

INSERT INTO education_categories (name, description, icon_name, image_path, is_active, sort_order, created_at, updated_at)
SELECT 
    'Intermittent Fasting',
    'Fasting protocols and their effects on diabetes management',
    'assets/icons/blog_category/9.png',
    NULL,
    true,
    9,
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM education_categories WHERE name = 'Intermittent Fasting'
);

INSERT INTO education_categories (name, description, icon_name, image_path, is_active, sort_order, created_at, updated_at)
SELECT 
    'Blood Pressure Management',
    'Managing blood pressure alongside diabetes care',
    'assets/icons/blog_category/10.png',
    NULL,
    true,
    10,
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM education_categories WHERE name = 'Blood Pressure Management'
); 