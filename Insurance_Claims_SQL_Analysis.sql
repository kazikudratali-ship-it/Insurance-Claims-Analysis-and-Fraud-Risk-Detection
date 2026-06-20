

-- Insurance Claims Analysis & Fraud Risk Detection
-- Table Name: InsuranceData

-- 1. View data
SELECT *
FROM InsuranceData;

-- 2. Total number of claims
SELECT COUNT(*) AS Total_Claims
FROM InsuranceData;

-- 3. Total claim amount
SELECT 
    SUM(ClaimAmount) AS Total_Claim_Amount,
    AVG(ClaimAmount) AS Average_Claim_Amount,
    MIN(ClaimAmount) AS Minimum_Claim_Amount,
    MAX(ClaimAmount) AS Maximum_Claim_Amount
FROM InsuranceData;

-- 4. Claim status distribution
SELECT 
    ClaimStatus,
    COUNT(*) AS Total_Claims,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS Claim_Percentage
FROM InsuranceData
GROUP BY ClaimStatus
ORDER BY Total_Claims DESC;

-- 5. Claim amount by policy type
SELECT 
    PolicyType,
    COUNT(*) AS Total_Claims,
    SUM(ClaimAmount) AS Total_Claim_Amount,
    AVG(ClaimAmount) AS Average_Claim_Amount
FROM InsuranceData
GROUP BY PolicyType
ORDER BY Total_Claim_Amount DESC;

-- 6. Average premium and coverage amount by policy type
SELECT 
    PolicyType,
    AVG(PremiumAmount) AS Average_Premium_Amount,
    AVG(CoverageAmount) AS Average_Coverage_Amount
FROM InsuranceData
GROUP BY PolicyType
ORDER BY Average_Coverage_Amount DESC;

-- 7. Claims by gender
SELECT 
    Gender,
    COUNT(*) AS Total_Claims,
    SUM(ClaimAmount) AS Total_Claim_Amount,
    AVG(ClaimAmount) AS Average_Claim_Amount
FROM InsuranceData
GROUP BY Gender;

-- 8. Claims by age group
SELECT
    CASE
        WHEN Age <= 25 THEN '18-25'
        WHEN Age <= 35 THEN '26-35'
        WHEN Age <= 45 THEN '36-45'
        WHEN Age <= 55 THEN '46-55'
        ELSE '55+'
    END AS Age_Group,
    COUNT(*) AS Total_Claims,
    SUM(ClaimAmount) AS Total_Claim_Amount,
    AVG(ClaimAmount) AS Average_Claim_Amount
FROM InsuranceData
GROUP BY
    CASE
        WHEN Age <= 25 THEN '18-25'
        WHEN Age <= 35 THEN '26-35'
        WHEN Age <= 45 THEN '36-45'
        WHEN Age <= 55 THEN '46-55'
        ELSE '55+'
    END
ORDER BY Total_Claims DESC;

-- 9. Claim status by policy type
SELECT 
    PolicyType,
    ClaimStatus,
    COUNT(*) AS Total_Claims
FROM InsuranceData
GROUP BY PolicyType, ClaimStatus
ORDER BY PolicyType, Total_Claims DESC;

-- 10. Top 20 highest claims
SELECT TOP 20
    ClaimNumber,
    CustomerID,
    PolicyType,
    PremiumAmount,
    CoverageAmount,
    ClaimAmount,
    ClaimStatus
FROM InsuranceData
ORDER BY ClaimAmount DESC;

-- 11. Claim-to-coverage ratio
SELECT
    ClaimNumber,
    CustomerID,
    PolicyType,
    ClaimAmount,
    CoverageAmount,
    ROUND(ClaimAmount * 100.0 / NULLIF(CoverageAmount, 0), 2) AS Claim_Coverage_Ratio_Percent
FROM InsuranceData
ORDER BY Claim_Coverage_Ratio_Percent DESC;

-- 12. Average claim-to-coverage ratio by policy type
SELECT
    PolicyType,
    ROUND(AVG(ClaimAmount * 100.0 / NULLIF(CoverageAmount, 0)), 2) AS Avg_Claim_Coverage_Ratio_Percent
FROM InsuranceData
WHERE ClaimAmount > 0
GROUP BY PolicyType
ORDER BY Avg_Claim_Coverage_Ratio_Percent DESC;

-- 13. Claims filed within 30 days of policy start
SELECT
    ClaimNumber,
    CustomerID,
    PolicyType,
    TRY_CONVERT(date, PolicyStartDate) AS PolicyStartDate,
    TRY_CONVERT(date, ClaimDate) AS ClaimDate,
    DATEDIFF(
        DAY,
        TRY_CONVERT(date, PolicyStartDate),
        TRY_CONVERT(date, ClaimDate)
    ) AS Days_To_Claim
FROM InsuranceData
WHERE
    TRY_CONVERT(date, PolicyStartDate) IS NOT NULL
    AND TRY_CONVERT(date, ClaimDate) IS NOT NULL
    AND DATEDIFF(
        DAY,
        TRY_CONVERT(date, PolicyStartDate),
        TRY_CONVERT(date, ClaimDate)
    ) <= 30
ORDER BY Days_To_Claim;

-- 14. Claim timing categories

WITH CleanDates AS (
    SELECT
        *,
        TRY_CONVERT(date, PolicyStartDate, 101) AS Policy_Start_Date,
        TRY_CONVERT(date, ClaimDate, 101) AS Claim_Date
    FROM InsuranceData
)
SELECT
    CASE
        WHEN Claim_Date IS NULL THEN 'No Claim Date'
        WHEN DATEDIFF(DAY, Policy_Start_Date, Claim_Date) <= 30 THEN 'Within 30 Days'
        WHEN DATEDIFF(DAY, Policy_Start_Date, Claim_Date) <= 90 THEN '31-90 Days'
        WHEN DATEDIFF(DAY, Policy_Start_Date, Claim_Date) <= 180 THEN '91-180 Days'
        ELSE '180+ Days'
    END AS Claim_Timing,
    COUNT(*) AS Total_Claims
FROM CleanDates
WHERE Policy_Start_Date IS NOT NULL
GROUP BY
    CASE
        WHEN Claim_Date IS NULL THEN 'No Claim Date'
        WHEN DATEDIFF(DAY, Policy_Start_Date, Claim_Date) <= 30 THEN 'Within 30 Days'
        WHEN DATEDIFF(DAY, Policy_Start_Date, Claim_Date) <= 90 THEN '31-90 Days'
        WHEN DATEDIFF(DAY, Policy_Start_Date, Claim_Date) <= 180 THEN '91-180 Days'
        ELSE '180+ Days'
    END
ORDER BY Total_Claims DESC;

-- 15. Suspicious claims
WITH CleanDates AS (
    SELECT
        ClaimNumber,
        CustomerID,
        PolicyType,
        PremiumAmount,
        CoverageAmount,
        ClaimAmount,
        ClaimStatus,
        TRY_CONVERT(date, PolicyStartDate, 101) AS Policy_Start_Date,
        TRY_CONVERT(date, ClaimDate, 101) AS Claim_Date
    FROM InsuranceData
)
SELECT
    ClaimNumber,
    CustomerID,
    PolicyType,
    PremiumAmount,
    CoverageAmount,
    ClaimAmount,
    ClaimStatus,
    Policy_Start_Date,
    Claim_Date,
    DATEDIFF(DAY, Policy_Start_Date, Claim_Date) AS Days_To_Claim,
    ROUND(ClaimAmount * 100.0 / NULLIF(CoverageAmount, 0), 2) AS Claim_Coverage_Ratio_Percent
FROM CleanDates
WHERE
    Policy_Start_Date IS NOT NULL
    AND (
        ClaimAmount * 1.0 / NULLIF(CoverageAmount, 0) >= 0.8
        OR (
            Claim_Date IS NOT NULL
            AND DATEDIFF(DAY, Policy_Start_Date, Claim_Date) <= 30
        )
    )
ORDER BY ClaimAmount DESC;

