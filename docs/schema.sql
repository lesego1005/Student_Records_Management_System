-- =============================================================================
-- Student Records Management System - Database Schema
-- =============================================================================
-- Generated for IBM Data Engineering Project Submission
-- Author: Lesego
-- Date: January 2026
-- PostgreSQL Version: 16+
-- =============================================================================

-- Enable extensions (if needed for advanced features)
CREATE EXTENSION IF NOT EXISTS plpgsql;

-- =============================================================================
-- 1. Tables
-- =============================================================================

CREATE TABLE IF NOT EXISTS students (
    student_id      SERIAL PRIMARY KEY,
    first_name      VARCHAR(50) NOT NULL,
    last_name       VARCHAR(50) NOT NULL,
    email           VARCHAR(100) UNIQUE NOT NULL,
    date_of_birth   DATE NOT NULL,
    -- phone_number VARCHAR(20),  -- commented out as it was removed earlier
    CONSTRAINT chk_dob_reasonable 
        CHECK (date_of_birth BETWEEN '1900-01-01' AND '2010-12-31')
);

CREATE TABLE IF NOT EXISTS courses (
    course_id       SERIAL PRIMARY KEY,
    course_name     VARCHAR(100) NOT NULL UNIQUE,
    credits         INTEGER NOT NULL CHECK (credits > 0),
    instructor      VARCHAR(100),
    description     TEXT
);

CREATE TABLE IF NOT EXISTS enrollments (
    enrollment_id    SERIAL PRIMARY KEY,
    student_id       INTEGER NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    course_id        INTEGER NOT NULL REFERENCES courses(course_id) ON DELETE CASCADE,
    enrollment_date  DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT unique_student_course UNIQUE (student_id, course_id)
);

CREATE TABLE IF NOT EXISTS grades (
    grade_id         SERIAL PRIMARY KEY,
    enrollment_id    INTEGER NOT NULL REFERENCES enrollments(enrollment_id) ON DELETE CASCADE,
    assessment_type  VARCHAR(50) NOT NULL,
    score            DECIMAL(5,2) NOT NULL CHECK (score BETWEEN 0 AND 100),
    graded_at        DATE DEFAULT CURRENT_DATE
);

CREATE TABLE IF NOT EXISTS attendance (
    attendance_id    SERIAL PRIMARY KEY,
    enrollment_id    INTEGER NOT NULL REFERENCES enrollments(enrollment_id) ON DELETE CASCADE,
    attendance_date  DATE NOT NULL,
    status           VARCHAR(10) NOT NULL CHECK (status IN ('Present', 'Absent', 'Late', 'Excused')),
    notes            TEXT,
    CONSTRAINT unique_enrollment_date UNIQUE (enrollment_id, attendance_date),
    CONSTRAINT chk_attendance_date_reasonable 
        CHECK (attendance_date <= CURRENT_DATE)
);

-- =============================================================================
-- 2. Indexes (for performance)
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_enrollments_student_id ON enrollments(student_id);
CREATE INDEX IF NOT EXISTS idx_grades_enrollment_id ON grades(enrollment_id);
CREATE INDEX IF NOT EXISTS idx_attendance_enrollment_id ON attendance(enrollment_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(attendance_date);

-- =============================================================================
-- 3. Stored Functions
-- =============================================================================

CREATE OR REPLACE FUNCTION get_grade_points(score DECIMAL)
RETURNS DECIMAL AS $$
BEGIN
    RETURN CASE
        WHEN score >= 75 THEN 4.0
        WHEN score >= 70 THEN 3.7
        WHEN score >= 65 THEN 3.0
        WHEN score >= 60 THEN 2.7
        WHEN score >= 50 THEN 2.0
        ELSE 0.0
    END;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calculate_student_gpa(p_student_id INT)
RETURNS DECIMAL(4,2) AS $$
DECLARE
    total_points  DECIMAL := 0;
    total_credits INT     := 0;
BEGIN
    SELECT 
        COALESCE(SUM(get_grade_points(g.score) * c.credits), 0),
        COALESCE(SUM(c.credits), 0)
    INTO total_points, total_credits
    FROM enrollments e
    JOIN courses c ON e.course_id = c.course_id
    JOIN grades g ON e.enrollment_id = g.enrollment_id
    WHERE e.student_id = p_student_id;

    IF total_credits = 0 THEN RETURN 0.00; END IF;

    RETURN ROUND(total_points / total_credits, 2);
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- 4. Views
-- =============================================================================

CREATE OR REPLACE VIEW student_gpa AS
SELECT 
    s.student_id,
    s.first_name || ' ' || s.last_name AS full_name,
    calculate_student_gpa(s.student_id) AS gpa,
    COUNT(DISTINCT e.course_id) AS num_courses_enrolled,
    ROUND(AVG(g.score), 1) AS overall_avg_score
FROM students s
LEFT JOIN enrollments e ON s.student_id = e.student_id
LEFT JOIN grades g ON e.enrollment_id = g.enrollment_id
GROUP BY s.student_id, s.first_name, s.last_name
ORDER BY gpa DESC NULLS LAST;

CREATE OR REPLACE VIEW student_attendance_summary AS
SELECT 
    s.student_id,
    s.first_name || ' ' || s.last_name AS full_name,
    COUNT(a.attendance_id) AS total_attendance_records,
    SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) AS present_count,
    ROUND(100.0 * SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) / COUNT(a.attendance_id), 1) AS attendance_percentage
FROM students s
JOIN enrollments e ON s.student_id = e.student_id
JOIN attendance a ON e.enrollment_id = a.enrollment_id
GROUP BY s.student_id, s.first_name, s.last_name
HAVING COUNT(a.attendance_id) > 0
ORDER BY attendance_percentage DESC NULLS LAST;

CREATE OR REPLACE VIEW student_risk_summary AS
WITH ranked AS (
    SELECT 
        sg.full_name,
        sg.gpa,
        sa.attendance_percentage,
        CASE 
            WHEN sg.gpa < 2.0 AND sa.attendance_percentage < 70 THEN 'High Risk (GPA & Attendance)'
            WHEN sg.gpa < 2.0 THEN 'Academic Risk (Low GPA)'
            WHEN sa.attendance_percentage < 70 THEN 'Attendance Risk'
            ELSE 'Moderate / No Immediate Risk'
        END AS risk_level,
        sg.num_courses_enrolled,
        sa.total_attendance_records
    FROM student_gpa sg
    JOIN student_attendance_summary sa ON sg.student_id = sa.student_id
)
SELECT *
FROM ranked
ORDER BY 
    CASE risk_level
        WHEN 'High Risk (GPA & Attendance)' THEN 1
        WHEN 'Academic Risk (Low GPA)'      THEN 2
        WHEN 'Attendance Risk'              THEN 3
        ELSE 4
    END;