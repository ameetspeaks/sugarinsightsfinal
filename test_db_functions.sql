-- Test script to verify database functions and constraints

-- Check if the unique constraint exists
SELECT 
    constraint_name,
    table_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'medication_history' 
AND constraint_type = 'UNIQUE';

-- Check if the function exists
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name = 'log_medication_taken';

-- Test the function with dummy data
SELECT log_medication_taken(
    '00000000-0000-0000-0000-000000000000'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    NOW(),
    NOW(),
    'Test call'
); 