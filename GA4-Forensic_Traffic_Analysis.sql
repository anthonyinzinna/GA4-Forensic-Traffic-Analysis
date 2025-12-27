SELECT
  *,
  -- FINAL IDENTITY LOGIC
  CASE 
    -- 1. DEVELOPER TRAFFIC (The "Ghost" Filter)
    -- Logic: Matches specific Geo + Device combo AND (High Frequency OR Zero-Time testing)
    WHEN (
       (city IN ('Brandon', 'Flowood', 'Ridgeland') AND operating_system IN ('Macintosh', 'iOS')) 
       AND (total_sessions > 5 OR avg_seconds_on_site < 5)
    ) THEN 'Developer (Self-Traffic)'

    -- 2. TECHNICAL LEADS (High Value)
    -- Logic: Source contains 'github' -> Likely code reviewers
    WHEN acquisition_source LIKE '%github%' THEN 'Technical Visitor (GitHub)'

    -- 3. SOCIAL LEADS (High Value)
    -- Logic: Source contains 'linkedin' or 't.co' -> Likely recruiters/hiring managers
    WHEN acquisition_source LIKE '%linkedin%' OR acquisition_source LIKE '%t.co%' THEN 'Social Visitor (LinkedIn/X)'

    -- 4. LOCAL NETWORK (High Engagement)
    -- Logic: Local geo but HIGH engagement (>30s) -> Likely real local network, not testing
    WHEN (
       (city IN ('Brandon', 'Flowood', 'Ridgeland') AND operating_system IN ('Macintosh', 'iOS'))
       AND avg_seconds_on_site > 30
    ) THEN 'Local Visitor (Direct)'

    -- 5. GLOBAL TRAFFIC
    ELSE 'Real User (Global)'
  END as user_label

FROM (
  -- INNER QUERY: Session Aggregation & Unnesting
  SELECT
    user_pseudo_id,
    MAX(TIMESTAMP_MICROS(event_timestamp)) as last_active_timestamp,
    
    geo.city,
    device.operating_system,
    
    -- TRAFFIC SOURCE RESOLUTION
    -- Uses windowing logic to attribute the session to its first source
    MAX(traffic_source.source) as acquisition_source,
    
    -- ENGAGEMENT METRICS
    -- 1. Count Unique Session IDs (Deduping)
    COUNT(DISTINCT CONCAT(user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'))) as total_sessions,

    -- 2. Sum Engagement Time (Scanning all events, not just page_view)
    IFNULL(SUM((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec')), 0) / 1000 as total_seconds_on_site,
    
    -- 3. Calculate Average Session Duration
    (IFNULL(SUM((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec')), 0) / 1000) 
    / NULLIF(COUNT(DISTINCT CONCAT(user_pseudo_id, (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id'))), 0) as avg_seconds_on_site

  FROM `<your-gcp-project-id>.analytics_<ga4_property_id>.events_*` 
  GROUP BY 1, 3, 4
)
