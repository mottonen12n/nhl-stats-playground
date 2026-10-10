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