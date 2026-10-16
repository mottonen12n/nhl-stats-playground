-- change the context
use role sysadmin;
use schema dev_db_us.clean_sch;
use warehouse adhoc_wh;

--seeing just flatten
select
    record_date,
    daily_record.value
from dev_db_us.stage_sch.raw_nhl_standings,
lateral flatten (input => json_data:standings) daily_record;

-- de-duplication of the records + flattening it
with nhl_standings_with_rank as (
    select 
        record_date,
        json_data,
        _stg_file_name,
        _stg_file_load_ts,
        _stg_file_md5 ,
        _copy_data_ts,
        row_number() over (partition by record_date order by _stg_file_load_ts desc) as latest_file_rank
    from dev_db_us.stage_sch.raw_nhl_standings
    where record_date is not null
),
unique_nhl_standings_data as (
    select 
        * 
    from 
        nhl_standings_with_rank 
    where latest_file_rank = 1
)
    select 
        record_date,
        daily_record.value:conferenceName::text as conference_name,
        daily_record.value:divisionName::text as division_name,
        daily_record.value:gamesPlayed::int as games_played,
        daily_record.value:goalAgainst::int as goals_against,
        daily_record.value:goalFor::int as goals_for,
        daily_record.value:homeGamesPlayed::int as home_games_played,
        daily_record.value:homeGoalsAgainst::int as home_goals_against,
        daily_record.value:homeGoalsFor::int as home_goals_for,
        daily_record.value:homeLosses::int as home_losses,
        daily_record.value:homeOtLosses::int as home_ot_losses,
        daily_record.value:homePoints::int as home_points,
        daily_record.value:homeRegulationPlusOtWins::int as home_regulation_plus_ot_wins,
        daily_record.value:homeRegulationWins::int as home_regulation_wins,
        daily_record.value:homeWins::int as home_wins,
        daily_record.value:losses::int as losses,
        daily_record.value:otLosses::int as ot_losses,
        daily_record.value:placeName.default::text as place_name,
        daily_record.value:pointPctg::float as points_percentage,
        daily_record.value:points::int as points,
        daily_record.value:regulationPlusOtWins::int as regulation_plus_ot_wins,
        daily_record.value:regulationWins::int as regulation_wins,
        daily_record.value:roadGamesPlayed::int as road_games_played,
        daily_record.value:roadGoalsAgainst::int as road_goals_against,
        daily_record.value:roadGoalsFor::int as road_goals_for,
        daily_record.value:roadLosses::int as road_losses,
        daily_record.value:roadOtLosses::int as road_ot_losses,
        daily_record.value:roadPoints::int as road_points,
        daily_record.value:roadRegulationPlusOtWins::int as road_regulation_plus_ot_wins,
        daily_record.value:roadRegulationWins::int as road_regulation_wins,
        daily_record.value:roadWins::int as road_wins,
        daily_record.value:seasonId::int as seasonId,
        daily_record.value:shootoutLosses::int as shootout_losses,
        daily_record.value:shootoutWins::int as shootout_wins,
        daily_record.value:streakCode::text as streak_code,
        daily_record.value:streakCount::int as streak_count,
        daily_record.value:teamName.default::text as team_name,
        daily_record.value:teamCommonName.default::text as team_common_name,
        daily_record.value:teamAbbrev.default::text as team_abbreviation,
        daily_record.value:winPctg::float as win_percentage,
        daily_record.value:wins::int as wins,

        
        _stg_file_name,
        _stg_file_load_ts,
        _stg_file_md5,
        _copy_data_ts
  from 
    unique_nhl_standings_data,
    lateral flatten (input => json_data:standings) daily_record;

create or replace dynamic table clean_nhl_standings_dt
    target_lag = 'downstream'
    warehouse = transform_wh
as
    with nhl_standings_with_rank as (
    select 
        record_date,
        json_data,
        _stg_file_name,
        _stg_file_load_ts,
        _stg_file_md5 ,
        _copy_data_ts,
        row_number() over (partition by record_date order by _stg_file_load_ts desc) as latest_file_rank
    from dev_db_us.stage_sch.raw_nhl_standings
    where record_date is not null
),
unique_nhl_standings_data as (
    select 
        * 
    from 
        nhl_standings_with_rank 
    where latest_file_rank = 1
)
    select 
        record_date,
        daily_record.value:conferenceName::text as conference_name,
        daily_record.value:divisionName::text as division_name,
        daily_record.value:gamesPlayed::int as games_played,
        daily_record.value:goalAgainst::int as goals_against,
        daily_record.value:goalFor::int as goals_for,
        daily_record.value:homeGamesPlayed::int as home_games_played,
        daily_record.value:homeGoalsAgainst::int as home_goals_against,
        daily_record.value:homeGoalsFor::int as home_goals_for,
        daily_record.value:homeLosses::int as home_losses,
        daily_record.value:homeOtLosses::int as home_ot_losses,
        daily_record.value:homePoints::int as home_points,
        daily_record.value:homeRegulationPlusOtWins::int as home_regulation_plus_ot_wins,
        daily_record.value:homeRegulationWins::int as home_regulation_wins,
        daily_record.value:homeWins::int as home_wins,
        daily_record.value:losses::int as losses,
        daily_record.value:otLosses::int as ot_losses,
        daily_record.value:placeName.default::text as place_name,
        daily_record.value:pointPctg::float as points_percentage,
        daily_record.value:points::int as points,
        daily_record.value:regulationPlusOtWins::int as regulation_plus_ot_wins,
        daily_record.value:regulationWins::int as regulation_wins,
        daily_record.value:roadGamesPlayed::int as road_games_played,
        daily_record.value:roadGoalsAgainst::int as road_goals_against,
        daily_record.value:roadGoalsFor::int as road_goals_for,
        daily_record.value:roadLosses::int as road_losses,
        daily_record.value:roadOtLosses::int as road_ot_losses,
        daily_record.value:roadPoints::int as road_points,
        daily_record.value:roadRegulationPlusOtWins::int as road_regulation_plus_ot_wins,
        daily_record.value:roadRegulationWins::int as road_regulation_wins,
        daily_record.value:roadWins::int as road_wins,
        daily_record.value:seasonId::int as seasonId,
        daily_record.value:shootoutLosses::int as shootout_losses,
        daily_record.value:shootoutWins::int as shootout_wins,
        daily_record.value:streakCode::text as streak_code,
        daily_record.value:streakCount::int as streak_count,
        daily_record.value:teamName.default::text as team_name,
        daily_record.value:teamCommonName.default::text as team_common_name,
        daily_record.value:teamAbbrev.default::text as team_abbreviation,
        daily_record.value:winPctg::float as win_percentage,
        daily_record.value:wins::int as wins,

        
        _stg_file_name,
        _stg_file_load_ts,
        _stg_file_md5,
        _copy_data_ts
  from 
    unique_nhl_standings_data,
    lateral flatten (input => json_data:standings) daily_record;


select * from clean_nhl_standings_dt;