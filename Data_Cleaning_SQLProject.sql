--  Using the world_layoffs database
USE world_leyoffs;

--  Checking the raw data
SELECT * FROM layoffs;

--  Data Cleaning Steps
-- 1️ Remove duplicate records
-- 2️ Standardize data (trim spaces, fix inconsistencies)
-- 3 Handle NULL and blank values
-- 4️ Remove unnecessary columns if needed

--  Step 1: Create a staging table to work with
CREATE TABLE layoffs_staging LIKE layoffs;
INSERT INTO layoffs_staging SELECT * FROM layoffs;
SELECT * FROM layoffs_staging;  -- Verify data is copied

--  Step 2: Identifying duplicates using ROW_NUMBER()

WITH duplicate_cte AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
    ) AS row_num
    FROM layoffs_staging
)
SELECT * FROM duplicate_cte WHERE row_num > 1;  -- Display duplicates

--  Step 3: Creating a new table with an additional row_num column
CREATE TABLE layoffs_staging2 (
    company TEXT,
    location TEXT,
    industry TEXT,
    total_laid_off INT DEFAULT NULL,
    percentage_laid_off TEXT,
    `date` TEXT,
    stage TEXT,
    country TEXT,
    funds_raised_millions INT DEFAULT NULL,
    row_num INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 📌 Step 4: Insert data with row numbers into the new table
INSERT INTO layoffs_staging2
SELECT *, ROW_NUMBER() OVER (
    PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
) AS row_num FROM layoffs_staging;

--  Step 5: Deleting duplicate records
DELETE FROM layoffs_staging2 WHERE row_num > 1;

--  Step 6: Standardizing Data (Trimming Spaces)
UPDATE layoffs_staging2 SET company = TRIM(company);

--  Step 7: Fixing Inconsistent Industry Names
UPDATE layoffs_staging2 SET industry = 'Crypto' WHERE industry LIKE 'Crypto%';

--  Step 8: Fixing Country Name Formatting
UPDATE layoffs_staging2 SET country = TRIM(TRAILING '.' FROM country) WHERE country LIKE 'United States.';

--  Step 9: Converting Date Column from Text to DATE Format
UPDATE layoffs_staging2 SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');
ALTER TABLE layoffs_staging2 MODIFY COLUMN `date` DATE;

--  Step 10: Handling NULL and Blank Values in Industry
UPDATE layoffs_staging2 SET industry = NULL WHERE industry = '';
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2 ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;

--  Step 11: Deleting Records with NULL Values in Critical Columns
DELETE FROM layoffs_staging2 WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

--  Step 12: Dropping the row_num column (Cleanup)
ALTER TABLE layoffs_staging2 DROP COLUMN row_num;

-- ✅ Data cleaning completed!
SELECT * FROM layoffs_staging2;  -- Final check
