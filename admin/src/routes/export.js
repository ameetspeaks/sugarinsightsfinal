const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { createClient } = require('@supabase/supabase-js');

// Supabase client
const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY
);

// General export endpoint - returns available export options
router.get('/', authenticateToken, async (req, res) => {
    try {
        const exportOptions = {
            availableExports: [
                {
                    type: 'users',
                    name: 'User Profiles',
                    description: 'Complete user profiles with diabetes information and settings',
                    formats: ['json', 'csv'],
                    endpoint: '/api/export/users'
                },
                {
                    type: 'user-activity',
                    name: 'User Activity',
                    description: 'User engagement and activity data over the last 30 days',
                    formats: ['json', 'csv'],
                    endpoint: '/api/export/user-activity'
                },
                {
                    type: 'medications',
                    name: 'Medications',
                    description: 'Medication prescriptions, schedules, and adherence tracking',
                    formats: ['json', 'csv'],
                    endpoint: '/api/export/medications'
                },
                {
                    type: 'medication-history',
                    name: 'Medication History',
                    description: 'Detailed medication adherence history and tracking data',
                    formats: ['json', 'csv'],
                    endpoint: '/api/export/medication-history'
                },
                {
                    type: 'health',
                    name: 'Health Data',
                    description: 'Glucose readings, blood pressure, and steps data',
                    formats: ['json', 'csv'],
                    endpoint: '/api/export/health'
                },
                {
                    type: 'blog',
                    name: 'Blog Articles',
                    description: 'Educational articles and blog posts with categories',
                    formats: ['json', 'csv'],
                    endpoint: '/api/export/blog'
                },
                {
                    type: 'videos',
                    name: 'Videos',
                    description: 'Educational videos with categories and metadata',
                    formats: ['json', 'csv'],
                    endpoint: '/api/export/videos'
                },
                {
                    type: 'analytics',
                    name: 'Analytics Summary',
                    description: 'Comprehensive analytics data and reports',
                    formats: ['json', 'csv'],
                    endpoint: '/api/export/analytics'
                }
            ],
            metadata: {
                lastUpdated: new Date().toISOString(),
                totalExportTypes: 8,
                supportedFormats: ['json', 'csv'],
                description: 'Sugar Insights Data Export API'
            }
        };

        res.json(exportOptions);
    } catch (error) {
        console.error('Export options error:', error);
        res.status(500).json({
            error: 'Internal server error',
            message: 'Failed to get export options'
        });
    }
});

// Export users data with enhanced information
router.get('/users', authenticateToken, async (req, res) => {
    try {
        const { format = 'json' } = req.query;
        
        const { data: users, error } = await supabase
            .from('user_profiles')
            .select('*');

        if (error) {
            return res.status(500).json({
                error: 'Database error',
                message: error.message
            });
        }

        // Enhance user data with activity summary
        const enhancedUsers = users?.map(user => ({
            ...user,
            activity_summary: {
                glucose_readings_count: 0, // Will be calculated if needed
                blood_pressure_readings_count: 0,
                steps_entries_count: 0,
                medications_count: 0
            }
        })) || [];

        if (format === 'csv') {
            const csv = convertUsersToCSV(enhancedUsers);
            res.setHeader('Content-Type', 'text/csv');
            res.setHeader('Content-Disposition', 'attachment; filename=users_export.csv');
            res.send(csv);
        } else {
            res.json(enhancedUsers);
        }
    } catch (error) {
        console.error('Export users error:', error);
        res.status(500).json({
            error: 'Internal server error',
            message: 'Failed to export users data'
        });
    }
});

// Export medications data with enhanced information
router.get('/medications', authenticateToken, async (req, res) => {
    try {
        const { format = 'json' } = req.query;
        
        const { data: medications, error } = await supabase
            .from('medications')
            .select(`
                *,
                user_profiles(name, email, diabetes_type, diabetes_status),
                medication_history(count)
            `);

        if (error) {
            return res.status(500).json({
                error: 'Database error',
                message: error.message
            });
        }

        // Enhance medication data with history summary
        const enhancedMedications = medications?.map(med => ({
            ...med,
            history_count: med.medication_history?.[0]?.count || 0,
            user_info: med.user_profiles ? {
                name: med.user_profiles.name,
                email: med.user_profiles.email,
                diabetes_type: med.user_profiles.diabetes_type,
                diabetes_status: med.user_profiles.diabetes_status
            } : null
        })) || [];

        if (format === 'csv') {
            const csv = convertMedicationsToCSV(enhancedMedications);
            res.setHeader('Content-Type', 'text/csv');
            res.setHeader('Content-Disposition', 'attachment; filename=medications_export.csv');
            res.send(csv);
        } else {
            res.json(enhancedMedications);
        }
    } catch (error) {
        console.error('Export medications error:', error);
        res.status(500).json({
            error: 'Internal server error',
            message: 'Failed to export medications data'
        });
    }
});

// Export medication history data
router.get('/medication-history', authenticateToken, async (req, res) => {
    try {
        const { format = 'json' } = req.query;
        
        const { data: history, error } = await supabase
            .from('medication_history')
            .select(`
                *,
                medications(name, dosage, frequency),
                user_profiles(name, email)
            `);

        if (error) {
            return res.status(500).json({
                error: 'Database error',
                message: error.message
            });
        }

        if (format === 'csv') {
            const csv = convertMedicationHistoryToCSV(history);
            res.setHeader('Content-Type', 'text/csv');
            res.setHeader('Content-Disposition', 'attachment; filename=medication_history_export.csv');
            res.send(csv);
        } else {
            res.json(history);
        }
    } catch (error) {
        console.error('Export medication history error:', error);
        res.status(500).json({
            error: 'Internal server error',
            message: 'Failed to export medication history data'
        });
    }
});

// Export blog data with enhanced information
router.get('/blog', authenticateToken, async (req, res) => {
    try {
        const { format = 'json' } = req.query;
        
        const { data: articles, error } = await supabase
            .from('articles')
            .select(`
                *,
                blog_categories(name, description)
            `);

        if (error) {
            return res.status(500).json({
                error: 'Database error',
                message: error.message
            });
        }

        if (format === 'csv') {
            const csv = convertArticlesToCSV(articles);
            res.setHeader('Content-Type', 'text/csv');
            res.setHeader('Content-Disposition', 'attachment; filename=blog_articles_export.csv');
            res.send(csv);
        } else {
            res.json(articles);
        }
    } catch (error) {
        console.error('Export blog error:', error);
        res.status(500).json({
            error: 'Internal server error',
            message: 'Failed to export blog data'
        });
    }
});

// Export videos data with enhanced information
router.get('/videos', authenticateToken, async (req, res) => {
    try {
        const { format = 'json' } = req.query;
        
        const { data: videos, error } = await supabase
            .from('videos')
            .select(`
                *,
                education_categories(name, description)
            `);

        if (error) {
            return res.status(500).json({
                error: 'Database error',
                message: error.message
            });
        }

        if (format === 'csv') {
            const csv = convertVideosToCSV(videos);
            res.setHeader('Content-Type', 'text/csv');
            res.setHeader('Content-Disposition', 'attachment; filename=videos_export.csv');
            res.send(csv);
        } else {
            res.json(videos);
        }
    } catch (error) {
        console.error('Export videos error:', error);
        res.status(500).json({
            error: 'Internal server error',
            message: 'Failed to export videos data'
        });
    }
});

// Export health data with enhanced filtering
router.get('/health', authenticateToken, async (req, res) => {
    try {
        const { format = 'json', type = 'all', date_from, date_to } = req.query;
        
        let data = {};
        const dateFilter = {};
        
        if (date_from) dateFilter.gte = date_from;
        if (date_to) dateFilter.lte = date_to;
        
        if (type === 'all' || type === 'glucose') {
            const { data: glucoseReadings, error: glucoseError } = await supabase
                .from('glucose_readings')
                .select(`
                    *,
                    user_profiles(name, email, diabetes_type)
                `)
                .match(dateFilter);
            
            if (glucoseError) throw glucoseError;
            data.glucoseReadings = glucoseReadings;
        }
        
        if (type === 'all' || type === 'blood_pressure') {
            const { data: bpReadings, error: bpError } = await supabase
                .from('blood_pressure_readings')
                .select(`
                    *,
                    user_profiles(name, email, diabetes_type)
                `)
                .match(dateFilter);
            
            if (bpError) throw bpError;
            data.bloodPressureReadings = bpReadings;
        }
        
        if (type === 'all' || type === 'steps') {
            const { data: stepsEntries, error: stepsError } = await supabase
                .from('steps_entries')
                .select(`
                    *,
                    user_profiles(name, email, diabetes_type)
                `)
                .match(dateFilter);
            
            if (stepsError) throw stepsError;
            data.stepsEntries = stepsEntries;
        }

        if (format === 'csv') {
            const csv = convertHealthDataToCSV(data, type);
            res.setHeader('Content-Type', 'text/csv');
            res.setHeader('Content-Disposition', `attachment; filename=health_data_${type}_export.csv`);
            res.send(csv);
        } else {
            res.json(data);
        }
    } catch (error) {
        console.error('Export health data error:', error);
        res.status(500).json({
            error: 'Internal server error',
            message: 'Failed to export health data'
        });
    }
});

// Export analytics summary with comprehensive data
router.get('/analytics', authenticateToken, async (req, res) => {
    try {
        const { format = 'json' } = req.query;
        
        // Get comprehensive analytics data
        const userStats = await getUserStats();
        const medicationStats = await getMedicationStats();
        const contentStats = await getContentStats();
        const healthStats = await getHealthStats();
        const engagementStats = await getEngagementStats();

        const analyticsData = {
            userStats,
            medicationStats,
            contentStats,
            healthStats,
            engagementStats,
            exportDate: new Date().toISOString(),
            exportMetadata: {
                generatedBy: 'Sugar Insights Admin API',
                version: '1.0.0',
                dataSource: 'Supabase Database'
            }
        };

        if (format === 'csv') {
            const csv = convertAnalyticsToCSV(analyticsData);
            res.setHeader('Content-Type', 'text/csv');
            res.setHeader('Content-Disposition', 'attachment; filename=analytics_summary_export.csv');
            res.send(csv);
        } else {
            res.json(analyticsData);
        }
    } catch (error) {
        console.error('Export analytics error:', error);
        res.status(500).json({
            error: 'Internal server error',
            message: 'Failed to export analytics data'
        });
    }
});

// Export user activity summary
router.get('/user-activity', authenticateToken, async (req, res) => {
    try {
        const { format = 'json', days = '30' } = req.query;
        
        const daysAgo = new Date();
        daysAgo.setDate(daysAgo.getDate() - parseInt(days));
        
        // Get user activity data
        const [glucoseActivity, bpActivity, stepsActivity, medicationActivity] = await Promise.all([
            supabase
                .from('glucose_readings')
                .select('user_id, created_at')
                .gte('created_at', daysAgo.toISOString()),
            supabase
                .from('blood_pressure_readings')
                .select('user_id, created_at')
                .gte('created_at', daysAgo.toISOString()),
            supabase
                .from('steps_entries')
                .select('user_id, created_at')
                .gte('created_at', daysAgo.toISOString()),
            supabase
                .from('medication_history')
                .select('user_id, created_at')
                .gte('created_at', daysAgo.toISOString())
        ]);

        // Process activity data
        const userActivity = {};
        
        // Process glucose activity
        glucoseActivity.data?.forEach(reading => {
            if (!userActivity[reading.user_id]) {
                userActivity[reading.user_id] = { glucose_readings: 0, bp_readings: 0, steps_entries: 0, medication_entries: 0 };
            }
            userActivity[reading.user_id].glucose_readings++;
        });

        // Process blood pressure activity
        bpActivity.data?.forEach(reading => {
            if (!userActivity[reading.user_id]) {
                userActivity[reading.user_id] = { glucose_readings: 0, bp_readings: 0, steps_entries: 0, medication_entries: 0 };
            }
            userActivity[reading.user_id].bp_readings++;
        });

        // Process steps activity
        stepsActivity.data?.forEach(entry => {
            if (!userActivity[entry.user_id]) {
                userActivity[entry.user_id] = { glucose_readings: 0, bp_readings: 0, steps_entries: 0, medication_entries: 0 };
            }
            userActivity[entry.user_id].steps_entries++;
        });

        // Process medication activity
        medicationActivity.data?.forEach(entry => {
            if (!userActivity[entry.user_id]) {
                userActivity[entry.user_id] = { glucose_readings: 0, bp_readings: 0, steps_entries: 0, medication_entries: 0 };
            }
            userActivity[entry.user_id].medication_entries++;
        });

        // Get user details for activity data
        const userIds = Object.keys(userActivity);
        const { data: users } = await supabase
            .from('user_profiles')
            .select('id, name, email, diabetes_type, diabetes_status')
            .in('id', userIds);

        const activityData = users?.map(user => ({
            user_id: user.id,
            name: user.name,
            email: user.email,
            diabetes_type: user.diabetes_type,
            diabetes_status: user.diabetes_status,
            activity: userActivity[user.id] || { glucose_readings: 0, bp_readings: 0, steps_entries: 0, medication_entries: 0 },
            total_activity: Object.values(userActivity[user.id] || {}).reduce((sum, val) => sum + val, 0)
        })) || [];

        if (format === 'csv') {
            const csv = convertUserActivityToCSV(activityData);
            res.setHeader('Content-Type', 'text/csv');
            res.setHeader('Content-Disposition', `attachment; filename=user_activity_${days}_days_export.csv`);
            res.send(csv);
        } else {
            res.json({
                activityData,
                summary: {
                    total_users: activityData.length,
                    active_users: activityData.filter(u => u.total_activity > 0).length,
                    period_days: parseInt(days),
                    export_date: new Date().toISOString()
                }
            });
        }
    } catch (error) {
        console.error('Export user activity error:', error);
        res.status(500).json({
            error: 'Internal server error',
            message: 'Failed to export user activity data'
        });
    }
});

// Helper functions for analytics export
async function getUserStats() {
    try {
        const { count: totalUsers } = await supabase
            .from('user_profiles')
            .select('*', { count: 'exact', head: true });

        const startOfMonth = new Date();
        startOfMonth.setDate(1);
        startOfMonth.setHours(0, 0, 0, 0);
        
        const { count: newUsersThisMonth } = await supabase
            .from('user_profiles')
            .select('*', { count: 'exact', head: true })
            .gte('created_at', startOfMonth.toISOString());

        return {
            totalUsers: totalUsers || 0,
            newUsersThisMonth: newUsersThisMonth || 0
        };
    } catch (error) {
        console.error('Error getting user stats:', error);
        return { totalUsers: 0, newUsersThisMonth: 0 };
    }
}

async function getMedicationStats() {
    try {
        const { count: totalMedications } = await supabase
            .from('medications')
            .select('*', { count: 'exact', head: true });

        const { count: activeMedications } = await supabase
            .from('medications')
            .select('*', { count: 'exact', head: true })
            .eq('is_active', true);

        return {
            totalMedications: totalMedications || 0,
            activeMedications: activeMedications || 0
        };
    } catch (error) {
        console.error('Error getting medication stats:', error);
        return { totalMedications: 0, activeMedications: 0 };
    }
}

async function getContentStats() {
    try {
        const { count: totalArticles } = await supabase
            .from('articles')
            .select('*', { count: 'exact', head: true });

        const { count: totalVideos } = await supabase
            .from('videos')
            .select('*', { count: 'exact', head: true });

        return {
            totalArticles: totalArticles || 0,
            totalVideos: totalVideos || 0
        };
    } catch (error) {
        console.error('Error getting content stats:', error);
        return { totalArticles: 0, totalVideos: 0 };
    }
}

async function getHealthStats() {
    try {
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

        const { data: glucoseReadings } = await supabase
            .from('glucose_readings')
            .select('glucose_level')
            .gte('created_at', thirtyDaysAgo.toISOString());

        const { data: bpReadings } = await supabase
            .from('blood_pressure_readings')
            .select('systolic, diastolic')
            .gte('created_at', thirtyDaysAgo.toISOString());

        return {
            glucoseReadings: glucoseReadings ? glucoseReadings.length : 0,
            bloodPressureReadings: bpReadings ? bpReadings.length : 0
        };
    } catch (error) {
        console.error('Error getting health stats:', error);
        return { glucoseReadings: 0, bloodPressureReadings: 0 };
    }
}

async function getEngagementStats() {
    try {
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

        const { data: glucoseUsers } = await supabase
            .from('glucose_readings')
            .select('user_id')
            .gte('created_at', sevenDaysAgo.toISOString());

        const { data: bpUsers } = await supabase
            .from('blood_pressure_readings')
            .select('user_id')
            .gte('created_at', sevenDaysAgo.toISOString());

        return {
            activeGlucoseUsers: glucoseUsers ? new Set(glucoseUsers.map(u => u.user_id)).size : 0,
            activeBpUsers: bpUsers ? new Set(bpUsers.map(u => u.user_id)).size : 0
        };
    } catch (error) {
        console.error('Error getting engagement stats:', error);
        return { activeGlucoseUsers: 0, activeBpUsers: 0 };
    }
}

// Enhanced CSV conversion functions
function convertUsersToCSV(users) {
    if (!users || users.length === 0) return '';
    
    const headers = [
        'ID', 'Name', 'Email', 'Diabetes Type', 'Diabetes Status', 
        'Age', 'Gender', 'Created At', 'Updated At',
        'Glucose Readings Count', 'Blood Pressure Readings Count', 
        'Steps Entries Count', 'Medications Count'
    ];
    
    const csvRows = [headers.join(',')];
    
    for (const user of users) {
        const values = [
            user.id,
            `"${user.name || ''}"`,
            `"${user.email || ''}"`,
            `"${user.diabetes_type || ''}"`,
            `"${user.diabetes_status || ''}"`,
            user.age || '',
            `"${user.gender || ''}"`,
            `"${user.created_at || ''}"`,
            `"${user.updated_at || ''}"`,
            user.activity_summary?.glucose_readings_count || 0,
            user.activity_summary?.blood_pressure_readings_count || 0,
            user.activity_summary?.steps_entries_count || 0,
            user.activity_summary?.medications_count || 0
        ];
        csvRows.push(values.join(','));
    }
    
    return csvRows.join('\n');
}

function convertMedicationsToCSV(medications) {
    if (!medications || medications.length === 0) return '';
    
    const headers = [
        'ID', 'Name', 'Dosage', 'Frequency', 'Is Active', 'Created At',
        'User Name', 'User Email', 'User Diabetes Type', 'User Diabetes Status',
        'History Count'
    ];
    
    const csvRows = [headers.join(',')];
    
    for (const med of medications) {
        const values = [
            med.id,
            `"${med.name || ''}"`,
            `"${med.dosage || ''}"`,
            `"${med.frequency || ''}"`,
            med.is_active ? 'Yes' : 'No',
            `"${med.created_at || ''}"`,
            `"${med.user_info?.name || ''}"`,
            `"${med.user_info?.email || ''}"`,
            `"${med.user_info?.diabetes_type || ''}"`,
            `"${med.user_info?.diabetes_status || ''}"`,
            med.history_count || 0
        ];
        csvRows.push(values.join(','));
    }
    
    return csvRows.join('\n');
}

function convertMedicationHistoryToCSV(history) {
    if (!history || history.length === 0) return '';
    
    const headers = [
        'ID', 'Medication Name', 'Dosage', 'Frequency', 'Taken At',
        'User Name', 'User Email', 'Status', 'Notes'
    ];
    
    const csvRows = [headers.join(',')];
    
    for (const entry of history) {
        const values = [
            entry.id,
            `"${entry.medications?.name || ''}"`,
            `"${entry.medications?.dosage || ''}"`,
            `"${entry.medications?.frequency || ''}"`,
            `"${entry.taken_at || ''}"`,
            `"${entry.user_profiles?.name || ''}"`,
            `"${entry.user_profiles?.email || ''}"`,
            `"${entry.status || ''}"`,
            `"${entry.notes || ''}"`
        ];
        csvRows.push(values.join(','));
    }
    
    return csvRows.join('\n');
}

function convertArticlesToCSV(articles) {
    if (!articles || articles.length === 0) return '';
    
    const headers = [
        'ID', 'Title', 'Content', 'Category', 'Is Published', 'Is Featured',
        'Created At', 'Updated At', 'Author', 'Tags'
    ];
    
    const csvRows = [headers.join(',')];
    
    for (const article of articles) {
        const values = [
            article.id,
            `"${article.title || ''}"`,
            `"${(article.content || '').replace(/"/g, '""')}"`,
            `"${article.blog_categories?.name || ''}"`,
            article.is_published ? 'Yes' : 'No',
            article.is_featured ? 'Yes' : 'No',
            `"${article.created_at || ''}"`,
            `"${article.updated_at || ''}"`,
            `"${article.author || ''}"`,
            `"${article.tags || ''}"`
        ];
        csvRows.push(values.join(','));
    }
    
    return csvRows.join('\n');
}

function convertVideosToCSV(videos) {
    if (!videos || videos.length === 0) return '';
    
    const headers = [
        'ID', 'Title', 'Description', 'Category', 'Video URL', 'Thumbnail URL',
        'Duration', 'Is Published', 'Is Featured', 'Created At', 'Updated At'
    ];
    
    const csvRows = [headers.join(',')];
    
    for (const video of videos) {
        const values = [
            video.id,
            `"${video.title || ''}"`,
            `"${(video.description || '').replace(/"/g, '""')}"`,
            `"${video.education_categories?.name || ''}"`,
            `"${video.video_url || ''}"`,
            `"${video.thumbnail_url || ''}"`,
            video.duration || '',
            video.is_published ? 'Yes' : 'No',
            video.is_featured ? 'Yes' : 'No',
            `"${video.created_at || ''}"`,
            `"${video.updated_at || ''}"`
        ];
        csvRows.push(values.join(','));
    }
    
    return csvRows.join('\n');
}

function convertHealthDataToCSV(data, type) {
    const csvRows = [];
    
    if (type === 'all' || type === 'glucose') {
        if (data.glucoseReadings && data.glucoseReadings.length > 0) {
            csvRows.push('=== GLUCOSE READINGS ===');
            csvRows.push('ID,User Name,User Email,Glucose Level,Reading Time,Notes');
            data.glucoseReadings.forEach(reading => {
                csvRows.push([
                    reading.id,
                    `"${reading.user_profiles?.name || ''}"`,
                    `"${reading.user_profiles?.email || ''}"`,
                    reading.glucose_level,
                    `"${reading.created_at || ''}"`,
                    `"${reading.notes || ''}"`
                ].join(','));
            });
            csvRows.push('');
        }
    }
    
    if (type === 'all' || type === 'blood_pressure') {
        if (data.bloodPressureReadings && data.bloodPressureReadings.length > 0) {
            csvRows.push('=== BLOOD PRESSURE READINGS ===');
            csvRows.push('ID,User Name,User Email,Systolic,Diastolic,Reading Time,Notes');
            data.bloodPressureReadings.forEach(reading => {
                csvRows.push([
                    reading.id,
                    `"${reading.user_profiles?.name || ''}"`,
                    `"${reading.user_profiles?.email || ''}"`,
                    reading.systolic,
                    reading.diastolic,
                    `"${reading.created_at || ''}"`,
                    `"${reading.notes || ''}"`
                ].join(','));
            });
            csvRows.push('');
        }
    }
    
    if (type === 'all' || type === 'steps') {
        if (data.stepsEntries && data.stepsEntries.length > 0) {
            csvRows.push('=== STEPS ENTRIES ===');
            csvRows.push('ID,User Name,User Email,Steps Count,Date,Notes');
            data.stepsEntries.forEach(entry => {
                csvRows.push([
                    entry.id,
                    `"${entry.user_profiles?.name || ''}"`,
                    `"${entry.user_profiles?.email || ''}"`,
                    entry.steps_count,
                    `"${entry.created_at || ''}"`,
                    `"${entry.notes || ''}"`
                ].join(','));
            });
        }
    }
    
    return csvRows.join('\n');
}

function convertUserActivityToCSV(activityData) {
    if (!activityData || activityData.length === 0) return '';
    
    const headers = [
        'User ID', 'Name', 'Email', 'Diabetes Type', 'Diabetes Status',
        'Glucose Readings', 'Blood Pressure Readings', 'Steps Entries', 'Medication Entries',
        'Total Activity'
    ];
    
    const csvRows = [headers.join(',')];
    
    for (const user of activityData) {
        const values = [
            user.user_id,
            `"${user.name || ''}"`,
            `"${user.email || ''}"`,
            `"${user.diabetes_type || ''}"`,
            `"${user.diabetes_status || ''}"`,
            user.activity.glucose_readings,
            user.activity.bp_readings,
            user.activity.steps_entries,
            user.activity.medication_entries,
            user.total_activity
        ];
        csvRows.push(values.join(','));
    }
    
    return csvRows.join('\n');
}

// Helper function to convert data to CSV (legacy)
function convertToCSV(data) {
    if (!data || data.length === 0) {
        return '';
    }

    const headers = Object.keys(data[0]);
    const csvRows = [];

    // Add header row
    csvRows.push(headers.join(','));

    // Add data rows
    for (const row of data) {
        const values = headers.map(header => {
            const value = row[header];
            // Escape commas and quotes
            if (typeof value === 'string' && (value.includes(',') || value.includes('"'))) {
                return `"${value.replace(/"/g, '""')}"`;
            }
            return value || '';
        });
        csvRows.push(values.join(','));
    }

    return csvRows.join('\n');
}

// Helper function to convert analytics data to CSV
function convertAnalyticsToCSV(analyticsData) {
    const csvRows = [];
    
    // Add header
    csvRows.push('Metric,Value,Category');
    
    // User stats
    csvRows.push(`Total Users,${analyticsData.userStats.totalUsers},Users`);
    csvRows.push(`New Users This Month,${analyticsData.userStats.newUsersThisMonth},Users`);
    
    // Medication stats
    csvRows.push(`Total Medications,${analyticsData.medicationStats.totalMedications},Medications`);
    csvRows.push(`Active Medications,${analyticsData.medicationStats.activeMedications},Medications`);
    
    // Content stats
    csvRows.push(`Total Articles,${analyticsData.contentStats.totalArticles},Content`);
    csvRows.push(`Total Videos,${analyticsData.contentStats.totalVideos},Content`);
    
    // Health stats
    csvRows.push(`Glucose Readings (30d),${analyticsData.healthStats.glucoseReadings},Health`);
    csvRows.push(`Blood Pressure Readings (30d),${analyticsData.healthStats.bloodPressureReadings},Health`);
    
    // Engagement stats
    csvRows.push(`Active Glucose Users (7d),${analyticsData.engagementStats.activeGlucoseUsers},Engagement`);
    csvRows.push(`Active BP Users (7d),${analyticsData.engagementStats.activeBpUsers},Engagement`);
    
    // Export date
    csvRows.push(`Export Date,${analyticsData.exportDate},Metadata`);
    
    return csvRows.join('\n');
}

module.exports = router; 