CREATE OR REPLACE VIEW estimate_factors_analyses_categorized_for_add AS
  SELECT
    m.estimate_type,
    m.category,
    m.surveytype,
    m.analysis_name,
    m.analysis_year,
    m.completion_year,
    ct.name as continent,
    r.name as region,
    c.name as country,
    m.site_name,
    m.best_estimate,
    m.population_estimate,
    m.population_variance,
    m.population_lower_confidence_limit,
    m.population_upper_confidence_limit,
    m.actually_seen,
    m.input_zone_id,
    m.population_submission_id,
    m.stratum_name,
    m.stratum_area,
    m.age,
    m.replacement_name,
    m.reason_change,
    m.citation,
    m.short_citation,
    m.population_standard_error,
    m.population_confidence_interval,
    m.lcl95,
    m.quality_level
  FROM (
    SELECT e.estimate_type,
      e.category,
      st.surveytype,
      e.analysis_name,
      e.analysis_year,
      e.completion_year,
      e.site_name,
      e.population_estimate as best_estimate,
      e.population_estimate,
      0 AS population_variance,
      0 AS population_lower_confidence_limit,
      0 AS population_upper_confidence_limit,
      e.actually_seen,
      e.input_zone_id,
      e.population_submission_id,
      e.stratum_name,
      e.stratum_area,
      e.age,
      e.replacement_name,
      e.reason_change,
      e.citation,
      e.short_citation,
      e.population_confidence_interval,
      e.population_standard_error,
      e.lcl95,
      e.quality_level
    FROM estimate_factors_analyses_categorized e
    JOIN surveytypes st ON e.category = st.category
    WHERE e.category = 'A'
   UNION
    SELECT e.estimate_type,
      e.category,
      st.surveytype,
      e.analysis_name,
      e.analysis_year,
      e.completion_year,
      e.site_name,
      CASE
        WHEN e.population_estimate IS NULL OR e.population_estimate = 0 THEN e.actually_seen
        ELSE e.population_estimate
      END AS best_estimate,
      e.population_estimate,
      e.population_variance,
      0 AS population_lower_confidence_limit,
      0 AS population_upper_confidence_limit,
      e.actually_seen,
      e.input_zone_id,
      e.population_submission_id,
      e.stratum_name,
      e.stratum_area,
      e.age,
      e.replacement_name,
      e.reason_change,
      e.citation,
      e.short_citation,
      e.population_confidence_interval,
      e.population_standard_error,
      e.lcl95,
      e.quality_level
    FROM estimate_factors_analyses_categorized e
    JOIN surveytypes st ON e.category = st.category
    WHERE e.category = 'B'
   UNION
    SELECT e.estimate_type,
      e.category,
      st.surveytype,
      e.analysis_name,
      e.analysis_year,
      e.completion_year,
      e.site_name,
      e.actually_seen as best_estimate,
      e.population_estimate,
      0 AS population_variance,
      e.population_lower_confidence_limit,
      e.population_upper_confidence_limit,
      e.actually_seen,
      e.input_zone_id,
      e.population_submission_id,
      e.stratum_name,
      e.stratum_area,
      e.age,
      e.replacement_name,
      e.reason_change,
      e.citation,
      e.short_citation,
      e.population_confidence_interval,
      e.population_standard_error,
      e.lcl95,
      e.quality_level
    FROM estimate_factors_analyses_categorized e
    JOIN surveytypes st ON e.category = st.category
    WHERE e.category = 'C'
   UNION
    SELECT e.estimate_type,
      e.category,
      st.surveytype,
      e.analysis_name,
      e.analysis_year,
      e.completion_year,
      e.site_name,
      e.population_estimate as best_estimate,
      e.population_estimate,
      0 AS population_variance,
      CASE
        WHEN e.population_lower_confidence_limit IS NULL OR e.population_upper_confidence_limit IS NULL OR (e.population_lower_confidence_limit = 0 AND e.population_upper_confidence_limit = 0) THEN e.population_estimate
        ELSE e.population_lower_confidence_limit
      END AS population_lower_confidence_limit,
      CASE
        WHEN e.population_lower_confidence_limit IS NULL OR e.population_upper_confidence_limit IS NULL OR (e.population_lower_confidence_limit = 0 AND e.population_upper_confidence_limit = 0) THEN e.population_estimate
        ELSE e.population_upper_confidence_limit
      END AS population_upper_confidence_limit,
      e.actually_seen,
      e.input_zone_id,
      e.population_submission_id,
      e.stratum_name,
      e.stratum_area,
      e.age,
      e.replacement_name,
      e.reason_change,
      e.citation,
      e.short_citation,
      e.population_confidence_interval,
      e.population_standard_error,
      e.lcl95,
      e.quality_level
    FROM estimate_factors_analyses_categorized e
    JOIN surveytypes st ON e.category = st.category
    WHERE e.category = 'D' AND e.site_name <> 'Rest of Gabon'
   UNION
    SELECT e.estimate_type,
      e.category,
      st.surveytype,
      e.analysis_name,
      e.analysis_year,
      e.completion_year,
      e.site_name,
      0 as best_estimate,
      0 as population_estimate,
      0 as population_variance,
      CASE
        WHEN e.population_lower_confidence_limit IS NULL OR e.population_upper_confidence_limit IS NULL OR (e.population_lower_confidence_limit = 0 AND e.population_upper_confidence_limit = 0) THEN e.population_estimate
        ELSE e.population_lower_confidence_limit
      END AS population_lower_confidence_limit,
      CASE
        WHEN e.population_lower_confidence_limit IS NULL OR e.population_upper_confidence_limit IS NULL OR (e.population_lower_confidence_limit = 0 AND e.population_upper_confidence_limit = 0) THEN e.population_estimate
        ELSE e.population_upper_confidence_limit
      END AS population_upper_confidence_limit,
      0 as actually_seen,
      e.input_zone_id,
      e.population_submission_id,
      e.stratum_name,
      e.stratum_area,
      e.age,
      e.replacement_name,
      e.reason_change,
      e.citation,
      e.short_citation,
      e.population_confidence_interval,
      e.population_standard_error,
      e.lcl95,
      e.quality_level
    FROM estimate_factors_analyses_categorized e
    JOIN surveytypes st ON e.category = st.category
    WHERE e.category = 'E' AND e.completion_year > e.analysis_year - 10
   UNION
    SELECT e.estimate_type,
      'F' AS category,
      'Degraded Data' AS surveytype,
      e.analysis_name,
      e.analysis_year,
      e.completion_year,
      e.site_name,
      0 AS best_estimate,
      e.population_estimate,
      0 as population_variance,
      e.population_estimate AS population_lower_confidence_limit,
      e.population_estimate AS population_upper_confidence_limit,
      e.actually_seen,
      e.input_zone_id,
      e.population_submission_id,
      e.stratum_name,
      e.stratum_area,
      e.age,
      e.replacement_name,
      e.reason_change,
      e.citation,
      e.short_citation,
      e.population_confidence_interval,
      e.population_standard_error,
      e.lcl95,
      e.quality_level
    FROM estimate_factors_analyses_categorized e
    WHERE e.category = 'E' AND e.completion_year <= e.analysis_year - 10
   UNION
    SELECT e.estimate_type,
      'G' as category,
      'Modeled Extrapolation' as surveytype,
      e.analysis_name,
      e.analysis_year,
      e.completion_year,
      e.site_name,
      0 as best_estimate,
      e.population_estimate,
      0 as population_variance,
      e.population_estimate AS population_lower_confidence_limit,
      e.population_estimate AS population_upper_confidence_limit,
      e.actually_seen,
      e.input_zone_id,
      e.population_submission_id,
      e.stratum_name,
      e.stratum_area,
      e.age,
      e.replacement_name,
      e.reason_change,
      e.citation,
      e.short_citation,
      e.population_confidence_interval,
      e.population_standard_error,
      e.lcl95,
      e.quality_level
    FROM estimate_factors_analyses_categorized e
    WHERE e.category = 'D' AND e.site_name = 'Rest of Gabon'
  ) m
  JOIN population_submissions ps ON ps.id = m.population_submission_id
  JOIN submissions s ON ps.submission_id = s.id
  JOIN countries c ON s.country_id = c.id
  JOIN regions r ON c.region_id = r.id
  JOIN continents ct ON r.continent_id = ct.id;

