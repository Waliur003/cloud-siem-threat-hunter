SELECT 
    srcaddr AS attacker_ip,
    dstaddr AS target_internal_ip,
    dstport AS targeted_port,
    action,
    COUNT(*) AS total_blocked_packets
FROM cloud_siem_db.vpc_flow_logs
WHERE action = 'REJECT'
GROUP BY srcaddr, dstaddr, dstport, action
ORDER BY total_blocked_packets DESC
LIMIT 20;