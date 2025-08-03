const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const { supabase } = require('../config/database');
const { authRateLimiter } = require('../middleware/rateLimiter');
const { verifyToken, authenticateToken } = require('../middleware/auth');

const router = express.Router();

// GET login route (for debugging and direct access)
router.get('/login', async (req, res) => {
    try {
        const { email, password } = req.query;
        
        if (!email || !password) {
            return res.status(400).json({
                error: 'Missing credentials',
                message: 'Email and password are required'
            });
        }

        console.log('GET login attempt:', { email, password: '***' });

        // Check if admin exists in database
        const { data: admin, error } = await supabase
            .from('admin_users')
            .select('*')
            .eq('email', email)
            .single();

        if (error || !admin) {
            console.log('Admin not found for email:', email);
            return res.status(401).json({
                error: 'Authentication failed',
                message: 'Invalid email or password'
            });
        }

        // Verify password
        const isValidPassword = await bcrypt.compare(password, admin.password_hash);
        if (!isValidPassword) {
            console.log('Invalid password for email:', email);
            return res.status(401).json({
                error: 'Authentication failed',
                message: 'Invalid email or password'
            });
        }

        // Generate JWT token
        const token = jwt.sign(
            {
                id: admin.id,
                email: admin.email,
                role: admin.role,
                permissions: admin.permissions
            },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
        );

        // Update last login
        await supabase
            .from('admin_users')
            .update({ last_login: new Date().toISOString() })
            .eq('id', admin.id);

        console.log('Login successful for:', email);

        res.json({
            message: 'Login successful',
            token,
            user: {
                id: admin.id,
                email: admin.email,
                role: admin.role,
                permissions: admin.permissions,
                name: admin.name
            }
        });

    } catch (error) {
        console.error('GET Login error:', error);
        res.status(500).json({
            error: 'Internal server error',
            message: 'Login failed'
        });
    }
});

// Admin login (POST)
router.post('/login', 
  authRateLimiter,
  [
    body('email').isEmail().normalizeEmail(),
    body('password').isLength({ min: 6 })
  ],
  async (req, res) => {
    try {
      console.log('POST login attempt:', { email: req.body.email, password: '***' });

      // Check validation errors
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        console.log('Validation errors:', errors.array());
        return res.status(400).json({
          error: 'Validation Error',
          details: errors.array()
        });
      }

      const { email, password } = req.body;

      // Check if admin exists in database
      const { data: admin, error } = await supabase
        .from('admin_users')
        .select('*')
        .eq('email', email)
        .single();

      if (error || !admin) {
        console.log('Admin not found for email:', email);
        return res.status(401).json({
          error: 'Authentication failed',
          message: 'Invalid email or password'
        });
      }

      // Verify password
      const isValidPassword = await bcrypt.compare(password, admin.password_hash);
      if (!isValidPassword) {
        console.log('Invalid password for email:', email);
        return res.status(401).json({
          error: 'Authentication failed',
          message: 'Invalid email or password'
        });
      }

      // Generate JWT token
      const token = jwt.sign(
        {
          id: admin.id,
          email: admin.email,
          role: admin.role,
          permissions: admin.permissions
        },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
      );

      // Update last login
      await supabase
        .from('admin_users')
        .update({ last_login: new Date().toISOString() })
        .eq('id', admin.id);

      console.log('Login successful for:', email);

      res.json({
        message: 'Login successful',
        token,
        user: {
          id: admin.id,
          email: admin.email,
          role: admin.role,
          permissions: admin.permissions,
          name: admin.name
        }
      });

    } catch (error) {
      console.error('POST Login error:', error);
      res.status(500).json({
        error: 'Internal server error',
        message: 'Login failed'
      });
    }
  }
);

// Get current admin profile
router.get('/profile', verifyToken, async (req, res) => {
  try {
    const { data: admin, error } = await supabase
      .from('admin_users')
      .select('id, email, name, role, permissions, created_at, last_login')
      .eq('id', req.user.id)
      .single();

    if (error || !admin) {
      return res.status(404).json({
        error: 'Admin not found'
      });
    }

    res.json({
      user: admin
    });

  } catch (error) {
    console.error('Profile error:', error);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
});

// Logout
router.post('/logout', verifyToken, async (req, res) => {
  try {
    // In a real application, you might want to blacklist the token
    // For now, we'll just return a success message
    res.json({
      message: 'Logout successful'
    });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
});

// Refresh token
router.post('/refresh', verifyToken, async (req, res) => {
  try {
    // Generate new token
    const token = jwt.sign(
      {
        id: req.user.id,
        email: req.user.email,
        role: req.user.role,
        permissions: req.user.permissions
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
    );

    res.json({
      message: 'Token refreshed',
      token
    });

  } catch (error) {
    console.error('Token refresh error:', error);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
});

module.exports = router; 