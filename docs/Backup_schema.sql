--
-- PostgreSQL database dump
--

\restrict spmp07NYLkMVA2jVxXnQncWsctCJBQfeM4GVhouRFhGyjujbAZBuc52vH2ruIXW

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

-- Started on 2026-01-23 15:54:54

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 5 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- TOC entry 5051 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 233 (class 1255 OID 24675)
-- Name: calculate_student_gpa(integer); Type: FUNCTION; Schema: public; Owner: student_admin
--

CREATE FUNCTION public.calculate_student_gpa(p_student_id integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
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
    WHERE e.student_id = p_student_id
    GROUP BY e.student_id;

    IF total_credits = 0 THEN RETURN 0.00; END IF;

    RETURN ROUND(total_points / total_credits, 2);
END;
$$;


ALTER FUNCTION public.calculate_student_gpa(p_student_id integer) OWNER TO student_admin;

--
-- TOC entry 232 (class 1255 OID 24674)
-- Name: get_grade_points(numeric); Type: FUNCTION; Schema: public; Owner: student_admin
--

CREATE FUNCTION public.get_grade_points(score numeric) RETURNS numeric
    LANGUAGE plpgsql
    AS $$    
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
    $$;


ALTER FUNCTION public.get_grade_points(score numeric) OWNER TO student_admin;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 228 (class 1259 OID 24640)
-- Name: attendance; Type: TABLE; Schema: public; Owner: student_admin
--

CREATE TABLE public.attendance (
    attendance_id integer NOT NULL,
    enrollment_id integer NOT NULL,
    attendance_date date NOT NULL,
    status character varying(10),
    notes text,
    CONSTRAINT attendance_status_check CHECK (((status)::text = ANY ((ARRAY['Present'::character varying, 'Absent'::character varying, 'Late'::character varying, 'Excused'::character varying])::text[]))),
    CONSTRAINT chk_attendance_date_future CHECK ((attendance_date <= CURRENT_DATE))
);


ALTER TABLE public.attendance OWNER TO student_admin;

--
-- TOC entry 227 (class 1259 OID 24639)
-- Name: attendance_attendance_id_seq; Type: SEQUENCE; Schema: public; Owner: student_admin
--

CREATE SEQUENCE public.attendance_attendance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.attendance_attendance_id_seq OWNER TO student_admin;

--
-- TOC entry 5053 (class 0 OID 0)
-- Dependencies: 227
-- Name: attendance_attendance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: student_admin
--

ALTER SEQUENCE public.attendance_attendance_id_seq OWNED BY public.attendance.attendance_id;


--
-- TOC entry 222 (class 1259 OID 24592)
-- Name: courses; Type: TABLE; Schema: public; Owner: student_admin
--

CREATE TABLE public.courses (
    course_id integer NOT NULL,
    course_name character varying(100) NOT NULL,
    description text,
    credits integer NOT NULL,
    instructor character varying(100),
    CONSTRAINT courses_credits_check CHECK (((credits >= 1) AND (credits <= 6)))
);


ALTER TABLE public.courses OWNER TO student_admin;

--
-- TOC entry 221 (class 1259 OID 24591)
-- Name: courses_course_id_seq; Type: SEQUENCE; Schema: public; Owner: student_admin
--

CREATE SEQUENCE public.courses_course_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.courses_course_id_seq OWNER TO student_admin;

--
-- TOC entry 5054 (class 0 OID 0)
-- Dependencies: 221
-- Name: courses_course_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: student_admin
--

ALTER SEQUENCE public.courses_course_id_seq OWNED BY public.courses.course_id;


--
-- TOC entry 224 (class 1259 OID 24603)
-- Name: enrollments; Type: TABLE; Schema: public; Owner: student_admin
--

CREATE TABLE public.enrollments (
    enrollment_id integer NOT NULL,
    student_id integer NOT NULL,
    course_id integer NOT NULL,
    enrollment_date date DEFAULT CURRENT_DATE,
    status character varying(20) DEFAULT 'Active'::character varying,
    CONSTRAINT enrollments_status_check CHECK (((status)::text = ANY ((ARRAY['Active'::character varying, 'Dropped'::character varying, 'Completed'::character varying])::text[])))
);


ALTER TABLE public.enrollments OWNER TO student_admin;

--
-- TOC entry 223 (class 1259 OID 24602)
-- Name: enrollments_enrollment_id_seq; Type: SEQUENCE; Schema: public; Owner: student_admin
--

CREATE SEQUENCE public.enrollments_enrollment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.enrollments_enrollment_id_seq OWNER TO student_admin;

--
-- TOC entry 5055 (class 0 OID 0)
-- Dependencies: 223
-- Name: enrollments_enrollment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: student_admin
--

ALTER SEQUENCE public.enrollments_enrollment_id_seq OWNED BY public.enrollments.enrollment_id;


--
-- TOC entry 226 (class 1259 OID 24625)
-- Name: grades; Type: TABLE; Schema: public; Owner: student_admin
--

CREATE TABLE public.grades (
    grade_id integer NOT NULL,
    enrollment_id integer NOT NULL,
    score numeric(5,2),
    assessment_type character varying(50),
    graded_at date DEFAULT CURRENT_DATE,
    CONSTRAINT chk_grade_score_range CHECK (((score >= (0)::numeric) AND (score <= (100)::numeric))),
    CONSTRAINT grades_score_check CHECK (((score >= (0)::numeric) AND (score <= (100)::numeric)))
);


ALTER TABLE public.grades OWNER TO student_admin;

--
-- TOC entry 225 (class 1259 OID 24624)
-- Name: grades_grade_id_seq; Type: SEQUENCE; Schema: public; Owner: student_admin
--

CREATE SEQUENCE public.grades_grade_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.grades_grade_id_seq OWNER TO student_admin;

--
-- TOC entry 5056 (class 0 OID 0)
-- Dependencies: 225
-- Name: grades_grade_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: student_admin
--

ALTER SEQUENCE public.grades_grade_id_seq OWNED BY public.grades.grade_id;


--
-- TOC entry 220 (class 1259 OID 24579)
-- Name: students; Type: TABLE; Schema: public; Owner: student_admin
--

CREATE TABLE public.students (
    student_id integer NOT NULL,
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
    email character varying(100) NOT NULL,
    date_of_birth date DEFAULT '2000-01-01'::date NOT NULL,
    phone_number character varying(20),
    CONSTRAINT chk_dob_reasonable CHECK (((date_of_birth >= '1900-01-01'::date) AND (date_of_birth <= '2010-12-31'::date)))
);


ALTER TABLE public.students OWNER TO student_admin;

--
-- TOC entry 230 (class 1259 OID 24682)
-- Name: student_attendance_summary; Type: VIEW; Schema: public; Owner: student_admin
--

CREATE VIEW public.student_attendance_summary AS
 SELECT s.student_id,
    (((s.first_name)::text || ' '::text) || (s.last_name)::text) AS full_name,
    count(a.attendance_id) AS total_attendance_records,
    sum(
        CASE
            WHEN ((a.status)::text = 'Present'::text) THEN 1
            ELSE 0
        END) AS present_count,
    sum(
        CASE
            WHEN ((a.status)::text = 'Absent'::text) THEN 1
            ELSE 0
        END) AS absent_count,
    sum(
        CASE
            WHEN ((a.status)::text = ANY ((ARRAY['Late'::character varying, 'Excused'::character varying])::text[])) THEN 1
            ELSE 0
        END) AS late_excused_count,
    round(((100.0 * (sum(
        CASE
            WHEN ((a.status)::text = 'Present'::text) THEN 1
            ELSE 0
        END))::numeric) / (count(a.attendance_id))::numeric), 1) AS attendance_percentage,
    round((avg(
        CASE
            WHEN ((a.status)::text = 'Present'::text) THEN 1.0
            ELSE 0.0
        END) * (100)::numeric), 1) AS avg_attendance_pct
   FROM ((public.students s
     JOIN public.enrollments e ON ((s.student_id = e.student_id)))
     JOIN public.attendance a ON ((e.enrollment_id = a.enrollment_id)))
  GROUP BY s.student_id, s.first_name, s.last_name
 HAVING (count(a.attendance_id) > 0)
  ORDER BY (round(((100.0 * (sum(
        CASE
            WHEN ((a.status)::text = 'Present'::text) THEN 1
            ELSE 0
        END))::numeric) / (count(a.attendance_id))::numeric), 1)) DESC NULLS LAST;


ALTER VIEW public.student_attendance_summary OWNER TO student_admin;

--
-- TOC entry 229 (class 1259 OID 24676)
-- Name: student_gpa; Type: VIEW; Schema: public; Owner: student_admin
--

CREATE VIEW public.student_gpa AS
 SELECT s.student_id,
    (((s.first_name)::text || ' '::text) || (s.last_name)::text) AS full_name,
    public.calculate_student_gpa(s.student_id) AS gpa,
    count(DISTINCT e.course_id) AS num_courses_enrolled,
    round(avg(g.score), 1) AS overall_avg_score
   FROM ((public.students s
     LEFT JOIN public.enrollments e ON ((s.student_id = e.student_id)))
     LEFT JOIN public.grades g ON ((e.enrollment_id = g.enrollment_id)))
  GROUP BY s.student_id, s.first_name, s.last_name
  ORDER BY (public.calculate_student_gpa(s.student_id)) DESC NULLS LAST;


ALTER VIEW public.student_gpa OWNER TO student_admin;

--
-- TOC entry 231 (class 1259 OID 24687)
-- Name: student_risk_summary; Type: VIEW; Schema: public; Owner: student_admin
--

CREATE VIEW public.student_risk_summary AS
 WITH ranked AS (
         SELECT sg.full_name,
            sg.gpa,
            sa.attendance_percentage,
                CASE
                    WHEN ((sg.gpa < 2.0) AND (sa.attendance_percentage < (70)::numeric)) THEN 'High Risk (GPA & Attendance)'::text
                    WHEN (sg.gpa < 2.0) THEN 'Academic Risk (Low GPA)'::text
                    WHEN (sa.attendance_percentage < (70)::numeric) THEN 'Attendance Risk'::text
                    ELSE 'Moderate / No Immediate Risk'::text
                END AS risk_level,
            sg.num_courses_enrolled,
            sa.total_attendance_records
           FROM (public.student_gpa sg
             JOIN public.student_attendance_summary sa ON ((sg.student_id = sa.student_id)))
        )
 SELECT full_name,
    gpa,
    attendance_percentage,
    risk_level,
    num_courses_enrolled,
    total_attendance_records
   FROM ranked
  ORDER BY
        CASE risk_level
            WHEN 'High Risk (GPA & Attendance)'::text THEN 1
            WHEN 'Academic Risk (Low GPA)'::text THEN 2
            WHEN 'Attendance Risk'::text THEN 3
            ELSE 4
        END;


ALTER VIEW public.student_risk_summary OWNER TO student_admin;

--
-- TOC entry 219 (class 1259 OID 24578)
-- Name: students_student_id_seq; Type: SEQUENCE; Schema: public; Owner: student_admin
--

CREATE SEQUENCE public.students_student_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.students_student_id_seq OWNER TO student_admin;

--
-- TOC entry 5057 (class 0 OID 0)
-- Dependencies: 219
-- Name: students_student_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: student_admin
--

ALTER SEQUENCE public.students_student_id_seq OWNED BY public.students.student_id;


--
-- TOC entry 4851 (class 2604 OID 24643)
-- Name: attendance attendance_id; Type: DEFAULT; Schema: public; Owner: student_admin
--

ALTER TABLE ONLY public.attendance ALTER COLUMN attendance_id SET DEFAULT nextval('public.attendance_attendance_id_seq'::regclass);


--
-- TOC entry 4845 (class 2604 OID 24595)
-- Name: courses course_id; Type: DEFAULT; Schema: public; Owner: student_admin
--

ALTER TABLE ONLY public.courses ALTER COLUMN course_id SET DEFAULT nextval('public.courses_course_id_seq'::regclass);


--
-- TOC entry 4846 (class 2604 OID 24606)
-- Name: enrollments enrollment_id; Type: DEFAULT; Schema: public; Owner: student_admin
--

ALTER TABLE ONLY public.enrollments ALTER COLUMN enrollment_id SET DEFAULT nextval('public.enrollments_enrollment_id_seq'::regclass);


--
-- TOC entry 4849 (class 2604 OID 24628)
-- Name: grades grade_id; Type: DEFAULT; Schema: public; Owner: student_admin
--

ALTER TABLE ONLY public.grades ALTER COLUMN grade_id SET DEFAULT nextval('public.grades_grade_id_seq'::regclass);


--
-- TOC entry 4843 (class 2604 OID 24582)
-- Name: students student_id; Type: DEFAULT; Schema: public; Owner: student_admin
--

ALTER TABLE ONLY public.students ALTER COLUMN student_id SET DEFAULT nextval('public.students_student_id_seq'::regclass);


--
-- TOC entry 4879 (class 2606 OID 24649)
-- Name: attendance attendance_pkey; Type: CONSTRAINT; Schema: public; Owner: student_admin
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_pkey PRIMARY KEY (attendance_id);


--
-- TOC entry 4865 (class 2606 OID 24601)
-- Name: courses courses_course_name_key; Type: CONSTRAINT; Schema: public; Owner: student_admin
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_course_name_key UNIQUE (course_name);


--
-- TOC entry 4867 (class 2606 OID 24599)
-- Name: courses courses_pkey; Type: CONSTRAINT; Schema: public; Owner: student_admin
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_pkey PRIMARY KEY (course_id);


--
-- TOC entry 4869 (class 2606 OID 24611)
-- Name: enrollments enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: student_admin
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT enrollments_pkey PRIMARY KEY (enrollment_id);


--
-- TOC entry 4871 (class 2606 OID 24613)
-- Name: enrollments enrollments_student_id_course_id_key; Type: CONSTRAINT; Schema: public; Owner: student_admin
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT enrollments_student_id_course_id_key UNIQUE (student_id, course_id);


--
-- TOC entry 4877 (class 2606 OID 24633)
-- Name: grades grades_pkey; Type: CONSTRAINT; Schema: public; Owner: student_admin
--

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT grades_pkey PRIMARY KEY (grade_id);


--
-- TOC entry 4861 (class 2606 OID 24590)
-- Name: students students_email_key; Type: CONSTRAINT; Schema: public; Owner: student_admin
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_email_key UNIQUE (email);


--
-- TOC entry 4863 (class 2606 OID 24588)
-- Name: students students_pkey; Type: CONSTRAINT; Schema: public; Owner: student_admin
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_pkey PRIMARY KEY (student_id);


--
-- TOC entry 4881 (class 2606 OID 24671)
-- Name: attendance unique_attendance_per_day; Type: CONSTRAINT; Schema: public; Owner: student_admin
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT unique_attendance_per_day UNIQUE (enrollment_id, attendance_date);


--
-- TOC entry 4875 (class 2606 OID 24696)
-- Name: enrollments unique_student_course; Type: CONSTRAINT; Schema: public; Owner: student_admin
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT unique_student_course UNIQUE (student_id, course_id);


--
-- TOC entry 4872 (class 1259 OID 24657)
-- Name: idx_enrollments_course; Type: INDEX; Schema: public; Owner: student_admin
--

CREATE INDEX idx_enrollments_course ON public.enrollments USING btree (course_id);


--
-- TOC entry 4873 (class 1259 OID 24656)
-- Name: idx_enrollments_student; Type: INDEX; Schema: public; Owner: student_admin
--

CREATE INDEX idx_enrollments_student ON public.enrollments USING btree (student_id);


--
-- TOC entry 4859 (class 1259 OID 24655)
-- Name: idx_students_email; Type: INDEX; Schema: public; Owner: student_admin
--

CREATE INDEX idx_students_email ON public.students USING btree (email);


--
-- TOC entry 4885 (class 2606 OID 24650)
-- Name: attendance attendance_enrollment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: student_admin
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_enrollment_id_fkey FOREIGN KEY (enrollment_id) REFERENCES public.enrollments(enrollment_id);


--
-- TOC entry 4882 (class 2606 OID 24619)
-- Name: enrollments enrollments_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: student_admin
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT enrollments_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(course_id);


--
-- TOC entry 4883 (class 2606 OID 24614)
-- Name: enrollments enrollments_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: student_admin
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT enrollments_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(student_id);


--
-- TOC entry 4884 (class 2606 OID 24634)
-- Name: grades grades_enrollment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: student_admin
--

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT grades_enrollment_id_fkey FOREIGN KEY (enrollment_id) REFERENCES public.enrollments(enrollment_id);


--
-- TOC entry 5052 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO student_admin;


-- Completed on 2026-01-23 15:54:55

--
-- PostgreSQL database dump complete
--

\unrestrict spmp07NYLkMVA2jVxXnQncWsctCJBQfeM4GVhouRFhGyjujbAZBuc52vH2ruIXW

