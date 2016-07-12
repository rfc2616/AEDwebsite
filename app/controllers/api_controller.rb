class ApiController < ApplicationController
  def autocomplete
    list = {}
    Continent.where(name: 'Africa').each do |c|
      list[c.name] = {
          id: c.id,
          geographicType: 'continent',
          parent: nil
      }
    end
    Region.all.each do |r|
      list[r.name] = {
          id: r.id,
          geographicType: 'region',
          parent: r.continent.name
      }
    end
    Country.where.not(region: nil).each do |c|
      list[c.name] = {
          id: c.iso_code,
          geographicType: 'country',
          parent: c.region.name
      }
    end
    sql = "SELECT DISTINCT
             input_zone_id,
             stratum_name || ' (' || analysis_year || ')' AS name,
             country
           FROM estimate_locator
           WHERE analysis_year < 2015"
    execute(sql).each do |s|
      list[s['name']] = {
          id: s['input_zone_id'],
          geographicType: 'stratum',
          parent: s['country']
      }
    end
    render json: list
  end

  def dump
    respond_to do |format|
      format.json { render json: Country.add_dump }
      format.csv { send_data(Country.add_csv_dump, filename: 'dump.csv') }
    end
  end

  def help
  end

  def strata_geojson
    sql = 'SELECT ST_AsGeoJSON(sg.geom) as "geo" FROM estimate_factors ef
           LEFT JOIN survey_geometries sg ON (ef.survey_geometry_id = sg.id)
           WHERE ef.input_zone_id = ?'
    render json: execute(sql, params[:strcode].upcase).first['geo']
  end

  private
  def execute(*array)
    sql = ActiveRecord::Base.send(:sanitize_sql_array, array)
    ActiveRecord::Base.connection.execute(sql)
  end
end
