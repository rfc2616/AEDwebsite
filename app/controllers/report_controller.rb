class ReportController < ApplicationController
  include AltDppsHelper
  include DppsContinentHelper
  include DppsRegionHelper
  include DppsCountryHelper
  include TotalizerHelper
  include DppsContinentPreviousHelper
  include DppsRegionPreviousHelper
  include DppsCountryPreviousHelper

  before_filter :set_past_years

  def execute(*array)
    sql = ActiveRecord::Base.send(:sanitize_sql_array, array)
    return ActiveRecord::Base.connection.execute(sql)
  end

  def references
    @references = execute <<-SQL
      SELECT *
      FROM aed2007."References"
      order by "Authors"
    SQL
  end

  def set_past_years
    @past_years = ['2007', '2002', '1998', '1995']
  end

  def species
    @past_reports = [
      { year: '2007', full_text: '033', authors: 'J.J. Blanc, R.F.W. Barnes, G.C. Craig, H.T. Dublin, C.R. Thouless, I. Douglas-Hamilton, and J.A. Hart', errata: true },
      { year: '2002', full_text: '029', authors: 'J.J. Blanc, C.R. Thouless, J.A. Hart, H.T. Dublin, I. Douglas-Hamilton, G.C. Craig and R.F.W. Barnes', errata: true },
      { year: '1998', full_text: '022', authors: 'R.F.W. Barnes, G.C. Craig, H.T. Dublin, G. Overton, W. Simons and C.R. Thouless', errata: false },
      { year: '1995', full_text: '011', authors: 'M.Y. Said, R.N. Chunge, G.C. Craig, C.R. Thouless, R.F.W. Barnes and H.T. Dublin', errata: true }
    ]
  end

  def year
    @year = params[:year]
  end

  before_filter :maybe_authenticate_user!, :only => [:preview_continent, :preview_region, :preview_country]

  # define official titles for certain filters
  def official_title(filter)
    if filter == "2013_africa_final"
      return "Provisional African Elephant Population Estimates: update to 31 Dec 2013"
    end
    return nil
  end

  def preview_corrections
    return unless allowed_preview?
    @year = params[:year].to_i
    @continent = params[:continent]
    @filter = params[:filter]
    @preview_title = official_title(@filter) or @filter.humanize.upcase
  end

  def preview_continent
    return unless allowed_preview?
    @year = params[:year].to_i
    @continent = params[:continent]
    @filter = params[:filter]
    @preview_title = official_title(@filter) or @filter.humanize.upcase
    @comp_year = Analysis.find_by_analysis_name(@filter).try(:comparison_year)

    # ADD values
    @alt_summary_totals = execute alt_dpps("1=1", @year, @filter)
    @alt_summary_sums   = execute alt_dpps_totals("1=1", @year, @filter)
    @alt_summary_sums_s = execute alt_dpps_totals("1=1", @comp_year, @filter) if @comp_year != @year
    @alt_areas          = execute alt_dpps_continent_area("1=1", @year, @filter)
    @alt_regions        = execute alt_dpps_continental_stats("1=1", @year, @filter)
    @alt_regions_sums   = execute alt_dpps_continental_stats_sums("1=1", @year, @filter)
    @alt_causes_of_change = execute alt_dpps_causes_of_change("1=1", @year, @filter)
    @alt_causes_of_change_s = execute alt_dpps_causes_of_change_sums("1=1", @year, @filter)
    @alt_areas_by_reason  = execute alt_dpps_continent_area_by_reason("1=1", @year, @filter)

    # DPPS values
    get_continent_values(@continent, @filter, @year).each do |k, v|
      instance_variable_set("@#{k}".to_sym, v)
    end
    @summary_totals_by_continent = execute totalizer("1=1",@filter,@year)
    if @summary_totals_by_continent.num_tuples < 1
      raise ActionController::RoutingError.new('Not Found')
    end
  end

  def continent
    @year = params[:year].to_i
    @continent = params[:continent]
    get_continent_previous_values(@continent, @year).each do |k,v|
      instance_variable_set("@#{k}".to_sym, v)
    end
  end

  def preview_region
    return unless allowed_preview?
    @year = params[:year].to_i
    @continent = params[:continent]
    @region = params[:region].gsub('_',' ')
    @filter = params[:filter]
    @preview_title = official_title(@filter) or @filter.humanize.upcase
    @comp_year = Analysis.find_by_analysis_name(@filter).try(:comparison_year)

    # ADD values
    @alt_summary_totals = execute alt_dpps("region = '#{@region}'", @year, @filter)
    @alt_summary_sums   = execute alt_dpps_totals("region = '#{@region}'", @year, @filter)
    @alt_summary_sums_s = execute alt_dpps_totals("region = '#{@region}'", @comp_year, @filter) if @comp_year != @year
    @alt_areas          = execute alt_dpps_region_area("region = '#{@region}'", @year, @filter)
    @alt_countries      = execute alt_dpps_region_stats("region = '#{@region}'", @year, @filter)
    @alt_country_sums   = execute alt_dpps_region_stats_sums("region = '#{@region}'", @year, @filter)
    @alt_causes_of_change = execute alt_dpps_causes_of_change("region = '#{@region}'", @year, @filter)
    @alt_causes_of_change_s = execute alt_dpps_causes_of_change_sums("region = '#{@region}'", @year, @filter)
    @alt_areas_by_reason  = execute alt_dpps_region_area_by_reason("region = '#{@region}'", @year, @filter)

    # DPPS values
    get_region_values(@region, @filter, @year).each do |k, v|
      instance_variable_set("@#{k}".to_sym, v)
    end
    @summary_totals_by_region = execute totalizer("region='#{@region}'",@filter,@year)
    if @summary_totals_by_region.num_tuples < 1
      raise ActionController::RoutingError.new('Not Found')
    end
  end

def region
  @year = params[:year].to_i
  @continent = params[:continent]
  @region = params[:region].gsub('_',' ')
  get_region_previous_values(@region, @year).each do |k,v|
    instance_variable_set("@#{k}".to_sym, v)
  end
end

def preview_country
  return unless allowed_preview?
  @year = params[:year].to_i
  @continent = params[:continent]
  @region = params[:region].gsub('_',' ')
  @country = params[:country].gsub('_',' ')
  @map_uri = Country.where(name: @country).first().iso_code + "/" + params[:filter] + "/" + params[:year]
  @filter = params[:filter]
  @preview_title = official_title(@filter) or @filter.humanize.upcase
  @comp_year = Analysis.find_by_analysis_name(@filter).try(:comparison_year)

  # ADD values
  @alt_summary_totals = execute alt_dpps("country = '#{sql_escape @country}'", @year, @filter)
  @alt_summary_sums   = execute alt_dpps_totals("country = '#{sql_escape @country}'", @year, @filter)
  @alt_summary_sums_s = execute alt_dpps_totals("country = '#{sql_escape @country}'", @comp_year, @filter) if @comp_year != @year
  @alt_areas          = execute alt_dpps_country_area("country = '#{sql_escape @country}'", @year, @filter)
  @alt_causes_of_change = execute alt_dpps_causes_of_change("country = '#{sql_escape @country}'", @year, @filter)
  @alt_causes_of_change_s = execute alt_dpps_causes_of_change_sums("country = '#{sql_escape @country}'", @year, @filter)
  @alt_areas_by_reason  = execute alt_dpps_country_area_by_reason("country = '#{sql_escape @country}'", @year, @filter)
  @alt_elephant_estimates_by_country = execute alt_dpps_country_stats(@country, @year, @filter)

  @alt_elephant_estimate_groups = []
  group = []
  current_replacement_name = @alt_elephant_estimates_by_country[0]['replacement_name']
  @alt_elephant_estimates_by_country.each do |row|
    if row['replacement_name'] == current_replacement_name
      group << row
    else
      @alt_elephant_estimate_groups << group
      group = []
      group << row
      current_replacement_name = row['replacement_name']
    end
  end
  @alt_elephant_estimate_groups << group

  # DPPS values
  get_country_values(@country, @filter, @year).each do |k, v|
    instance_variable_set("@#{k}".to_sym, v)
  end
  @summary_totals_by_country = execute totalizer("country='#{sql_escape @country}'",@filter,@year)
  if @summary_totals_by_country.num_tuples < 1
    raise ActionController::RoutingError.new('Not Found')
  end

  @ioc_tabs = [
        {
            title: 'ADD Interpretation of Changes',
            template: 'table_causes_of_change_add',
            args: {
                totals: @alt_causes_of_change,
                sums: @alt_causes_of_change_s
            }
        },
        {
            title: 'DPPS Interpretation of Changes',
            template: 'table_causes_of_change_dpps',
            args: {
                base_totals: @causes_of_change_by_country_u,
                base_sums: @causes_of_change_sums_by_country_u,
                scaled_totals: @causes_of_change_by_country,
                scaled_sums: @causes_of_change_sums_by_country
            }
        }
  ]
  end

  def preview_site
    return unless allowed_preview?
    @year = params[:year].to_i
    @continent = params[:continent]
    @site = params[:site].gsub('_',' ')
    @filter = params[:filter]
    @preview_title = official_title(@filter) or @filter.humanize.upcase

    @summary_totals_by_site = execute <<-SQL, @site
      select
        e.category "CATEGORY",
        surveytype "SURVEYTYPE",
        round(sum(definite)) "DEFINITE",
        round(sum(probable)) "PROBABLE",
        round(sum(possible)) "POSSIBLE",
        round(sum(speculative)) "SPECUL"
      from estimate_locator e
        join estimate_dpps d on e.input_zone_id = d.input_zone_id
          and e.analysis_name = d.analysis_name
          and e.analysis_year = d.analysis_year
        join surveytypes t on t.category = e.category
        where e.analysis_name = '#{@filter}' and e.analysis_year = '#{@year}'
        and replacement_name=?
      group by e.category, surveytype
      order by e.category;
    SQL
    @summary_sums_by_site = execute <<-SQL, @site
      select
        round(sum(definite)) "DEFINITE",
        round(sum(probable)) "PROBABLE",
        round(sum(possible)) "POSSIBLE",
        round(sum(speculative)) "SPECUL"
      from estimate_locator e
        join estimate_dpps d on e.input_zone_id = d.input_zone_id
          and e.analysis_name = d.analysis_name
          and e.analysis_year = d.analysis_year
        join surveytypes t on t.category = e.category
        where e.analysis_name = '#{@filter}' and e.analysis_year = '#{@year}'
        and replacement_name=?
    SQL
    @elephant_estimates_by_site = execute <<-SQL, @site
      select
        CASE WHEN reason_change='NC' THEN
          '-'
        ELSE
          reason_change
        END as "ReasonForChange",
        e.population_submission_id,
        e.site_name || ' / ' || e.stratum_name survey_zone,
        e.input_zone_id method_and_quality,
        e.category "CATEGORY",
        e.completion_year "CYEAR",
        e.population_estimate "ESTIMATE",
        CASE WHEN e.population_confidence_interval is NULL THEN
          to_char(e.population_upper_confidence_limit,'9999999') || '*'
        ELSE
          to_char(ROUND(e.population_confidence_interval),'9999999')
        END "CL95",
        e.short_citation "REFERENCE",
        '-' "PFS",
        e.stratum_area "AREA_SQKM",
        CASE WHEN longitude<0 THEN
          to_char(abs(longitude),'990D9')||'W'
        WHEN longitude=0 THEN
          '0.0'
        ELSE
          to_char(abs(longitude),'990D9')||'E'
        END "LON",
        CASE WHEN latitude<0 THEN
          to_char(abs(latitude),'990D9')||'S'
        WHEN latitude=0 THEN
          '0.0'
        ELSE
          to_char(abs(latitude),'990D9')||'N'
        END "LAT"
      from estimate_locator e
        join estimate_dpps d on e.input_zone_id = d.input_zone_id
          and e.analysis_name = d.analysis_name
          and e.analysis_year = d.analysis_year
        join surveytypes t on t.category = e.category
        join population_submissions on e.population_submission_id = population_submissions.id
        where e.analysis_name = '#{@filter}' and e.analysis_year = '#{@year}'
        and replacement_name=?
      order by e.site_name, e.stratum_name
    SQL

    @causes_of_change_by_site = execute <<-SQL, @site
      SELECT *
      FROM causes_of_change_by_site where site=?
        and analysis_name = '#{@filter}' and analysis_year = '#{@year}'
    SQL

    @causes_of_change_sums_by_site = execute <<-SQL, @site
      SELECT *
      FROM causes_of_change_sums_by_site where site=?
        and analysis_name = '#{@filter}' and analysis_year = '#{@year}'
    SQL
  end

  def country
    @year = params[:year].to_i
    @continent = params[:continent]
    @region = params[:region].gsub('_',' ')
    @country = params[:country].gsub('_',' ')
    get_country_previous_values(@country, @year).each do |k,v|
      instance_variable_set("@#{k}".to_sym, v)
    end
  end

  def survey
    @year = params[:year].to_i
    @continent = params[:continent]
    @region = params[:region].gsub('_',' ')
    @country = params[:country].gsub('_',' ')
    @survey = params[:survey]
    db = "aed#{@year}"
    if @survey.to_i > 0
      survey_zones = execute <<-SQL, @survey
        SELECT *
        FROM #{db}.elephant_estimates_by_country where "OBJECTID"=?
      SQL
      survey_zones.each do |survey_zone|
        @survey_zone = survey_zone
        break
      end
    end
    if @survey_zone.nil?
      raise ActiveRecord::RecordNotFound
    end
  end

  helper_method :narrative, :footnote

  def report_narrative
    if @report_narrative.nil?
      @report_narrative = ReportNarrative.where(:uri => request.path[8..-1]).first
    end
    if @report_narrative.nil?
      @report_narrative = ReportNarrative.new
    end
    return @report_narrative
  end

  def narrative
    narrative = report_narrative.narrative
    if narrative.nil?
      narrative = ''
    else
      narrative = "<div class='report_narrative_narrative'>#{narrative}</div>"
    end
  end

  def footnote
    note = report_narrative.footnote
    if note.nil?
      note = ''
    else
      note = "<div class='report_narrative_footnote'>#{note}</div>"
    end
    if !current_user.nil? and current_user.admin?
      result = render_to_string :partial => "edit_narrative_links", :locals => {:report_narrative => report_narrative}
      note << result
    end
    note
  end

  def bibliography
    @filter = params[:filter]
    @bibliography = execute <<-SQL, @filter
      select input_zone_id, short_citation, citation from estimate_factors join new_strata on analysis_name=? and input_zone_id=new_stratum;
    SQL
  end

  def appendix_1
    @filter = params[:filter]
    @year = params[:year]
    @table = execute <<-SQL, @filter, @filter
      SELECT
        x.country "Country",
	substring(c.region from 1 for 1) "Region",
        TO_CHAR(x."ESTIMATE" / (x."ESTIMATE" + x."CONFIDENCE" + x."GUESS_MAX"),'990D99') as "Probable Fraction",
        TO_CHAR(crt."ASSESSED_RANGE" / crt."RANGE_AREA",'990D99') as "Assessed Range Fraction",
        TO_CHAR((x."ESTIMATE" / (x."ESTIMATE" + x."CONFIDENCE" + x."GUESS_MAX")) * (crt."ASSESSED_RANGE" / crt."RANGE_AREA"),'990D99') AS "IQI",
	TO_CHAR(((x."ESTIMATE" / (x."ESTIMATE" + x."CONFIDENCE" + x."GUESS_MAX")) * (crt."ASSESSED_RANGE" / crt."RANGE_AREA"))-prev_iqi,'990D99') "Change on Previous Report",
        TO_CHAR((crt."RANGE_AREA" / cont.range_area)*100,'990D99%') "Continental Range Fraction",
        ROUND(log((1+(x."ESTIMATE" / (x."ESTIMATE" + x."CONFIDENCE" + x."GUESS_MAX")) * (crt."ASSESSED_RANGE" / crt."RANGE_AREA")) / (crt."RANGE_AREA" / cont.range_area))) "PFS"
      FROM estimate_factors_analyses_categorized_totals_country_for_add x
      JOIN country_range_totals crt ON crt.country = x.country AND crt.analysis_year = x.analysis_year AND crt.analysis_name = x.analysis_name
      JOIN regional_range_totals rrt ON rrt.region = crt.region AND rrt.analysis_name = crt.analysis_name AND rrt.analysis_year = crt.analysis_year
      JOIN continental_range_totals cont ON cont.continent = 'Africa' AND cont.analysis_name = rrt.analysis_name AND cont.analysis_year = rrt.analysis_year
      JOIN analyses a ON x.analysis_year = a.analysis_year
      JOIN country c ON c.cntryname = x.country
      JOIN
      ( SELECT
          x.country,
          (x."ESTIMATE" / (x."ESTIMATE" + x."CONFIDENCE" + x."GUESS_MAX")) * (crt."ASSESSED_RANGE" / crt."RANGE_AREA") AS prev_iqi
        FROM
        analyses a
        JOIN estimate_factors_analyses_categorized_totals_country_for_add x
	       ON x.analysis_year = a.comparison_year
	       AND x.analysis_name = a.analysis_name
        JOIN country_range_totals crt ON crt.country = x.country AND crt.analysis_year = a.comparison_year AND crt.analysis_name = x.analysis_name
        JOIN regional_range_totals rrt ON rrt.region = crt.region AND rrt.analysis_name = a.analysis_name AND rrt.analysis_year = a.comparison_year
        JOIN continental_range_totals cont ON cont.continent = 'Africa' AND cont.analysis_name = a.analysis_name AND cont.analysis_year = a.comparison_year
        JOIN country c ON c.cntryname = x.country
        WHERE
  	     a.analysis_name = ?
      ) prev ON prev.country = x.country
      WHERE
	     a.analysis_name = ?
      ORDER BY "PFS", "Country";
    SQL
  end

  def appendix_2
    @filter = params[:filter]
    @table = execute <<-SQL, @filter
      SELECT
        analysis_year,
        region,
        country,
        replacement_name,
        estimate_type,
        estimate,
        confidence
      FROM appendix_2_add
      WHERE analysis_name = ?
    SQL
    @regional_totals = execute <<-SQL, @filter, @filter
      SELECT
        analysis_year,
        region,
        sum(population_estimate) AS estimate,
        1.96*sqrt(sum(population_variance)) AS confidence
      FROM ioc_add_new_base
      WHERE
        reason_change = 'RS' AND analysis_name = ?
      GROUP BY analysis_year, region
      UNION
      SELECT
        analysis_year,
        region,
        sum(population_estimate) AS estimate,
        1.96*sqrt(sum(population_variance)) AS confidence
      FROM ioc_add_replaced_base
      WHERE
        reason_change = 'RS' AND analysis_name = ?
      GROUP BY analysis_year, region
      ORDER BY region, analysis_year
    SQL
  end

  def general_statistics
    @filter = params[:filter]

    @table = execute <<-SQL, @filter
      select
        crt.region,
        pam.country,
        pam.stated country_area,
        ROUND("RANGE_AREA") range_area,
        ROUND(("RANGE_AREA"/pam.stated)*100) percent_range_area,
        percent_protected protected_area_coverage,
        cprm.percent_protected_range protected_range,
        to_char((x."ESTIMATE" / (x."ESTIMATE" + x."CONFIDENCE" + x."GUESS_MAX")) * (crt."ASSESSED_RANGE" / crt."RANGE_AREA"),'990D99') iqi
      from country_pa_metrics pam
      join country_range_totals crt
      on pam.country = crt.country
      join country_pa_range_metrics cprm
      on crt.country = cprm.country
      join analyses a
      on crt.analysis_name = a.analysis_name
      and crt.analysis_year = a.analysis_year
      join estimate_factors_analyses_categorized_totals_country_for_add x
      on x.analysis_name = a.analysis_name
      and x.analysis_year = a.analysis_year
      and crt.country = x.country
      where crt.analysis_name = ?
      order by region, pam.country;
    SQL

    @regional_table = execute <<-SQL, @filter, @filter
      select
        s1.region,
        s1.country_area region_area,
        s1.range_area,
        s1.percent_range_area,
        TO_CHAR((s3.pa_area / s1.country_area)*100,'990D99') protected_area_coverage,
        s4.percent_protected protected_range,
        s2.iqi
        from
      (
            select
              crt.region,
              sum(pam.stated) country_area,
              ROUND(sum("RANGE_AREA")) range_area,
              ROUND((sum("RANGE_AREA")/sum(pam.stated))*100) percent_range_area
            from country_pa_metrics pam
            join country_range_totals crt
            on pam.country = crt.country
            join analyses a
            on crt.analysis_name = a.analysis_name
            and crt.analysis_year = a.analysis_year
            where crt.analysis_name = ?
            group by region
      ) s1
        join
      (
            select
              crt.region,
              to_char((x."ESTIMATE" / (x."ESTIMATE" + x."CONFIDENCE" + x."GUESS_MAX")) * (crt.range_assessed / crt.range_area),'990D99') iqi
            from regional_range_totals crt
            join analyses a
            on crt.analysis_name = a.analysis_name
            and crt.analysis_year = a.analysis_year
            join estimate_factors_analyses_categorized_totals_region_for_add x
            on x.analysis_name = a.analysis_name
            and x.analysis_year = a.analysis_year
            and crt.region = x.region
            where crt.analysis_name = ?
      ) s2
      on s1.region = s2.region
        join
      (
            select
              region,
              sum(protected_area_sqkm) pa_area
            from country
            join country_pa_metrics
            on cntryname=country
            group by region
      ) s3
      on s1.region = s3.region
        join
      (
            select
      	region,
              TO_CHAR((sum(protected_area_range_sqkm)/sum(range_sqkm))*100,'990D99') percent_protected
      	from country
      	join country_pa_range_metrics
      	on cntryname=country group by region
      ) s4
      on s1.region = s4.region
      order by region;
    SQL

  @continental_table = execute <<-SQL, @filter, @filter
      select
      s1.country_area continental_area,
      s1.range_area,
      s1.percent_range_area,
      TO_CHAR((s3.pa_area / s1.country_area)*100,'990D99') protected_area_coverage,
      s4.percent_protected protected_range,
      s2.iqi
      from
    (
          select
            sum(pam.stated) country_area,
            ROUND(sum("RANGE_AREA")) range_area,
            ROUND((sum("RANGE_AREA")/sum(pam.stated))*100) percent_range_area
          from country_pa_metrics pam
          join country_range_totals crt
          on pam.country = crt.country
          join analyses a
          on crt.analysis_name = a.analysis_name
          and crt.analysis_year = a.analysis_year
          where crt.analysis_name = ?
    ) s1,
    (
          select
            to_char((x."ESTIMATE" / (x."ESTIMATE" + x."CONFIDENCE" + x."GUESS_MAX")) * (crt.range_assessed / crt.range_area),'990D99') iqi
          from continental_range_totals crt
          join analyses a
          on crt.analysis_name = a.analysis_name
          and crt.analysis_year = a.analysis_year
          join estimate_factors_analyses_categorized_totals_continent_for_add x
          on x.analysis_name = a.analysis_name
          and x.analysis_year = a.analysis_year
          where crt.analysis_name = ?
    ) s2,
    (
          select
            sum(protected_area_sqkm) pa_area
          from country
          join country_pa_metrics
          on cntryname=country
    ) s3,
    (
          select
            TO_CHAR((sum(protected_area_range_sqkm)/sum(range_sqkm))*100,'990D99') percent_protected
    	from country
    	join country_pa_range_metrics
    	on cntryname=country
    ) s4
    SQL
  end

end
