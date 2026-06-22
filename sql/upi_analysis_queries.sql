
-- ================================================================
-- UPI Payment Intelligence — SQL Analysis Queries
-- Database: upi_intelligence (PostgreSQL)
-- Author: Miraj Rajendra Patil
-- ================================================================
-- Business Questions Answered:
-- Q1: Fraud profile — city tier, device, app, user segment
-- Q2: Merchant category performance — volume and value
-- Q3: Spending behavior — age groups and city tiers
-- Q4: Transaction failure drivers and operational cost
-- Q5: High value transaction risk profile
-- ================================================================



-- ================================================================
-- BUSINESS QUESTION 1: FRAUD PROFILE ANALYSIS
-- ================================================================


-- Which city tier has the highest concentration of fraud?
SELECT 
    user_city_tier,
    COUNT(*) AS total_transactions,
    SUM(is_fraud) AS total_fraud,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2) AS fraud_rate_pct
FROM transactions
GROUP BY user_city_tier
ORDER BY fraud_rate_pct DESC;


-- Which payment app has the highest fraud rate?
SELECT 
    payment_app,
    COUNT(*) AS total_transactions,
    SUM(is_fraud) AS total_fraud,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2) AS fraud_rate_pct
FROM transactions
GROUP BY payment_app
ORDER BY fraud_rate_pct DESC;


-- Which device type is most associated with fraud?
SELECT 
    device_type,
    COUNT(*) AS total_transactions,
    SUM(is_fraud) AS total_fraud,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2) AS fraud_rate_pct
FROM transactions
GROUP BY device_type
ORDER BY fraud_rate_pct DESC;


-- Do unverified KYC users show higher fraud rates?
SELECT 
    user_kyc_status,
    SUM(is_fraud) AS total_fraud,
    COUNT(*) AS total_transactions,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2) AS fraud_rate_pct
FROM transactions
GROUP BY user_kyc_status
ORDER BY fraud_rate_pct DESC;


-- ================================================================
-- BUSINESS QUESTION 2: MERCHANT CATEGORY PERFORMANCE
-- ================================================================

-- Which merchant categories drive highest transaction volume and value?
SELECT 
    m.merchant_category,
    COUNT(t.transaction_id) AS total_transactions,
    ROUND(SUM(t.amount)::numeric, 2) AS total_value_inr,
    ROUND(AVG(t.amount)::numeric, 2) AS avg_transaction_value,
    ROUND(COUNT(t.transaction_id) * 100.0 / SUM(COUNT(t.transaction_id)) OVER(), 2) AS volume_share_pct
FROM transactions t
JOIN merchants m ON t.receiver_id = m.merchant_id
GROUP BY m.merchant_category
ORDER BY total_value_inr DESC;


-- Which merchant categories have highest fraud risk?
SELECT 
    m.merchant_category,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(t.is_fraud) AS total_fraud,
    ROUND(SUM(t.is_fraud) * 100.0 / COUNT(t.transaction_id), 2) AS fraud_rate_pct
FROM transactions t
JOIN merchants m ON t.receiver_id = m.merchant_id
GROUP BY m.merchant_category
ORDER BY fraud_rate_pct DESC;



-- ================================================================
-- BUSINESS QUESTION 3: SPENDING BEHAVIOR ACROSS AGE GROUPS AND CITY TIERS
-- ================================================================

-- Which age group transacts most and spends highest amount?
SELECT 
    u.age_group,
    COUNT(t.transaction_id) AS total_transactions,
    ROUND(SUM(t.amount)::numeric, 2) AS total_spend_inr,
    ROUND(AVG(t.amount)::numeric, 2) AS avg_transaction_value,
    ROUND((SUM(t.amount) * 100.0 / SUM(SUM(t.amount)) OVER())::numeric, 2) AS spend_share_pct
FROM transactions t
JOIN users u ON t.user_id = u.user_id
GROUP BY u.age_group
ORDER BY total_spend_inr DESC;



-- Which city tier generates highest transaction volume and value?
SELECT 
    u.city_tier,
    COUNT(t.transaction_id) AS total_transactions,
    ROUND(SUM(t.amount)::numeric, 2) AS total_spend_inr,
    ROUND(AVG(t.amount)::numeric, 2) AS avg_transaction_value,
    ROUND((SUM(t.amount) * 100.0 / SUM(SUM(t.amount)) OVER())::numeric, 2) AS spend_share_pct
FROM transactions t
JOIN users u ON t.user_id = u.user_id
GROUP BY u.city_tier
ORDER BY total_spend_inr DESC;



-- ================================================================
-- BUSINESS QUESTION 4: TRANSACTION FAILURE ANALYSIS
-- ================================================================

-- What is the overall transaction success and failure rate?
SELECT 
    status,
    COUNT(*) AS total_transactions,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()::numeric, 2) AS percentage
FROM transactions
GROUP BY status
ORDER BY total_transactions DESC;


-- Which payment app has the highest failure rate?
SELECT 
    payment_app,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN status = 'Failed' THEN 1 ELSE 0 END) AS failed_transactions,
    ROUND(SUM(CASE WHEN status = 'Failed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)::numeric, 2) AS failure_rate_pct
FROM transactions
GROUP BY payment_app
ORDER BY failure_rate_pct DESC;


-- At what hours do transaction failures peak?
WITH hourly_stats AS (
    SELECT 
        hour_of_day,
        COUNT(*) AS total_transactions,
        SUM(CASE WHEN status = 'Failed' THEN 1 ELSE 0 END) AS failed_transactions
    FROM transactions
    GROUP BY hour_of_day
)
SELECT 
    hour_of_day,
    total_transactions,
    failed_transactions,
    ROUND(failed_transactions * 100.0 / total_transactions::numeric, 2) AS failure_rate_pct
FROM hourly_stats
ORDER BY failure_rate_pct DESC
LIMIT 10;


-- ================================================================
-- BUSINESS QUESTION 5: HIGH VALUE TRANSACTION RISK PROFILE
-- ================================================================

-- What percentage of transactions are high value and what is their fraud rate?
WITH high_value AS (
    SELECT *,
        CASE WHEN amount > 5000 THEN 'High Value' ELSE 'Regular' END AS transaction_category
    FROM transactions
)
SELECT 
    transaction_category,
    COUNT(*) AS total_transactions,
    ROUND(AVG(amount)::numeric, 2) AS avg_amount,
    SUM(is_fraud) AS total_fraud,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*)::numeric, 2) AS fraud_rate_pct,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()::numeric, 2) AS volume_share_pct
FROM high_value
GROUP BY transaction_category
ORDER BY avg_amount DESC;


-- Which fraud signals fire most on high value fraudulent transactions?
WITH high_value_fraud AS (
    SELECT 
        t.transaction_id,
        t.amount,
        t.new_device_flag,
        t.ip_location_mismatch,
        t.failed_attempts_last_24h,
        t.transaction_velocity,
        t.is_fraud,
        t.user_city_tier,
        t.payment_app
    FROM transactions t
    WHERE t.amount > 5000 AND t.is_fraud = 1
)
SELECT 
    SUM(new_device_flag) AS new_device_count,
    SUM(ip_location_mismatch) AS ip_mismatch_count,
    ROUND(AVG(failed_attempts_last_24h)::numeric, 2) AS avg_failed_attempts,
    ROUND(AVG(transaction_velocity)::numeric, 2) AS avg_transaction_velocity,
    COUNT(*) AS total_high_value_frauds,
    ROUND(SUM(new_device_flag) * 100.0 / COUNT(*)::numeric, 2) AS new_device_pct,
    ROUND(SUM(ip_location_mismatch) * 100.0 / COUNT(*)::numeric, 2) AS ip_mismatch_pct
FROM high_value_fraud;


-- Rank high value transactions by composite risk score
WITH risk_scored AS (
    SELECT 
        transaction_id,
        amount,
        payment_app,
        user_city_tier,
        new_device_flag,
        ip_location_mismatch,
        failed_attempts_last_24h,
        is_fraud,
        (new_device_flag * 3 + 
         ip_location_mismatch * 3 + 
         CASE WHEN failed_attempts_last_24h > 2 THEN 2 ELSE failed_attempts_last_24h END +
         CASE WHEN transaction_velocity > 2 THEN 2 ELSE 0 END) AS risk_score
    FROM transactions
    WHERE amount > 5000
)
SELECT 
    transaction_id,
    amount,
    payment_app,
    user_city_tier,
    risk_score,
    is_fraud,
    RANK() OVER (ORDER BY risk_score DESC) AS risk_rank,
    CASE 
        WHEN risk_score >= 6 THEN 'High Risk'
        WHEN risk_score >= 3 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM risk_scored
ORDER BY risk_score DESC
LIMIT 15;


