-- Create departments table
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    department_code VARCHAR(10) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create instructors table
CREATE TABLE instructors (
    instructor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    department_id INT REFERENCES departments(department_id) ON DELETE SET NULL,
    hire_date DATE,
    salary DECIMAL(10,2),
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create students table
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    date_of_birth DATE,
    department_id INT REFERENCES departments(department_id) ON DELETE SET NULL,
    enrollment_date DATE DEFAULT CURRENT_DATE,
    tuition_fees DECIMAL(10,2) DEFAULT 5000.00,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create courses table
CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,
    course_code VARCHAR(20) NOT NULL UNIQUE,
    course_name VARCHAR(100) NOT NULL,
    credits INT NOT NULL CHECK (credits BETWEEN 1 AND 5),
    department_id INT REFERENCES departments(department_id) ON DELETE CASCADE,
    instructor_id INT REFERENCES instructors(instructor_id) ON DELETE SET NULL,
    max_capacity INT DEFAULT 30,
    current_enrollment INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create enrollments table
CREATE TABLE enrollments (
    enrollment_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(student_id) ON DELETE CASCADE,
    course_id INT REFERENCES courses(course_id) ON DELETE CASCADE,
    enrollment_date DATE DEFAULT CURRENT_DATE,
    grade DECIMAL(4,2) CHECK (grade BETWEEN 0 AND 100),
    status VARCHAR(20) DEFAULT 'enrolled' CHECK (status IN ('enrolled', 'completed', 'dropped')),
    UNIQUE(student_id, course_id)
);

-- Create indexes for performance
CREATE INDEX idx_students_email ON students(email);
CREATE INDEX idx_students_department ON students(department_id);
CREATE INDEX idx_instructors_email ON instructors(email);
CREATE INDEX idx_courses_department ON courses(department_id);
CREATE INDEX idx_courses_instructor ON courses(instructor_id);
CREATE INDEX idx_enrollments_student ON enrollments(student_id);
CREATE INDEX idx_enrollments_course ON enrollments(course_id);
CREATE INDEX idx_enrollments_grade ON enrollments(grade);

-- Insert sample data into departments
INSERT INTO departments (department_name, department_code) VALUES
('Computer Science', 'CS'),
('Mathematics', 'MATH'),
('Physics', 'PHYS'),
('Engineering', 'ENG'),
('Business Administration', 'BUS');

-- Insert sample data into instructors
INSERT INTO instructors (first_name, last_name, email, department_id, hire_date, salary, password_hash) VALUES
('John', 'Smith', 'john.smith@university.edu', 1, '2018-06-15', 75000.00, '$2b$10$Kx7kY1U9VZ8e8V8V8V8V8e'),
('Sarah', 'Johnson', 'sarah.j@university.edu', 1, '2020-02-10', 68000.00, '$2b$10$Kx7kY1U9VZ8e8V8V8V8Ve'),
('Michael', 'Brown', 'michael.b@university.edu', 2, '2015-09-01', 82000.00, '$2b$10$Kx7kY1U9VZ8e8V8V8V8Ve'),
('Emily', 'Davis', 'emily.d@university.edu', 3, '2019-03-22', 71000.00, '$2b$10$Kx7kY1U9VZ8e8V8V8V8Ve'),
('Robert', 'Wilson', 'robert.w@university.edu', 4, '2017-11-05', 78000.00, '$2b$10$Kx7kY1U9VZ8e8V8V8V8Ve');

-- Insert sample data into students
INSERT INTO students (first_name, last_name, email, date_of_birth, department_id, enrollment_date, tuition_fees, password_hash) VALUES
('Alice', 'Johnson', 'alice.j@student.edu', '2000-05-15', 1, '2022-09-01', 5500.00, '$2b$10$Kx7kY1U9VZ8e8V8V8V8V8e'),
('Bob', 'Williams', 'bob.w@student.edu', '2001-03-22', 1, '2022-09-01', 5500.00, '$2b$10$Kx7kY1U9VZ8e8V8V8V8Ve'),
('Charlie', 'Miller', 'charlie.m@student.edu', '1999-11-30', 2, '2021-09-01', 5300.00, '$2b$10$Kx7kY1U9VZ8e8V8V8V8Ve'),
('Diana', 'Garcia', 'diana.g@student.edu', '2000-07-12', 3, '2022-09-01', 5200.00, '$2b$10$Kx7kY1U9VZ8e8V8V8V8Ve'),
('Ethan', 'Taylor', 'ethan.t@student.edu', '2001-01-25', 4, '2023-01-15', 5600.00, '$2b$10$Kx7kY1U9VZ8e8V8V8V8Ve');

-- Insert sample data into courses
INSERT INTO courses (course_code, course_name, credits, department_id, instructor_id, max_capacity, current_enrollment) VALUES
('CS101', 'Introduction to Programming', 3, 1, 1, 30, 0),
('CS201', 'Data Structures', 4, 1, 2, 25, 0),
('MATH101', 'Calculus I', 4, 2, 3, 35, 0),
('PHYS101', 'Physics I', 4, 3, 4, 30, 0),
('ENG101', 'Engineering Fundamentals', 3, 4, 5, 28, 0),
('BUS101', 'Business Principles', 3, 5, NULL, 40, 0);

-- Insert sample data into enrollments
INSERT INTO enrollments (student_id, course_id, grade, status) VALUES
(1, 1, 85.5, 'completed'),
(1, 2, 92.0, 'enrolled'),
(2, 1, 78.0, 'completed'),
(2, 2, NULL, 'enrolled'),
(3, 3, 88.5, 'completed'),
(3, 4, NULL, 'enrolled'),
(4, 4, 91.0, 'completed'),
(4, 5, NULL, 'enrolled'),
(5, 5, 86.5, 'completed'),
(5, 1, NULL, 'enrolled');

-- Update current enrollment counts
UPDATE courses c
SET current_enrollment = (
    SELECT COUNT(*) 
    FROM enrollments e 
    WHERE e.course_id = c.course_id 
    AND e.status != 'dropped'
);
-- student_system_views.sql

-- View for student grades that hides sensitive information like emails
CREATE OR REPLACE VIEW student_grades_confidential AS
SELECT 
    s.student_id,
    s.first_name || ' ' || s.last_name AS student_name,
    s.department_id,
    c.course_code,
    c.course_name,
    e.grade,
    e.status,
    e.enrollment_date
FROM students s
JOIN enrollments e ON s.student_id = e.student_id
JOIN courses c ON e.course_id = c.course_id
WHERE e.grade IS NOT NULL
ORDER BY s.student_id, c.course_code;

-- View for instructors showing only their courses and enrolled students
CREATE OR REPLACE VIEW instructor_course_students AS
SELECT 
    i.instructor_id,
    i.first_name || ' ' || i.last_name AS instructor_name,
    c.course_id,
    c.course_code,
    c.course_name,
    s.student_id,
    s.first_name || ' ' || s.last_name AS student_name,
    e.enrollment_date,
    e.grade,
    e.status
FROM instructors i
JOIN courses c ON i.instructor_id = c.instructor_id
JOIN enrollments e ON c.course_id = e.course_id
JOIN students s ON e.student_id = s.student_id
WHERE e.status != 'dropped'
ORDER BY i.instructor_id, c.course_code, s.last_name;
-- student_system_functions.sql

-- Procedure to update student grades for a course
CREATE OR REPLACE PROCEDURE update_student_grade(
    p_student_id INT,
    p_course_id INT,
    p_grade DECIMAL(4,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validate grade range
    IF p_grade < 0 OR p_grade > 100 THEN
        RAISE EXCEPTION 'Grade must be between 0 and 100';
    END IF;
    
    -- Check if enrollment exists
    IF NOT EXISTS (
        SELECT 1 FROM enrollments 
        WHERE student_id = p_student_id 
        AND course_id = p_course_id
    ) THEN
        RAISE EXCEPTION 'Student is not enrolled in this course';
    END IF;
    
    -- Update the grade
    UPDATE enrollments 
    SET grade = p_grade,
        status = CASE WHEN p_grade >= 60 THEN 'completed' ELSE 'completed' END
    WHERE student_id = p_student_id 
    AND course_id = p_course_id;
    
    RAISE NOTICE 'Grade updated successfully for student % in course %', p_student_id, p_course_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error updating grade: %', SQLERRM;
END;
$$;

-- Function to calculate GPA of a student
CREATE OR REPLACE FUNCTION calculate_student_gpa(p_student_id INT)
RETURNS DECIMAL(3,2)
LANGUAGE plpgsql
AS $$
DECLARE
    total_points DECIMAL(5,2) := 0;
    total_credits INT := 0;
    course_record RECORD;
    grade_point DECIMAL(3,2);
    v_gpa DECIMAL(3,2);
BEGIN
    -- Check if student exists
    IF NOT EXISTS (SELECT 1 FROM students WHERE student_id = p_student_id) THEN
        RAISE EXCEPTION 'Student with ID % does not exist', p_student_id;
    END IF;
    
    -- Loop through completed courses
    FOR course_record IN (
        SELECT e.grade, c.credits
        FROM enrollments e
        JOIN courses c ON e.course_id = c.course_id
        WHERE e.student_id = p_student_id 
        AND e.grade IS NOT NULL
        AND e.status = 'completed'
    ) LOOP
        -- Convert percentage grade to grade points (4.0 scale)
        CASE 
            WHEN course_record.grade >= 90 THEN grade_point := 4.0;
            WHEN course_record.grade >= 80 THEN grade_point := 3.0;
            WHEN course_record.grade >= 70 THEN grade_point := 2.0;
            WHEN course_record.grade >= 60 THEN grade_point := 1.0;
            ELSE grade_point := 0.0;
        END CASE;
        
        total_points := total_points + (grade_point * course_record.credits);
        total_credits := total_credits + course_record.credits;
    END LOOP;
    
    -- Calculate GPA
    IF total_credits > 0 THEN
        v_gpa := total_points / total_credits;
    ELSE
        v_gpa := 0;
    END IF;
    
    RETURN ROUND(v_gpa, 2);
END;
$$;

-- Procedure to adjust course credits or student tuition fees
CREATE OR REPLACE PROCEDURE adjust_academic_financial(
    p_action VARCHAR(20),
    p_id INT,
    p_amount DECIMAL(10,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Amount must be positive';
    END IF;
    
    CASE p_action
        WHEN 'course_credits' THEN
            -- Update course credits
            UPDATE courses 
            SET credits = p_amount 
            WHERE course_id = p_id;
            
            IF NOT FOUND THEN
                RAISE EXCEPTION 'Course with ID % not found', p_id;
            END IF;
            RAISE NOTICE 'Course credits updated for course %', p_id;
            
        WHEN 'student_fees' THEN
            -- Update student tuition fees
            UPDATE students 
            SET tuition_fees = p_amount 
            WHERE student_id = p_id;
            
            IF NOT FOUND THEN
                RAISE EXCEPTION 'Student with ID % not found', p_id;
            END IF;
            RAISE NOTICE 'Tuition fees updated for student %', p_id;
            
        ELSE
            RAISE EXCEPTION 'Invalid action. Use "course_credits" or "student_fees"';
    END CASE;
END;
$$;
-- student_system_cursors.sql

-- Explicit cursor to list all students and their enrolled courses
CREATE OR REPLACE FUNCTION list_students_courses()
RETURNS TABLE(
    student_name VARCHAR(101),
    course_code VARCHAR(20),
    course_name VARCHAR(100),
    grade DECIMAL(4,2)
) 
LANGUAGE plpgsql
AS $$
DECLARE
    student_cursor CURSOR FOR
        SELECT s.student_id, s.first_name, s.last_name
        FROM students s
        ORDER BY s.last_name, s.first_name;
    
    course_cursor CURSOR (s_id INT) FOR
        SELECT c.course_code, c.course_name, e.grade
        FROM enrollments e
        JOIN courses c ON e.course_id = c.course_id
        WHERE e.student_id = s_id
        ORDER BY c.course_code;
    
    v_student_id INT;
    v_first_name VARCHAR(50);
    v_last_name VARCHAR(50);
    v_course_code VARCHAR(20);
    v_course_name VARCHAR(100);
    v_grade DECIMAL(4,2);
BEGIN
    OPEN student_cursor;
    
    LOOP
        FETCH student_cursor INTO v_student_id, v_first_name, v_last_name;
        EXIT WHEN NOT FOUND;
        
        OPEN course_cursor(v_student_id);
        LOOP
            FETCH course_cursor INTO v_course_code, v_course_name, v_grade;
            EXIT WHEN NOT FOUND;
            
            student_name := v_first_name || ' ' || v_last_name;
            course_code := v_course_code;
            course_name := v_course_name;
            grade := v_grade;
            RETURN NEXT;
        END LOOP;
        CLOSE course_cursor;
        
    END LOOP;
    
    CLOSE student_cursor;
END;
$$;

-- Parameterized cursor to filter students by department or course
CREATE OR REPLACE FUNCTION filter_students_by_criteria(
    p_department_id INT DEFAULT NULL,
    p_course_id INT DEFAULT NULL
)
RETURNS TABLE(
    student_id INT,
    student_name VARCHAR(101),
    email VARCHAR(100),
    department_name VARCHAR(100),
    course_name VARCHAR(100)
) 
LANGUAGE plpgsql
AS $$
DECLARE
    student_filter_cursor CURSOR FOR
        SELECT s.student_id, s.first_name, s.last_name, s.email, d.department_name, c.course_name
        FROM students s
        JOIN departments d ON s.department_id = d.department_id
        LEFT JOIN enrollments e ON s.student_id = e.student_id
        LEFT JOIN courses c ON e.course_id = c.course_id
        WHERE (p_department_id IS NULL OR s.department_id = p_department_id)
        AND (p_course_id IS NULL OR e.course_id = p_course_id)
        ORDER BY s.last_name, s.first_name;
BEGIN
    FOR student_record IN student_filter_cursor LOOP
        student_id := student_record.student_id;
        student_name := student_record.first_name || ' ' || student_record.last_name;
        email := student_record.email;
        department_name := student_record.department_name;
        course_name := student_record.course_name;
        RETURN NEXT;
    END LOOP;
END;
$$;

-- Cursor with FOR UPDATE to update student grades (used in a procedure)
CREATE OR REPLACE PROCEDURE update_grades_batch(
    p_course_id INT,
    p_grade_adjustment DECIMAL(4,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    grade_update_cursor CURSOR FOR
        SELECT enrollment_id, grade
        FROM enrollments
        WHERE course_id = p_course_id
        AND grade IS NOT NULL
        FOR UPDATE;
    
    v_enrollment_id INT;
    v_current_grade DECIMAL(4,2);
    v_new_grade DECIMAL(4,2);
BEGIN
    -- Validate grade adjustment
    IF ABS(p_grade_adjustment) > 10 THEN
        RAISE EXCEPTION 'Grade adjustment cannot exceed 10 points';
    END IF;
    
    OPEN grade_update_cursor;
    
    LOOP
        FETCH grade_update_cursor INTO v_enrollment_id, v_current_grade;
        EXIT WHEN NOT FOUND;
        
        -- Calculate new grade
        v_new_grade := v_current_grade + p_grade_adjustment;
        
        -- Ensure grade stays within bounds
        IF v_new_grade > 100 THEN
            v_new_grade := 100;
        ELSIF v_new_grade < 0 THEN
            v_new_grade := 0;
        END IF;
        
        -- Update the grade
        UPDATE enrollments
        SET grade = v_new_grade
        WHERE CURRENT OF grade_update_cursor;
        
        RAISE NOTICE 'Updated enrollment %: % -> %', 
            v_enrollment_id, v_current_grade, v_new_grade;
    END LOOP;
    
    CLOSE grade_update_cursor;
    
    RAISE NOTICE 'Batch grade update completed for course %', p_course_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error in batch grade update: %', SQLERRM;
END;
$$;
-- student_system_additional_procedures.sql

-- Stored procedure that uses a cursor to generate student transcripts
CREATE OR REPLACE PROCEDURE generate_student_transcript(p_student_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
    transcript_cursor CURSOR FOR
        SELECT 
            c.course_code,
            c.course_name,
            c.credits,
            e.grade,
            e.enrollment_date,
            i.first_name || ' ' || i.last_name AS instructor_name
        FROM enrollments e
        JOIN courses c ON e.course_id = c.course_id
        LEFT JOIN instructors i ON c.instructor_id = i.instructor_id
        WHERE e.student_id = p_student_id
        AND e.grade IS NOT NULL
        ORDER BY e.enrollment_date;
    
    v_course_code VARCHAR(20);
    v_course_name VARCHAR(100);
    v_credits INT;
    v_grade DECIMAL(4,2);
    v_enrollment_date DATE;
    v_instructor_name VARCHAR(101);
    v_total_credits INT := 0;
    v_total_points DECIMAL(5,2) := 0;
    v_gpa DECIMAL(3,2);
BEGIN
    -- Check if student exists
    IF NOT EXISTS (SELECT 1 FROM students WHERE student_id = p_student_id) THEN
        RAISE EXCEPTION 'Student with ID % does not exist', p_student_id;
    END IF;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Transcript for Student ID: %', p_student_id;
    RAISE NOTICE 'Generated on: %', CURRENT_DATE;
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    
    OPEN transcript_cursor;
    
    LOOP
        FETCH transcript_cursor INTO 
            v_course_code, v_course_name, v_credits, v_grade, 
            v_enrollment_date, v_instructor_name;
        EXIT WHEN NOT FOUND;
        
        -- Display course information
        RAISE NOTICE 'Course: % - %', v_course_code, v_course_name;
        RAISE NOTICE 'Credits: %, Grade: %, Semester: %', 
            v_credits, v_grade, TO_CHAR(v_enrollment_date, 'YYYY-MM');
        RAISE NOTICE 'Instructor: %', v_instructor_name;
        RAISE NOTICE '---';
        
        -- Calculate for GPA
        v_total_credits := v_total_credits + v_credits;
        IF v_grade >= 90 THEN
            v_total_points := v_total_points + (4.0 * v_credits);
        ELSIF v_grade >= 80 THEN
            v_total_points := v_total_points + (3.0 * v_credits);
        ELSIF v_grade >= 70 THEN
            v_total_points := v_total_points + (2.0 * v_credits);
        ELSIF v_grade >= 60 THEN
            v_total_points := v_total_points + (1.0 * v_credits);
        END IF;
    END LOOP;
    
    CLOSE transcript_cursor;
    
    -- Calculate and display GPA
    IF v_total_credits > 0 THEN
        v_gpa := v_total_points / v_total_credits;
        RAISE NOTICE 'Total Credits: %', v_total_credits;
        RAISE NOTICE 'GPA: %', ROUND(v_gpa, 2);
    ELSE
        RAISE NOTICE 'No completed courses found.';
    END IF;
    
    RAISE NOTICE '========================================';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error generating transcript: %', SQLERRM;
END;
$$;

-- Function returning a computed value: Student standing based on GPA
CREATE OR REPLACE FUNCTION get_student_standing(p_student_id INT)
RETURNS VARCHAR(20)
LANGUAGE plpgsql
AS $$
DECLARE
    v_gpa DECIMAL(3,2);
    v_standing VARCHAR(20);
BEGIN
    -- Get student's GPA
    v_gpa := calculate_student_gpa(p_student_id);
    
    -- Determine standing based on GPA
    CASE
        WHEN v_gpa >= 3.5 THEN v_standing := 'Dean''s List';
        WHEN v_gpa >= 3.0 THEN v_standing := 'Good Standing';
        WHEN v_gpa >= 2.0 THEN v_standing := 'Satisfactory';
        WHEN v_gpa >= 1.0 THEN v_standing := 'Academic Warning';
        ELSE v_standing := 'Academic Probation';
    END CASE;
    
    RETURN v_standing;
END;
$$;
