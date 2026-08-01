CREATE EXTERNAL TABLE IF NOT EXISTS cloud_siem_db.vpc_flow_logs (
    version INT,
    account_id STRING,
    interface_id STRING,
    srcaddr STRING,
    dstaddr STRING,
    srcport INT,
    dstport INT,
    protocol INT,
    packets BIGINT,
    bytes BIGINT,
    start BIGINT,
    `end` BIGINT,
    action STRING,
    log_status STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ' '
LOCATION 's3://cloud-siem-security-datalake/vpc-flow-logs/AWSLogs/';