# 🎬 Sakila Movie Rental — Data Warehouse Design

> **Course:** Data Warehousing / Data Architecture  
> **Topic:** From OLTP Schema to Dimensional Model and ETL Design  
> **Source Database:**```
https://drive.google.com/file/d/1UxR65upm350BBJkEODJQ3h2LQKGrw5-L/view
```

---

## 📁 Repository Structure

```
sakila-data-warehouse/
├── 01_sakila_dw_structure.sql    ← Step 1: Creates the star schema (DDL only, no data)
├── 02_sakila_etl.ipynb           ← Step 2: Python ETL — Extract → Transform → Load
├── 03_business_analysis.ipynb   ← Step 3: 15 business questions with tables + charts
├── Assignment_Report.docx        ← Full assignment report (Word document)
└── README.md                     ← This file
```

---

## 🗄️ Data Warehouse Overview

### Schema: Star Schema

**3 Fact Tables:**

| Fact Table | Grain | Key Measures |
|---|---|---|
| `fact_rental` | One row per rental transaction | duration, overdue days, rental rate |
| `fact_payment` | One row per payment | amount paid |
| `fact_inventory_snapshot` | Film × Store × Date | copies available, copies rented out |

**7 Dimension Tables + 1 Bridge:**

| Dimension | Source OLTP Tables | Purpose |
|---|---|---|
| `dim_date` | Generated | All time-based analysis |
| `dim_customer` | customer, address, city, country | Customer behavior (SCD Type 2) |
| `dim_film` | film, language | Film performance |
| `dim_category` | category | Genre analysis |
| `dim_store` | store, staff, address, city, country | Store performance |
| `dim_staff` | staff | Staff productivity |
| `dim_actor` | actor | Actor-film analysis |
| `bridge_film_actor` | film_actor | Film ↔ Actor many-to-many |

---

## 🚀 How to Run

### Prerequisites
- MySQL 8.0 with Sakila database loaded
- Python 3.11+ with Anaconda
- VS Code or Jupyter Notebook

### Step 1 — Create the Star Schema
```sql
-- Run in MySQL Workbench
SOURCE 01_sakila_dw_structure.sql;
```

### Step 2 — Run the ETL Pipeline
```
1. Open 02_sakila_etl.ipynb in VS Code
2. Set your MySQL password in Cell 1:
   PASSWORD = 'your_password'
3. Kernel → Restart & Run All
```

Expected output (final verify cell):
```
dim_date                  :  2191 rows ✓
dim_customer              :   599 rows ✓
dim_film                  :  1000 rows ✓
dim_category              :    16 rows ✓
dim_store                 :     2 rows ✓
dim_staff                 :     2 rows ✓
dim_actor                 :   200 rows ✓
bridge_film_actor         :  5462 rows ✓
fact_rental               : 16044 rows ✓
fact_payment              : 16049 rows ✓
fact_inventory_snapshot   :  varies ✓
```

### Step 3 — Business Analysis
```
1. Open 03_business_analysis.ipynb
2. Set your MySQL password in Cell 0
3. Kernel → Restart & Run All
```

---

## 📊 Business Questions Answered (Step 3)

| # | Question | Chart Type |
|---|---|---|
| Q1 | Which films are rented most frequently? | Horizontal bar |
| Q2 | Which films generate the highest revenue? | Horizontal bar |
| Q3 | Which film categories are most popular? | Pie + bar |
| Q4 | Which stores generate the highest number of rentals? | Vertical bar |
| Q5 | Which stores generate the highest revenue? | Vertical bar |
| Q6 | Which customers rent the most films? | Horizontal bar |
| Q7 | Which customers generate the highest revenue? | Horizontal bar |
| Q8 | How does rental activity change over time? | Line chart |
| Q9 | How does revenue change by month/quarter/year? | 3-panel chart |
| Q10 | Which staff process the most rentals and payments? | Grouped bar |
| Q11 | Which cities/countries have the highest activity? | Dual bar |
| Q12 | What is the average rental duration per category? | Grouped bar |
| Q13 | Which films are returned late most often? | Horizontal bar |
| Q14 | How does store performance differ by location? | 2×2 metric grid |
| Q15 | What are the most active customer locations? | Bar + bubble scatter |

---

## 🔧 ETL Architecture

```
sakila (OLTP)
    │
    ├── EXTRACT ──── pd.read_sql() reads 15 OLTP tables into DataFrames
    │
    ├── TRANSFORM ── Join tables · Clean NULLs · Compute date keys
    │                Compute measures · Resolve surrogate keys
    │                Detect late returns · Handle unreturned films
    │
    └── LOAD ─────── Dimensions first → Bridge → Facts
                     TRUNCATE before reload (safe re-run)
                     Row count assertions after each load
```

---

## 📋 Install Dependencies
```bash
conda activate your_env
conda install -c conda-forge sqlalchemy pymysql -y
pip install pandas numpy matplotlib --trusted-host pypi.org --trusted-host files.pythonhosted.org
```

---

## 📄 Assignment Report

The full written report (`Assignment_Report.docx`) covers:
1. Introduction — OLTP vs Data Warehouse
2. Business Questions — 15 questions with importance explained
3. Dimensional Model Design — fact tables, dimensions, grain, measures
4. Dimensional Model Diagram — star schema structure
5. ETL Design — Extract, Transform, Load explained in detail
6. Data Quality Considerations — 8 data quality rules
7. Conclusion — summary and business value
