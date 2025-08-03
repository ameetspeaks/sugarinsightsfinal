const express = require('express');
const { verifyToken, requirePermission } = require('../middleware/auth');
const { supabase } = require('../config/database');

const router = express.Router();

// Cache for users data
const usersCache = new Map();
const USERS_CACHE_DURATION = 5 * 60 * 1000; // 5 minutes

// Create new user
router.post('/', verifyToken, requirePermission('users:write'), async (req, res) => {
  try {
    const userData = req.body;
    
    // Validate required fields
    if (!userData.name || !userData.email) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Name and email are required'
      });
    }

    // Check if user already exists
    const { data: existingUser } = await supabase
      .from('user_profiles')
      .select('user_id')
      .eq('email', userData.email)
      .single();

    if (existingUser) {
      return res.status(409).json({
        error: 'User already exists',
        message: 'A user with this email already exists'
      });
    }

    // Create new user
    const newUser = {
      user_id: `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      name: userData.name,
      email: userData.email,
      phone: userData.phone || null,
      diabetes_type: userData.diabetes_type || null,
      status: userData.status || 'active',
      onboarding_completed: false,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    const { data: user, error } = await supabase
      .from('user_profiles')
      .insert(newUser)
      .select()
      .single();

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    res.status(201).json({
      message: 'User created successfully',
      user
    });

  } catch (error) {
    console.error('Create user error:', error);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
});

// Get all users with pagination and filters (optimized)
router.get('/', verifyToken, requirePermission('users:read'), async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      search = '',
      status = '',
      diabetes_type = '',
      onboarding_completed = '',
      sort_by = 'created_at',
      sort_order = 'desc'
    } = req.query;

    // Check cache for simple queries
    const cacheKey = `users_${page}_${limit}_${search}_${status}_${diabetes_type}_${onboarding_completed}_${sort_by}_${sort_order}`;
    const cachedData = usersCache.get(cacheKey);
    
    if (cachedData && (Date.now() - cachedData.timestamp) < USERS_CACHE_DURATION) {
      console.log('Returning cached users data');
      return res.json(cachedData.data);
    }

    const offset = (page - 1) * limit;

    // Build query with optimized select
    let query = supabase
      .from('user_profiles')
      .select('id, name, email, phone, diabetes_type, diabetes_status, status, onboarding_completed, created_at, updated_at', { count: 'exact' });

    // Add filters
    if (search) {
      query = query.or(`name.ilike.%${search}%,email.ilike.%${search}%`);
    }

    if (status) {
      query = query.eq('status', status);
    }

    if (diabetes_type) {
      query = query.eq('diabetes_type', diabetes_type);
    }

    if (onboarding_completed !== '') {
      query = query.eq('onboarding_completed', onboarding_completed === 'true');
    }

    // Add sorting
    query = query.order(sort_by, { ascending: sort_order === 'asc' });

    // Add pagination
    query = query.range(offset, offset + limit - 1);

    const { data: users, error, count } = await query;

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    const response = {
      users: users || [],
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit)
      }
    };

    // Cache the response
    usersCache.set(cacheKey, {
      data: response,
      timestamp: Date.now()
    });

    res.json(response);

  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to fetch users'
    });
  }
});

// Get specific user by ID with detailed information
router.get('/:userId', verifyToken, requirePermission('users:read'), async (req, res) => {
  try {
    const { userId } = req.params;

    const { data: user, error } = await supabase
      .from('user_profiles')
      .select('*')
      .eq('user_id', userId)
      .single();

    if (error || !user) {
      return res.status(404).json({
        error: 'User not found'
      });
    }

    // Get user's health data summary
    const { count: glucoseCount } = await supabase
      .from('glucose_readings')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId);

    const { count: bpCount } = await supabase
      .from('blood_pressure_readings')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId);

    const { count: medCount } = await supabase
      .from('medications')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId);

    const { count: stepsCount } = await supabase
      .from('steps_data')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId);

    const { data: recentReadings } = await supabase
      .from('glucose_readings')
      .select('glucose_value, reading_type, created_at')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(5);

    const { data: recentMedications } = await supabase
      .from('medications')
      .select('name, dosage, frequency, created_at')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(5);

    res.json({
      user: {
        ...user,
        health_summary: {
          glucose_readings: glucoseCount || 0,
          blood_pressure_readings: bpCount || 0,
          medications: medCount || 0,
          steps_entries: stepsCount || 0,
          recent_readings: recentReadings || [],
          recent_medications: recentMedications || []
        }
      }
    });

  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
});

// Update user profile
router.put('/:userId', verifyToken, requirePermission('users:write'), async (req, res) => {
  try {
    const { userId } = req.params;
    const updateData = req.body;

    // Remove sensitive fields that shouldn't be updated via admin
    delete updateData.password;
    delete updateData.password_hash;

    const { data: user, error } = await supabase
      .from('user_profiles')
      .update({
        ...updateData,
        updated_at: new Date().toISOString()
      })
      .eq('user_id', userId)
      .select()
      .single();

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    res.json({
      message: 'User updated successfully',
      user
    });

  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
});

// Delete user (soft delete)
router.delete('/:userId', verifyToken, requirePermission('users:delete'), async (req, res) => {
  try {
    const { userId } = req.params;

    const { error } = await supabase
      .from('user_profiles')
      .update({
        status: 'deleted',
        deleted_at: new Date().toISOString()
      })
      .eq('user_id', userId);

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    res.json({
      message: 'User deleted successfully'
    });

  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
});

// Get user analytics
router.get('/:userId/analytics', verifyToken, requirePermission('users:read'), async (req, res) => {
  try {
    const { userId } = req.params;
    const { start_date, end_date } = req.query;

    // Get user's health data analytics
    const analytics = {
      glucose_readings: 0,
      blood_pressure_readings: 0,
      medications: 0,
      steps_entries: 0,
      last_activity: null
    };

    // Count glucose readings
    const { count: glucoseCount } = await supabase
      .from('glucose_readings')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId);

    analytics.glucose_readings = glucoseCount || 0;

    // Count blood pressure readings
    const { count: bpCount } = await supabase
      .from('blood_pressure_readings')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId);

    analytics.blood_pressure_readings = bpCount || 0;

    // Count medications
    const { count: medCount } = await supabase
      .from('medications')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId);

    analytics.medications = medCount || 0;

    // Count steps entries
    const { count: stepsCount } = await supabase
      .from('steps_data')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId);

    analytics.steps_entries = stepsCount || 0;

    res.json({ analytics });

  } catch (error) {
    console.error('Get user analytics error:', error);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
});

// Get user activity log
router.get('/:userId/activity', verifyToken, requirePermission('users:read'), async (req, res) => {
  try {
    const { userId } = req.params;
    const { page = 1, limit = 50 } = req.query;
    const offset = (page - 1) * limit;

    // Get user's recent activity from various tables
    const activities = [];

    // Get recent glucose readings
    const { data: glucoseReadings } = await supabase
      .from('glucose_readings')
      .select('created_at, glucose_value, reading_type')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(10);

    if (glucoseReadings) {
      glucoseReadings.forEach(reading => {
        activities.push({
          type: 'glucose_reading',
          timestamp: reading.created_at,
          details: `Glucose: ${reading.glucose_value} mg/dL (${reading.reading_type})`
        });
      });
    }

    // Get recent medication logs
    const { data: medicationLogs } = await supabase
      .from('medication_history')
      .select('created_at, status, notes')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(10);

    if (medicationLogs) {
      medicationLogs.forEach(log => {
        activities.push({
          type: 'medication_log',
          timestamp: log.created_at,
          details: `Medication ${log.status}: ${log.notes || 'No notes'}`
        });
      });
    }

    // Sort activities by timestamp
    activities.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

    // Apply pagination
    const paginatedActivities = activities.slice(offset, offset + limit);

    res.json({
      activities: paginatedActivities,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: activities.length,
        totalPages: Math.ceil(activities.length / limit)
      }
    });

  } catch (error) {
    console.error('Get user activity error:', error);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
});

module.exports = router; 