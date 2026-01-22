# Student Records Management System

A full-featured student records application with PostgreSQL backend, interactive Python CLI, CRUD operations, reporting (CSV/PDF), and cloud deployment on Render.

## Project Overview

This project is a complete student records management system built as part of a Data Engineering learning path. It includes:

- Database schema (students, courses, enrollments, grades, attendance)
- Realistic sample data generation (ETL scripts)
- Interactive CLI for CRUD operations
- GPA calculation, attendance percentage, and academic risk reporting
- CSV and PDF report generation
- Cloud deployment on Render (PostgreSQL free tier)
- Secure connection using environment variables

## Features

- **CRUD Operations** via CLI:
  - Add new students
  - Enroll students in courses
  - Record grades
  - Mark attendance (Present/Absent/Late/Excused)
- **Analytics & Reports**:
  - Student GPA calculation (weighted by credits)
  - Attendance percentage per student
  - Academic risk summary (low GPA / low attendance)
  - Export GPA report to CSV
  - Export risk summary to PDF (using ReportLab)
- **Data Generation** (ETL):
  - Scripts to populate realistic sample data
- **Deployment**:
  - PostgreSQL hosted on Render
  - CLI connects to cloud database securely

## Tech Stack

- **Database**: PostgreSQL (deployed on Render free tier)
- **Backend/CLI**: Python 3
  - `psycopg2` — PostgreSQL driver
  - `tabulate` — beautiful terminal tables
  - `reportlab` — PDF generation
  - `python-dotenv` — environment variables
  - `csv` — CSV export

## Entity-Relationship Diagram

![ERD Diagram](ERD.png)

## Project Structure

```plaintext
student-records-management/
├── data_scripts/                    # ETL pipeline scripts
│   ├── load_data.py
│   ├── load_courses.py
│   ├── load_enrollments.py
│   ├── load_grades.py
│   └── load_attendance.py
├── student_cli.py                   # Main CLI application
├── erd.png
├── .env.example                     # Template (copy your .env but remove real password)
├── .gitignore
├── requirements.txt
├── README.md
└── docs/                           
    ├── schema.sql                   # Full SQL schema + functions + views                      
    └── sample_data.csv              
```

## Prerequisites

- Python 3.8+
- PostgreSQL client tools (`psql`, `pg_dump`) — used for migration
- Git (for version control)

## Local Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/YOURUSERNAME/student-records-management.git
   cd student-records-management
   ```

2. **Install dependencies**

   ```bash
   pip install -r requirements.txt
   ```

   (If `requirements.txt` is missing, create it with:)

   ```bash
   pip install psycopg2-binary tabulate reportlab python-dotenv
   pip freeze > requirements.txt
   ```

3. **Set up environment variables**

   Copy `.env.example` to `.env`:

   ```bash
   copy .env.example .env
   ```

   Edit `.env` and fill in your **local** or **Render** credentials:

   ```
   DB_HOST=localhost                     # or Render host
   DB_PORT=5432
   DB_NAME=student_records_db
   DB_USER=student_admin
   DB_PASSWORD=your_password_here
   ```

4. **Run the CLI**

   ```bash
   python student_cli.py
   ```

   You should see:

   ```
   Connected to database successfully!
   ```

   Then use the menu (1–6) to interact.

## Cloud Deployment (Render PostgreSQL)

1. Deployed PostgreSQL database:
   - Platform: Render (free tier)
   - Service name: student-records-db
   - Status: Available (green)
   - Connection string: `postgres://student_admin:...@dpg-d5oc8pemcj7s73aoqpo0-a.oregon-postgres.render.com:5432/student_records_db`

2. Data migration:
   - Used `pg_dump` from local → `psql` restore to Render
   - Verified: 623 students, all tables present

3. CLI connects to cloud DB:
   - Uses `.env` file (never committed)
   - All CRUD and reporting operations work remotely

## Running ETL Scripts (Data Generation)

To populate or refresh data:

```bash
cd data_scripts
python load_data.py          # Students
python load_courses.py       # Courses
python load_enrollments.py   # Enrollments
python load_grades.py        # Grades
python load_attendance.py    # Attendance
```

**Note**: `load_attendance.py` currently produces a reduced dataset (~5,579 rows) after earlier cleanup of invalid future dates.

## Limitations & Notes

- Free Render PostgreSQL expires Feb 20, 2026 — upgrade or recreate for long-term use
- Attendance table reduced during data quality cleanup (future dates removed)
- No authentication in CLI (educational project only)

## Future Improvements

- Add user authentication
- Web frontend (e.g. Flask/Streamlit)
- Automated ETL with Airflow or cron
- Backup & recovery strategy

## License

MIT License (or your preferred license)

---

Made with ❤️ as part of Data Engineering learning path  
Last updated: January 2026
