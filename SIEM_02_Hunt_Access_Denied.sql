SELECT 
    eventtime,
    useridentity.username AS actor,
    sourceipaddress,
    eventsource,
    eventname,
    errorcode,
    errormessage
FROM default.cloudtrail_logs_cloud_siem_security_datalake_cloudtrail
WHERE errorcode IS NOT NULL 
  AND (errorcode LIKE '%Denied%' OR errorcode LIKE '%Unauthorized%')
ORDER BY eventtime DESC
LIMIT 20;