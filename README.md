# 🚀 Week 7 Assignment: Daily ETL Pipeline (Date-Stamped File Ingestion & Transformation)



## 📋 Project Overview

This project demonstrates a robust, automated ETL solution using **Azure Data Factory (ADF)** designed to handle a common data engineering challenge: ingesting daily files where critical metadata is embedded within the filename.

The pipeline automatically discovers, transforms, and loads multiple types of date-stamped CSV files from an Azure Data Lake into a structured Azure SQL Database, making the data ready for analytics and reporting.

> 🔗 **Thanks to [CSI (Celebal Summer Internship)](https://www.celebaltech.com/)**  
> This task deepened my understanding of cloud-scale data pipelines, showcasing real-world techniques and design considerations.

---

## 🎯 Problem Statement

This project addresses the challenge of building a fully automated ETL pipeline to process daily data feeds delivered as CSV files. The core requirements are to extract critical date information embedded in the filenames, apply unique transformation rules for different file types, handle and eliminate duplicate records to ensure data integrity, and implement a daily truncate-and-load pattern into a structured SQL database.

The specific processing logic is summarized below:

| File Type           | Filename Pattern                 | Required Logic                                | Target Table        |
|---------------------|----------------------------------|-----------------------------------------------|---------------------|
| Customer Master     | `CUST_MSTR_YYYYMMDD.csv`         | Add `Date` column from filename.              | `dbo.CUST_MSTR`     |
| Master-Child Data   | `master_child_export-YYYYMMDD.csv` | Add `Date` & `DateKey` columns from filename. | `dbo.master_child`  |
| E-commerce Orders   | `H_ECOM_ORDER_*.csv`             | Deduplicate by `OrderID` and load data.       | `dbo.H_ECOM_Orders` |

This project implements a solution in Azure Data Factory to solve all of these challenges in a scalable, efficient, and reliable manner.

---

## 🛠️ Technologies Used

- **Orchestration & ETL:** Azure Data Factory (ADF)
- **Data Storage:** Azure Data Lake Storage Gen2
- **Data Warehouse:** Azure SQL Database
- **Core ADF Components:** Mapping Data Flows, Pipelines, Copy Data Activity
- **Automation:** Schedule Triggers
- **Monitoring:** Azure Monitor

*Resource group*
<p align="center">
  <img src="./Screenshots/Resource group.png" width="600"/>
</p>

 *Linked services*
<p align="center">
  <img src="./Screenshots/Linked services.png" width="600"/>
</p>

 *Datasets*
<p align="center">
  <img src="./Screenshots/Factory Resources.png" width="400"/>
</p>


## 🔧 Data Factory as Code

The full configuration of the Azure Data Factory pipelines, datasets, and triggers is available as an ARM template in the /arm_template folder, demonstrating Infrastructure as Code (IaC) principles.

---

## 📂 Project Tasks & Implementation

### 1️⃣ Dynamic Ingestion of Date-Stamped CSV Files 📂📅

**Objective:** Build resilient Data Flows capable of processing all files of a specific type from a source folder, regardless of how many files are present.

#### Steps:
- **Created three distinct Data Flows**, one for each file type (`CUST_MSTR`, `master_child_export`, `H_ECOM_ORDER`).
- Each Data Flow's **Source** was configured with a **Wildcard Path** (e.g., `CUST_MSTR_*.csv`) to dynamically read all matching files in a single operation.
- The `Column to store file name` feature was enabled to capture the filename for transformation.

📸 **Evidence:**

- ✅ `DF_Load_CUST_MSTR` Data Flow.

  ![CUST_MSTR Data Flow Preview](https://github.com/Ayush03A/Celebal-DE-Internship-WEEK-7/blob/74d786aacfd8d4b2f0dbac9a352a1e02cbcbc9d5/Screenshots/Data%20Flow%20CUST%20MSTR.png)
  
- ✅ `DF_Load_CUST_MSTR` Data Flow successfully previews data from the source.

  ![CUST_MSTR Data Flow Preview](https://github.com/Ayush03A/Celebal-DE-Internship-WEEK-7/blob/34eaa698cc671df8689dca070d11e9953638ea30/Screenshots/Data%20Flow%20successfully%20previews%20data%20from%20the%20source.png)

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

- ✅ `DF_Load_CUST_MSTR` Data Flow successfully creates `Date` column.

  <!-- TODO: Replace with your screenshot link -->
  ![master_child Data Flow with new columns](https://github.com/Ayush03A/Celebal-DE-Internship-WEEK-7/blob/34eaa698cc671df8689dca070d11e9953638ea30/Screenshots/Data%20Flow%20CUST%20MSTR%20Dated.png)

- ✅ `DF_Load_master_child` successfully creates both `Date` and `DateKey` columns.

  <!-- TODO: Replace with your screenshot link -->
  ![master_child Data Flow with new columns](https://github.com/Ayush03A/Celebal-DE-Internship-WEEK-7/blob/34eaa698cc671df8689dca070d11e9953638ea30/Screenshots/DF_Load_master_child%20successfully%20creates%20both%20Date%20and%20DateKey%20columns.png)

- ✅ `H_ECOM_ORDER` Data Flow using Aggregate to ensure unique OrderIDs.

  <!-- TODO: Replace with your screenshot link -->
  ![H_ECOM_ORDER Aggregate transformation](https://github.com/Ayush03A/Celebal-DE-Internship-WEEK-7/blob/34eaa698cc671df8689dca070d11e9953638ea30/Screenshots/H_ECOM_ORDER%20Data%20Flow%20using%20Aggregate%20to%20ensure%20unique%20OrderIDs..png)

---

### 3️⃣ Automated Truncate-and-Load Pattern 🔄

**Objective:** Implement a daily full-refresh pattern by automatically clearing the destination tables before loading the new day's data.

#### Implementation:
- **For Data Flows (`CUST_MSTR`, `master_child`):**
  - The **Sink** transformation was configured with the **Table action: Truncate table**. This is the most efficient method within a Data Flow.
- **For `H_ECOM_ORDER` Load:**
  - A dedicated **Script Activity** (`DELETE FROM dbo.H_ECOM_Orders;`) was placed in the pipeline *before* the Data Flow to explicitly handle the data clearing, resolving a primary key violation issue during debugging.

📸 **Evidence:**

- ✅ Data successfully loaded and verified in Azure SQL Database.

  <!-- TODO: Replace with your screenshot link -->
  ![SQL Table Verification](https://github.com/Ayush03A/Celebal-DE-Internship-WEEK-7/blob/34eaa698cc671df8689dca070d11e9953638ea30/Screenshots/SQL%20Databse%20CUST_MSTR%20Table%20.png)


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
  ![Final Sequential Pipeline](https://github.com/Ayush03A/Celebal-DE-Internship-WEEK-7/blob/34eaa698cc671df8689dca070d11e9953638ea30/Screenshots/master%20pipeline%20in%20the%20ADF%20canvas.png)
  
- ✅ Successful pipeline run monitored in the ADF "Output" tab.

  <!-- TODO: Replace with your screenshot link -->
  ![Successful Pipeline Run](https://github.com/Ayush03A/Celebal-DE-Internship-WEEK-7/blob/34eaa698cc671df8689dca070d11e9953638ea30/Screenshots/Final%20sequential%20pipeline%20showing%20the%20DELETE%20script%20activity%20for%20H_ECOM_Orders.png)

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

### 💡 Next Logical Steps

To make this solution even more robust and manageable for production, the next steps would be:

1.  **Performance Optimization (Parallel Execution):** Modify the pipeline to run all three data loads simultaneously, as they are independent. This would significantly reduce the total pipeline run time.
2.  **Advanced Error Handling:** Implement a pattern to catch and log problematic rows or files into a separate "quarantine" location instead of failing the entire pipeline.
3.  **CI/CD Implementation:** Integrate the ADF project with **Azure DevOps** or **GitHub Actions** to automate deployment across different environments (Dev, Test, Prod), enabling a professional software development lifecycle.
4.  **Parameterization for Reusability:** Convert hard-coded values (like folder paths and file prefixes) into pipeline parameters to create a generic, reusable data loading framework.


## 🙏 Acknowledgements

Huge thanks to my amazing mentors and HR team for constant guidance and feedback throughout this journey:

👨‍🏫 **Jash Tewani & Anurag Yadav** – Technical Mentor  
🙌 **Prerna Kamat** – HR, Celebal CSI  
🙌 **Priyanshi Jain** – HR, Celebal CSI  
🏢 **Celebal Technologies** – For this amazing real-world data engineering internship

