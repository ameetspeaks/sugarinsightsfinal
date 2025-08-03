const express = require('express');
const { verifyToken, requirePermission } = require('../middleware/auth');
const { supabase } = require('../config/database');

const router = express.Router();

// Get all medications with filters
router.get('/', verifyToken, requirePermission('medications:read'), async (req, res) => {
  try {
    console.log('Medications route called');
    const {
      page = 1,
      limit = 20,
      user_id = '',
      status = '',
      search = ''
    } = req.query;

    console.log('Query params:', { page, limit, user_id, status, search });

    const offset = (page - 1) * limit;

    // Build query
    let query = supabase
      .from('medications')
      .select('*', { count: 'exact' });

    console.log('Building Supabase query...');

    // Add filters
    if (user_id) {
      query = query.eq('user_id', user_id);
    }

    if (status) {
      query = query.eq('status', status);
    }

    if (search) {
      query = query.or(`name.ilike.%${search}%,dosage.ilike.%${search}%`);
    }

    // Add pagination
    query = query.range(offset, offset + limit - 1);

    console.log('Executing query...');
    const { data: medications, error, count } = await query;

    console.log('Query result:', { 
      medicationsCount: medications?.length || 0, 
      error: error?.message, 
      count 
    });

    if (error) {
      console.error('Supabase error:', error);
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    res.json({
      medications,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: count,
        totalPages: Math.ceil(count / limit)
      }
    });

  } catch (error) {
    console.error('Get medications error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
});

// Get medication analytics
router.get('/analytics/overview', verifyToken, requirePermission('medications:read'), async (req, res) => {
  try {
    const { start_date, end_date } = req.query;

    // Get medication statistics
    const analytics = {
      total_medications: 0,
      active_medications: 0,
      adherence_rate: 0,
      most_prescribed: [],
      recent_activity: []
    };

    // Count total medications
    const { count: totalCount } = await supabase
      .from('medications')
      .select('*', { count: 'exact', head: true });

    analytics.total_medications = totalCount || 0;

    // Count active medications
    const { count: activeCount } = await supabase
      .from('medications')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'active');

    analytics.active_medications = activeCount || 0;

    // Calculate adherence rate
    const { data: historyData } = await supabase
      .from('medication_history')
      .select('status')
      .in('status', ['taken', 'skipped']);

    if (historyData && historyData.length > 0) {
      const takenCount = historyData.filter(h => h.status === 'taken').length;
      analytics.adherence_rate = Math.round((takenCount / historyData.length) * 100);
    }

    // Get most prescribed medications
    const { data: prescribedData } = await supabase
      .from('medications')
      .select('name, count')
      .select('name')
      .limit(10);

    if (prescribedData) {
      const nameCounts = {};
      prescribedData.forEach(med => {
        nameCounts[med.name] = (nameCounts[med.name] || 0) + 1;
      });

      analytics.most_prescribed = Object.entries(nameCounts)
        .map(([name, count]) => ({ name, count }))
        .sort((a, b) => b.count - a.count)
        .slice(0, 5);
    }

    res.json({ analytics });

  } catch (error) {
    console.error('Get medication analytics error:', error);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
});

// Get specific medication
router.get('/:medicationId', verifyToken, requirePermission('medications:read'), async (req, res) => {
  try {
    const { medicationId } = req.params;
    console.log('Getting medication with ID:', medicationId);

    // Try a simpler query without the join first
    const { data: medication, error } = await supabase
      .from('medications')
      .select('*')
      .eq('id', medicationId)
      .single();

    console.log('Simple query result:', { medication, error });

    if (error || !medication) {
      console.log('Medication not found or error:', error);
      return res.status(404).json({
        error: 'Medication not found'
      });
    }

    res.json({ medication });

  } catch (error) {
    console.error('Get medication error:', error);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
});

// Create medication
router.post('/', verifyToken, requirePermission('medications:write'), async (req, res) => {
  try {
    const medicationData = req.body;

    const { data: medication, error } = await supabase
      .from('medications')
      .insert({
        ...medicationData,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    res.status(201).json({
      message: 'Medication created successfully',
      medication
    });

  } catch (error) {
    console.error('Create medication error:', error);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
});

// Update medication
router.put('/:medicationId', verifyToken, requirePermission('medications:write'), async (req, res) => {
  try {
    const { medicationId } = req.params;
    const updateData = req.body;

    const { data: medication, error } = await supabase
      .from('medications')
      .update({
        ...updateData,
        updated_at: new Date().toISOString()
      })
      .eq('id', medicationId)
      .select()
      .single();

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    res.json({
      message: 'Medication updated successfully',
      medication
    });

  } catch (error) {
    console.error('Update medication error:', error);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
});

// Delete medication
router.delete('/:medicationId', verifyToken, requirePermission('medications:delete'), async (req, res) => {
  try {
    const { medicationId } = req.params;

    const { error } = await supabase
      .from('medications')
      .delete()
      .eq('id', medicationId);

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    res.json({
      message: 'Medication deleted successfully'
    });

  } catch (error) {
    console.error('Delete medication error:', error);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
});

// Get medication history
router.get('/:medicationId/history', verifyToken, requirePermission('medications:read'), async (req, res) => {
  try {
    const { medicationId } = req.params;
    const { page = 1, limit = 50 } = req.query;
    const offset = (page - 1) * limit;

    const { data: history, error, count } = await supabase
      .from('medication_history')
      .select('*')
      .eq('medication_id', medicationId)
      .order('scheduled_for', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      return res.status(500).json({
        error: 'Database error',
        message: error.message
      });
    }

    res.json({
      history,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: count,
        totalPages: Math.ceil(count / limit)
      }
    });

  } catch (error) {
    console.error('Get medication history error:', error);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
});

module.exports = router; 