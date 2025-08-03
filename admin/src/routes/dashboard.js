const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { supabase } = require('../config/database');

// Get dashboard statistics
router.get('/', authenticateToken, async (req, res) => {
    try {
        // Get total users
        const { count: totalUsers } = await supabase
            .from('user_profiles')
            .select('*', { count: 'exact', head: true });

        // Get active medications
        const { count: activeMedications } = await supabase
            .from('medications')
            .select('*', { count: 'exact', head: true })
            .eq('status', 'active');

        // Get total articles
        const { count: totalArticles } = await supabase
            .from('articles')
            .select('*', { count: 'exact', head: true });

        // Get recent users (last 5)
        const { data: recentUsers } = await supabase
            .from('user_profiles')
            .select('id, name, email, created_at')
            .order('created_at', { ascending: false })
            .limit(5);

        // Mock data for now
        const dashboardData = {
            totalUsers: totalUsers || 0,
            activeMedications: activeMedications || 0,
            totalArticles: totalArticles || 0,
            totalLogins: 1250, // Mock data
            recentUsers: recentUsers || []
        };

        res.json(dashboardData);
    } catch (error) {
        console.error('Dashboard error:', error);
        res.status(500).json({ 
            error: 'Internal server error',
            message: 'Failed to load dashboard data'
        });
    }
});

module.exports = router; 