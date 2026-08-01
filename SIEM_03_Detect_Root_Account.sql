SELECT 
    eventtime,
    eventsource,
    eventname,
    sourceipaddress,
    useragent
FROM default.cloudtrail_logs_cloud_siem_security_datalake_cloudtrail
WHERE useridentity.type = 'Root'
ORDER BY eventtime DESC;