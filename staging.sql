-- change context
use role sysadmin;
use schema dev_db_us.stage_sch;
use warehouse adhoc_wh;


-- create an internal stage and enable directory service
create stage if not exists raw_standings_stg
directory = ( enable = true)
comment = 'raw nhl daily standings will be stored in this internal stage location';

 -- create file format to process the JSON file
  create file format if not exists json_file_format 
      type = 'JSON'
      compression = 'AUTO' 
      comment = 'this is json file format object';

show stages;
list @raw_standings_stg;


select 
    try_to_date(t.$1:standings[0].date::text, 'yyyy-mm-dd') as record_date,
    t.$1,
    -- meta data information
    metadata$filename as _stg_file_name,
    metadata$FILE_LAST_MODIFIED as _stg_file_load_ts,
    metadata$FILE_CONTENT_KEY as _stg_file_md5,
    current_timestamp() as _copy_data_ts
from 
    @dev_db_us.stage_sch.raw_standings_stg
    (file_format => JSON_FILE_FORMAT) t;

create or replace transient table raw_nhl_standings (
    id int primary key autoincrement,
    record_date date not null,
    json_data variant not null,
    -- audit columns for debugging
    _stg_file_name text,
    _stg_file_load_ts timestamp,
    _stg_file_md5 text,
    _copy_data_ts timestamp default current_timestamp()
);

create or replace task copy_nhl_standings_data
    warehouse = load_wh
    schedule = 'USING CRON 0 0 * * * US/Arizona'
as
copy into raw_nhl_standings (record_date, json_data, _stg_file_name, _stg_file_load_ts, _stg_file_md5, _copy_data_ts) from
(
    select 
    try_to_date(t.$1:standings[0].date::text, 'yyyy-mm-dd') as record_date,
    t.$1,
    -- meta data information
    metadata$filename as _stg_file_name,
    metadata$FILE_LAST_MODIFIED as _stg_file_load_ts,
    metadata$FILE_CONTENT_KEY as _stg_file_md5,
    current_timestamp() as _copy_data_ts
    from @dev_db_us.stage_sch.raw_standings_stg t
)
file_format = (format_name = 'dev_db_us.stage_sch.JSON_FILE_FORMAT') 
ON_ERROR = ABORT_STATEMENT; 

show tasks;
use role accountadmin;
grant execute task, execute managed task on account to role sysadmin;
use role sysadmin;

alter task dev_db_us.stage_sch.copy_nhl_standings_data resume;
execute task dev_db_us.stage_sch.copy_nhl_standings_data;
alter task dev_db_us.stage_sch.copy_nhl_standings_data suspend;

select *
    from raw_nhl_standings
    limit 10;
