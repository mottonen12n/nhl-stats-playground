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

  -- level-1
select 
    * 
from 
    @dev_db_us.stage_sch.raw_standings_stg
    (file_format => JSON_FILE_FORMAT) t;

create or replace transient table raw_aqi (
    id int primary key autoincrement,
    record_date date not null,
    json_data variant not null,
    record_count number not null default 0,
    
    -- audit columns for debugging
    _stg_file_name text,
    _stg_file_load_ts timestamp,
    _stg_file_md5 text,
    _copy_data_ts timestamp default current_timestamp()
);

