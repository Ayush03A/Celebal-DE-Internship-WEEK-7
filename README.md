# 🚀 Week 7 Assignment: Daily ETL Pipeline (Date-Stamped File Ingestion & Transformation)



## 📋 Project Overview

This project demonstrates a robust, automated ETL solution using **Azure Data Factory (ADF)** designed to handle a common data engineering challenge: ingesting daily files where critical metadata is embedded within the filename.

The pipeline automatically discovers, transforms, and loads multiple types of date-stamped CSV files from an Azure Data Lake into a structured Azure SQL Database, making the data ready for analytics and reporting.

> 🔗 **Thanks to [CSI (Celebal Summer Internship)](https://www.celebaltech.com/)**  
> This task deepened my understanding of cloud-scale data pipelines, showcasing real-world techniques and design considerations.

---

## 🎯 Problem Statement

A business receives multiple data feeds daily from various source systems, delivered as CSV files into an Azure Data Lake. Each file contains valuable data, but also presents several challenges:

1.  **Embedded Metadata:** Critical information, such as the reporting date for the data, is not present as a column within the files. Instead, it is part of the filename itself.
2.  **Multiple File Types:** There are different types of files, each with its own unique file naming convention and data enrichment requirements.
3.  **Data Integrity Issues:** Source systems may produce duplicate records across different files, which can violate database constraints.
4.  **Daily Refresh Requirement:** The target analytical tables must be completely refreshed each day following a "truncate and load" pattern.
5.  **Automation and Reliability:** The entire process must be fully automated and resilient.

The specific requirements for each file type are summarized below:

| File Type / Data Source   | Source Filename Pattern                  | Required Transformations / Logic                                                                               | Target SQL Table       |
| ------------------------- | ---------------------------------------- | -------------------------------------------------------------------------------------------------------------- | ---------------------- |
| **Customer Master**       | `CUST_MSTR_YYYYMMDD.csv`                 | Extract date from filename and add a new **`Date`** column (format: `YYYY-MM-DD`).                             | `dbo.CUST_MSTR`        |
| **Master-Child Data**     | `master_child_export-YYYYMMDD.csv`       | Extract date from filename and add two new columns: **`Date`** (`YYYY-MM-DD`) and **`DateKey`** (`YYYYMMDD`).   | `dbo.master_child`     |
| **E-commerce Orders**     | `H_ECOM_ORDER_*.csv`                     | Load data as-is, but **remove duplicate records** based on `OrderID` to ensure primary key integrity.          | `dbo.H_ECOM_Orders`    |

This project implements a solution in Azure Data Factory to solve all of these challenges in a scalable, efficient, and reliable manner.

---

## 🛠️ Technologies Used

- **Orchestration & ETL:** Azure Data Factory (ADF)
- **Data Storage:** Azure Data Lake Storage Gen2
- **Data Warehouse:** Azure SQL Database
- **Core ADF Components:** Mapping Data Flows, Pipelines, Copy Data Activity
- **Automation:** Schedule Triggers
- **Monitoring:** Azure Monitor

---

## 📂 Project Tasks & Implementation

### 1️⃣ Dynamic Ingestion of Date-Stamped CSV Files 📂📅

**Objective:** Build resilient Data Flows capable of processing all files of a specific type from a source folder, regardless of how many files are present.

#### Steps:
- **Created three distinct Data Flows**, one for each file type (`CUST_MSTR`, `master_child_export`, `H_ECOM_ORDER`).
- Each Data Flow's **Source** was configured with a **Wildcard Path** (e.g., `CUST_MSTR_*.csv`) to dynamically read all matching files in a single operation.
- The `Column to store file name` feature was enabled to capture the filename for transformation.

📸 **Evidence:**

- ✅ `DF_Load_CUST_MSTR` Data Flow successfully previews data from the source.

  <!-- TODO: Replace with your screenshot link -->
  ![CUST_MSTR Data Flow Preview](https://github.com/your-username/your-repo/blob/main/screenshots/cust_mstr_dataflow_preview.png)

---

### 2️⃣ Metadata Extraction & Data Transformation ✨

**Objective:** Parse the captured filename to enrich the data with new, structured columns (`Date` and `DateKey`).

#### Implementation:
- **For `CUST_MSTR` files:**
  - A `Derived Column` transformation was used with the expression `toDate(replace(replace(SourceFileName, 'CUST_MSTR_', ''), '.csv', ''), 'yyyyMMdd')` to create a `Date` column.
- **For `master_child_export` files:**
  - A `Derived Column` transformation created two new columns:
    - `DateKey` (Integer): `toInteger(replace(replace(SourceFileName, 'master_child_export-', ''), '.csv', ''))`
    - `Date` (Date): `toDate(replace(replace(SourceFileName, 'master_child_export-', ''), '.csv', ''), 'yyyyMMdd')`
- **For `H_ECOM_ORDER` files (Data Integrity):**
  - An `Aggregate` transformation was used to group by `OrderID` and take the `first()` of all other columns, effectively removing any duplicate records before loading.

📸 **Evidence:**

- ✅ `DF_Load_master_child` successfully creates both `Date` and `DateKey` columns.

  <!-- TODO: Replace with your screenshot link -->
  ![master_child Data Flow with new columns](https://github.com/your-username/your-repo/blob/main/screenshots/master_child_derived_columns.png)

- ✅ `H_ECOM_ORDER` Data Flow using Aggregate to ensure unique OrderIDs.

  <!-- TODO: Replace with your screenshot link -->
  ![H_ECOM_ORDER Aggregate transformation](https://github.com/your-username/your-repo/blob/main/screenshots/hecom_aggregate.png)

---

### 3️⃣ Automated Truncate-and-Load Pattern 🔄

**Objective:** Implement a daily full-refresh pattern by automatically clearing the destination tables before loading the new day's data.

#### Implementation:
- **For Data Flows (`CUST_MSTR`, `master_child`):**
  - The **Sink** transformation was configured with the **Table action: Truncate table**. This is the most efficient method within a Data Flow.
- **For `H_ECOM_ORDER` Load:**
  - A dedicated **Script Activity** (`DELETE FROM dbo.H_ECOM_Orders;`) was placed in the pipeline *before* the Data Flow to explicitly handle the data clearing, resolving a primary key violation issue during debugging.

📸 **Evidence:**

- ✅ Final sequential pipeline showing the `DELETE` script activity for `H_ECOM_Orders`.

  <!-- TODO: Replace with your screenshot link -->
  ![Pipeline with Delete Script](https://github.com/your-username/your-repo/blob/main/screenshots/pipeline_with_delete_script.png)

- ✅ Data successfully loaded and verified in Azure SQL Database.

  <!-- TODO: Replace with your screenshot link -->
  ![SQL Table Verification](https://github.com/your-username/your-repo/blob/main/screenshots/sql_table_result.png)


---

### 4️⃣ Pipeline Orchestration and Automation ⚙️

**Objective:** Assemble all processing steps into a single, reliable master pipeline that runs automatically.

#### Implementation:
- A master pipeline (`PL_Load_All_Daily_Files_Sequentially`) was created to run the three data loading processes in sequence.
- **On Success** precedence constraints (the green arrows) ensure that the `master_child` load only starts after `CUST_MSTR` succeeds, and so on.
- A **Schedule Trigger** was configured to run the entire pipeline automatically every day.
- **Monitoring & Alerting** was set up using Azure Monitor to send an email notification upon any pipeline failure.

📸 **Evidence:**

- ✅ The complete sequential master pipeline in the ADF canvas.

  <!-- TODO: Replace with your screenshot link -->
  ![Final Sequential Pipeline](https://github.com/your-username/your-repo/blob/main/screenshots/final_pipeline_view.png)
  
- ✅ Successful pipeline run monitored in the ADF "Output" tab.

  <!-- TODO: Replace with your screenshot link -->
  ![Successful Pipeline Run](https://github.com/your-username/your-repo/blob/main/screenshots/successful_pipeline_run.png)

---

## ✅ Summary Table

| Task                                          | Status   |
| --------------------------------------------- | -------- |
| Dynamic Ingestion with Wildcard Paths         | ✅ Done  |
| Metadata Extraction from Filename             | ✅ Done  |
| Duplicate Record Handling                     | ✅ Done  |
| Automated Truncate-and-Load                   | ✅ Done  |
| Sequential Pipeline Orchestration             | ✅ Done  |
| Daily Automation via Schedule Trigger         | ✅ Done  |
| Failure Alerting with Azure Monitor           | ✅ Done  |

---

## ❗ Challenges Faced & Debugging Journey

- **Initial `BadRequest` Errors:** Encountered generic `BadRequest` errors during Data Flow preview, which were resolved by restarting the **Data Flow Debug cluster** that had timed out.
- **Path Does Not Resolve:** The initial `source1` configuration failed because the Dataset path was incorrect. This was fixed by creating a new, clean dataset pointing to the correct container (`raw`) and directory (`CUST_MSTR`).
- **Primary Key Violation:** The `H_ECOM_Orders` load repeatedly failed with a "Cannot insert duplicate key" error.
  - **Debugging:** We proved the `TRUNCATE` command was succeeding by checking the row count in SQL. This confirmed the issue was with the incoming data having duplicates across files.
  - **Solution:** Replaced the `Copy Data` activity with a **Data Flow** using an **Aggregate transformation** to ensure only unique `OrderID`s are passed to the sink, permanently solving the problem.

---

## 🧠 Key Learnings & Next Steps

This project provided deep, hands-on experience in building a real-world ETL solution. Key takeaways include:

- **The Importance of Debugging:** Mastered the use of **Data Preview** to isolate issues at each step of a Data Flow, from source connectivity to transformations.
- **Robust Pipeline Design:** Understood the trade-offs between different pipeline patterns (Wildcard vs. `ForEach` loop).
- **Data Integrity:** Learned to proactively handle potential data quality issues like duplicates using transformations like `Aggregate`.
- **Problem Solving:** Successfully navigated common ADF issues like debug session timeouts and path resolution errors.

### Next Logical Steps

To make this solution even more robust and manageable for production, the next steps would be:

1.  **Performance Optimization (Parallel Execution):** Modify the pipeline to run all three data loads simultaneously, as they are independent. This would significantly reduce the total pipeline run time.
2.  **Advanced Error Handling:** Implement a pattern to catch and log problematic rows or files into a separate "quarantine" location instead of failing the entire pipeline.
3.  **CI/CD Implementation:** Integrate the ADF project with **Azure DevOps** or **GitHub Actions** to automate deployment across different environments (Dev, Test, Prod), enabling a professional software development lifecycle.
4.  **Parameterization for Reusability:** Convert hard-coded values (like folder paths and file prefixes) into pipeline parameters to create a generic, reusable data loading framework.
