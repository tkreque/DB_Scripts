/* 

------------------------ CHANGE LOG ------------------------
2018-04-02 - Thiago Reque
  - Created the script
*/

select TIME_FORMAT(SEC_TO_TIME(VARIABLE_VALUE ),'%Hh %im')  as Uptime 
from information_schema.GLOBAL_STATUS 
where VARIABLE_NAME='Uptime';