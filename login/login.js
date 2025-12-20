const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static('public'));

// PostgreSQL connection pool
const pool = new Pool({
    user: process.env.DB_USER || 'postgres',
    host: process.env.DB_HOST || 'localhost',
    database: process.env.DB_NAME || 'student_system',
    password: process.env.DB_PASSWORD || 'password',
    port: process.env.DB_PORT || 5432,
});

// Login attempts tracking (in-memory for simplicity)
const loginAttempts = new Map();
const MAX_LOGIN_ATTEMPTS = 3;
const LOCKOUT_TIME = 15 * 60 * 1000; // 15 minutes in milliseconds

// Test database connection
pool.connect((err, client, release) => {
    if (err) {
        console.error('Error connecting to database:', err);
    } else {
        console.log('Connected to PostgreSQL database');
        release();
    }
});

// Login endpoint
app.post('/api/login', async (req, res) => {
    const { email, password, userType } = req.body;
    const clientIp = req.ip || req.connection.remoteAddress;
    
    try {
        // Check login attempts
        const attempts = loginAttempts.get(clientIp) || { count: 0, lastAttempt: Date.now() };
        
        // Reset if lockout time has passed
        if (Date.now() - attempts.lastAttempt > LOCKOUT_TIME) {
            attempts.count = 0;
        }
        
        // Check if exceeded max attempts
        if (attempts.count >= MAX_LOGIN_ATTEMPTS) {
            return res.status(429).json({
                success: false,
                message: 'Too many login attempts. Please try again later.'
            });
        }
        
        // Determine which table to query based on user type
        let table, idField, nameField;
        if (userType === 'student') {
            table = 'students';
            idField = 'student_id';
            nameField = 'CONCAT(first_name, \' \', last_name) as name';
        } else if (userType === 'instructor') {
            table = 'instructors';
            idField = 'instructor_id';
            nameField = 'CONCAT(first_name, \' \', last_name) as name';
        } else {
            return res.status(400).json({
                success: false,
                message: 'Invalid user type'
            });
        }
        
        // Query database
        const query = `
            SELECT ${idField}, email, password_hash, ${nameField}
            FROM ${table}
            WHERE email = $1
        `;
        
        const result = await pool.query(query, [email]);
        
        if (result.rows.length === 0) {
            // Increment failed attempt
            attempts.count++;
            attempts.lastAttempt = Date.now();
            loginAttempts.set(clientIp, attempts);
            
            return res.status(401).json({
                success: false,
                message: 'Invalid email or password'
            });
        }
        
        const user = result.rows[0];
        
        // In a real application, you would verify the password hash
        // For demo purposes, we'll check against a simple pattern
        // Note: In production, use bcrypt.compare(password, user.password_hash)
        const isValidPassword = password === 'password123'; // Demo only
        
        if (!isValidPassword) {
            // Increment failed attempt
            attempts.count++;
            attempts.lastAttempt = Date.now();
            loginAttempts.set(clientIp, attempts);
            
            return res.status(401).json({
                success: false,
                message: 'Invalid email or password'
            });
        }
        
        // Reset login attempts on successful login
        loginAttempts.delete(clientIp);
        
        // Return user data (excluding password hash)
        res.json({
            success: true,
            message: 'Login successful',
            user: {
                id: user[idField],
                email: user.email,
                name: user.name,
                userType: userType
            }
        });
        
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
});

// Get student dashboard data
app.get('/api/student/:id/dashboard', async (req, res) => {
    try {
        const studentId = req.params.id;
        
        // Get student info
        const studentQuery = `
            SELECT s.*, d.department_name
            FROM students s
            LEFT JOIN departments d ON s.department_id = d.department_id
            WHERE s.student_id = $1
        `;
        
        // Get enrolled courses
        const coursesQuery = `
            SELECT c.course_code, c.course_name, c.credits, e.grade, e.status,
                   i.first_name || ' ' || i.last_name as instructor_name
            FROM enrollments e
            JOIN courses c ON e.course_id = c.course_id
            LEFT JOIN instructors i ON c.instructor_id = i.instructor_id
            WHERE e.student_id = $1
            ORDER BY c.course_code
        `;
        
        // Calculate GPA
        const gpaQuery = `SELECT calculate_student_gpa($1) as gpa`;
        
        const [studentResult, coursesResult, gpaResult] = await Promise.all([
            pool.query(studentQuery, [studentId]),
            pool.query(coursesQuery, [studentId]),
            pool.query(gpaQuery, [studentId])
        ]);
        
        if (studentResult.rows.length === 0) {
            return res.status(404).json({ error: 'Student not found' });
        }
        
        res.json({
            student: studentResult.rows[0],
            courses: coursesResult.rows,
            gpa: gpaResult.rows[0].gpa
        });
        
    } catch (error) {
        console.error('Dashboard error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Get instructor dashboard data
app.get('/api/instructor/:id/dashboard', async (req, res) => {
    try {
        const instructorId = req.params.id;
        
        // Get instructor info
        const instructorQuery = `
            SELECT i.*, d.department_name
            FROM instructors i
            LEFT JOIN departments d ON i.department_id = d.department_id
            WHERE i.instructor_id = $1
        `;
        
        // Get assigned courses
        const coursesQuery = `
            SELECT c.*, COUNT(e.student_id) as enrolled_students
            FROM courses c
            LEFT JOIN enrollments e ON c.course_id = e.course_id AND e.status = 'enrolled'
            WHERE c.instructor_id = $1
            GROUP BY c.course_id
            ORDER BY c.course_code
        `;
        
        // Get course students using the view
        const studentsQuery = `
            SELECT * FROM instructor_course_students
            WHERE instructor_id = $1
            ORDER BY course_code, student_name
        `;
        
        const [instructorResult, coursesResult, studentsResult] = await Promise.all([
            pool.query(instructorQuery, [instructorId]),
            pool.query(coursesQuery, [instructorId]),
            pool.query(studentsQuery, [instructorId])
        ]);
        
        if (instructorResult.rows.length === 0) {
            return res.status(404).json({ error: 'Instructor not found' });
        }
        
        res.json({
            instructor: instructorResult.rows[0],
            courses: coursesResult.rows,
            students: studentsResult.rows
        });
        
    } catch (error) {
        console.error('Instructor dashboard error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Update student grade
app.post('/api/update-grade', async (req, res) => {
    try {
        const { studentId, courseId, grade } = req.body;
        
        // Call the stored procedure
        await pool.query('CALL update_student_grade($1, $2, $3)', 
            [studentId, courseId, grade]);
        
        res.json({ success: true, message: 'Grade updated successfully' });
        
    } catch (error) {
        console.error('Update grade error:', error);
        res.status(400).json({ 
            success: false, 
            message: error.message 
        });
    }
});

// Generate student transcript
app.get('/api/student/:id/transcript', async (req, res) => {
    try {
        const studentId = req.params.id;
        
        // Call the stored procedure
        const result = await pool.query('CALL generate_student_transcript($1)', [studentId]);
        
        // Note: The procedure outputs via RAISE NOTICE, so we need to handle it differently
        // In production, you'd want to modify the procedure to return data
        res.json({ 
            success: true, 
            message: 'Transcript generated (check server logs)' 
        });
        
    } catch (error) {
        console.error('Transcript error:', error);
        res.status(400).json({ 
            success: false, 
            message: error.message 
        });
    }
});

// Start server
app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});