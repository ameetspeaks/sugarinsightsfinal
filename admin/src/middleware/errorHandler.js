// Error handling middleware
const errorHandler = (err, req, res, next) => {
  console.error('Error:', err);

  // Default error
  let error = {
    message: err.message || 'Internal Server Error',
    status: err.status || 500
  };

  // Validation errors
  if (err.name === 'ValidationError') {
    error.status = 400;
    error.message = 'Validation Error';
    error.details = err.details;
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    error.status = 401;
    error.message = 'Invalid token';
  }

  // Database errors
  if (err.code === '23505') { // Unique constraint violation
    error.status = 409;
    error.message = 'Resource already exists';
  }

  if (err.code === '23503') { // Foreign key violation
    error.status = 400;
    error.message = 'Referenced resource does not exist';
  }

  // Supabase errors
  if (err.code === 'PGRST116') {
    error.status = 404;
    error.message = 'Resource not found';
  }

  // Rate limiting errors
  if (err.status === 429) {
    error.status = 429;
    error.message = 'Too many requests';
  }

  res.status(error.status).json({
    error: error.message,
    details: error.details,
    timestamp: new Date().toISOString(),
    path: req.path
  });
};

module.exports = {
  errorHandler
}; 