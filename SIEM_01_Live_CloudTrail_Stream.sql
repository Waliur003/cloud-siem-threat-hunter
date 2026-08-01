SELECT 
    eventtime,
    eventsource,
    eventname,
    sourceipaddress,
    useridentity.username AS actor
FROM default.cloudtrail_logs_cloud_siem_security_datalake_cloudtrail
ORDER BY eventtime DESC
LIMIT 10;