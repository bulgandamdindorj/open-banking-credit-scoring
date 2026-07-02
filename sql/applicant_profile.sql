-- ============================================================
-- Thin-File Credit Scoring: SQL exploration
-- Classifies borrowers by bureau history and explores how
-- payment behaviour relates to default within each group.
-- Built and run in DBeaver.
-- ============================================================


-- ------------------------------------------------------------
-- 1. Overall default rate in the dataset.
-- ------------------------------------------------------------
SELECT
    TARGET,
    COUNT(*) AS total,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS percentage
FROM application_train
GROUP BY TARGET;


-- ------------------------------------------------------------
-- 2. Classify applicants by bureau history and show the
--    default rate for each group.
--      No bureau history   -> no record in the bureau table
--      Thin file (1 entry) -> 1 bureau record
--      Has bureau history  -> 2 or more bureau records
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN b.SK_ID_CURR IS NULL THEN 'No bureau history'
        WHEN bureau_count <= 1    THEN 'Thin file (1 entry)'
        ELSE                           'Has bureau history'
    END AS profile,
    COUNT(*) AS total_applicants,
    ROUND(AVG(a.TARGET) * 100, 1) AS default_rate_pct
FROM application_train a
LEFT JOIN (
    SELECT SK_ID_CURR, COUNT(*) AS bureau_count
    FROM bureau
    GROUP BY SK_ID_CURR
) b ON a.SK_ID_CURR = b.SK_ID_CURR
GROUP BY profile
ORDER BY total_applicants DESC;


-- ------------------------------------------------------------
-- 3. Default rate by payment behaviour (all applicants).
--    A payment counts as on time if entered on or before the
--    scheduled date, allowing a 7 day grace window.
--    pct_on_time is the share of an applicant's payments on time.
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN pct_on_time >= 0.95 THEN '1. Almost always on time (95%+)'
        WHEN pct_on_time >= 0.80 THEN '2. Mostly on time (80-95%)'
        WHEN pct_on_time >= 0.60 THEN '3. Sometimes late (60-80%)'
        ELSE                          '4. Often late (under 60%)'
    END AS payment_behaviour,
    COUNT(DISTINCT a.SK_ID_CURR) AS total_applicants,
    ROUND(AVG(a.TARGET) * 100, 1) AS default_rate_pct
FROM application_train a
JOIN (
    SELECT
        SK_ID_CURR,
        AVG(CASE WHEN DAYS_ENTRY_PAYMENT <= DAYS_INSTALMENT + 7
                 THEN 1.0 ELSE 0.0 END) AS pct_on_time
    FROM installments_payments
    GROUP BY SK_ID_CURR
) p ON a.SK_ID_CURR = p.SK_ID_CURR
GROUP BY payment_behaviour
ORDER BY payment_behaviour;


-- ------------------------------------------------------------
-- 4. Save the classification as a view for reuse.
-- ------------------------------------------------------------
CREATE VIEW applicant_profile AS
SELECT
    a.SK_ID_CURR,
    a.TARGET,
    CASE
        WHEN b.SK_ID_CURR IS NULL THEN 'No bureau history'
        WHEN bureau_count <= 1    THEN 'Thin file (1 entry)'
        ELSE                           'Has bureau history'
    END AS profile
FROM application_train a
LEFT JOIN (
    SELECT SK_ID_CURR, COUNT(*) AS bureau_count
    FROM bureau
    GROUP BY SK_ID_CURR
) b ON a.SK_ID_CURR = b.SK_ID_CURR;


-- ------------------------------------------------------------
-- 5. The key check: does the payment behaviour pattern hold
--    inside the thin-file and no-bureau group specifically?
--    This is the population the project is about.
-- ------------------------------------------------------------
SELECT
    ap.profile,
    CASE
        WHEN pct_on_time >= 0.95 THEN '1. Almost always on time (95%+)'
        WHEN pct_on_time >= 0.80 THEN '2. Mostly on time (80-95%)'
        WHEN pct_on_time >= 0.60 THEN '3. Sometimes late (60-80%)'
        ELSE                          '4. Often late (under 60%)'
    END AS payment_behaviour,
    COUNT(DISTINCT ap.SK_ID_CURR) AS total_applicants,
    ROUND(AVG(ap.TARGET) * 100, 1) AS default_rate_pct
FROM applicant_profile ap
JOIN (
    SELECT
        SK_ID_CURR,
        AVG(CASE WHEN DAYS_ENTRY_PAYMENT <= DAYS_INSTALMENT + 7
                 THEN 1.0 ELSE 0.0 END) AS pct_on_time
    FROM installments_payments
    GROUP BY SK_ID_CURR
) p ON ap.SK_ID_CURR = p.SK_ID_CURR
WHERE ap.profile IN ('No bureau history', 'Thin file (1 entry)')
GROUP BY ap.profile, payment_behaviour
ORDER BY ap.profile, payment_behaviour;
