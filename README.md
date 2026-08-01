# Cloud Security Project 8: Automated AWS Cloud Threat Hunter & SIEM Platform

## S3 Security Data Lake, Athena SQL Engine & EventBridge/SNS Real-Time Alerting

---

## Overview

I have architected and deployed an automated, production-grade **Cloud Security Information and Event Management (SIEM) and Threat Hunting Platform** on AWS. Built in accordance with cloud security best practices, this project establishes an encrypted **Security Data Lake** utilizing **Amazon S3** and **AWS KMS** to continuously aggregate security telemetry from **AWS CloudTrail** API management logs and **VPC Flow Logs**.

The ingestion tier uses the **AWS Glue Data Catalog** to discover log schemas, allowing high-speed SQL threat queries via **Amazon Athena**. To move beyond manual threat hunting, the platform incorporates real-time security automation: **Amazon EventBridge** monitors live CloudTrail event streams for unauthorized API operations (`AccessDenied` and `UnauthorizedOperation`), instantly routing threat payloads to an **Amazon SNS** topic to dispatch real-time email alerts to Security Operations Center (SOC) personnel.

---

## The Problem

Relying on manual log reviews or unaggregated cloud telemetry introduces critical security vulnerabilities and operational bottlenecks:

* **Unaggregated Log Streams & Limited Visibility:** Security logs scattered across individual services (VPC, CloudTrail, S3) hinder rapid incident response and cross-service threat correlation.
* **Delayed Incident Response Times:** Manually sifting through millions of raw JSON log records in S3 to find unauthorized access attempts creates dangerous detection lags.
* **Lack of Real-Time Threat Automation:** Without automated detection pipelines, credential leaks or unauthorized privilege escalation attempts go unnoticed until damage has occurred.
* **High Storage & Query Costs:** Querying raw, unindexed log data without centralized cataloging leads to exorbitant scan costs and degraded query performance.

---

## The Solution

* **Centralized & Encrypted Security Data Lake:** Ingests raw AWS CloudTrail management events and network perimeter VPC Flow Logs into an Amazon S3 bucket protected with server-side KMS encryption.
* **Serverless SQL Analytics Engine:** Catalogs telemetry schemas via AWS Glue, enabling serverless SQL querying in Amazon Athena to hunt for security anomalies, root account usage, and network port probes.
* **Real-Time EventBridge Threat Pattern Matching:** Analyzes live CloudTrail event patterns in under 60 seconds to detect unauthorized API calls (`AccessDenied` and `UnauthorizedOperation`).
* **Automated Multi-Channel SNS Alerting:** Connects EventBridge detection rules directly to an Amazon Simple Notification Service (SNS) topic, dispatches instant email alerts with detailed event metadata.

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Storage Tier** | **Amazon S3 Data Lake** (`cloud-siem-security-datalake`), **AWS KMS** Encryption |
| **Log Ingestion Streams** | **AWS CloudTrail**, **AWS VPC Flow Logs** |
| **Data Cataloging Tier** | **AWS Glue Data Catalog** (`cloud_siem_db`, `default` catalog) |
| **Threat Analytics Engine** | **Amazon Athena** (Presto/Trino SQL Serverless Engine) |
| **Event Detection Tier** | **Amazon EventBridge** (`SIEM-AccessDenied-Detection-Rule`) |
| **Notification Tier** | **Amazon SNS** (`siem-security-alerts`), Email Protocol |
| **Automation & CLI** | **AWS CloudShell**, Bash Threat Simulation Scripts |

---

## Architecture Diagram

```text
[ AWS Environment ]
   │
   ├─► AWS CloudTrail Logs ────┐
   │                          │
   └─► VPC Flow Logs ─────────┼──► [ S3 Security Data Lake ] ──► [ AWS Glue Data Catalog ]
                              │       (KMS Encrypted)                   │
                              │                                         ▼
                              ├─► [ Amazon EventBridge ]       [ Amazon Athena SQL Engine ]
                              │      (Threat Rule Pattern)              │
                              │               │                         ▼
                              │               ▼              (Threat Hunting Queries)
                              └──────► [ Amazon SNS Topic ]
                                              │
                                              ▼
                                     [ SOC Email Alert ]
```

---

## Project Procedure

### 1. Encrypted Security Data Lake & Catalog Setup

* Created an Amazon S3 bucket (`cloud-siem-security-datalake`) configured with AWS KMS server-side encryption to serve as the immutable log repository.
* Enabled AWS CloudTrail logging and VPC Flow Logs, routing JSON and columnar log delivery directly to S3 storage prefixes.
* Configured the **AWS Glue Data Catalog** database `cloud_siem_db` and imported table schemas for CloudTrail and VPC Flow Logs.

---

### 2. Amazon Athena Threat Suite Engineering

Authored 4 production SQL threat hunting queries inside Amazon Athena to interrogate security telemetry:

1. **`SIEM_01_Live_CloudTrail_Stream`**: Validates real-time CloudTrail event parsing.
2. **`SIEM_02_Hunt_Access_Denied`**: Filters log noise to catch unauthorized API enumeration and `AccessDenied` anomalies.
3. **`SIEM_03_Detect_Root_Account`**: Audits usage of the high-risk AWS Root Account.
4. **`SIEM_04_Hunt_Rejected_VPC`**: Aggregates external IP addresses performing port scans blocked by Network ACLs/Security Groups.

---

### 3. EventBridge Detection Rule Construction

Built an Amazon EventBridge rule `SIEM-AccessDenied-Detection-Rule` configured with a custom JSON event pattern:

```json
{
  "source": ["aws.s3", "custom.siem"],
  "detail": {
    "errorCode": ["AccessDenied", "UnauthorizedOperation"]
  }
}
```

Mapped rule execution targets directly to the SNS topic `siem-security-alerts`.

---

### 4. Amazon SNS Notification Pipeline & Policy Hardening

* Provisioned an Amazon SNS Topic `siem-security-alerts` and subscribed SOC email endpoints.
* Updated the SNS Access Policy to grant explicit `sns:Publish` rights to the EventBridge service principal (`events.amazonaws.com`), ensuring seamless cross-service message delivery.

---

## Infrastructure as Code (IaC) Architecture

To support repeatable security infrastructure deployments, this Cloud SIEM platform is fully modularized using Terraform:

```text
terraform-aws-cloud-siem/
├── main.tf              # Provider configuration and KMS encryption keys
├── variables.tf         # Abstracted S3 bucket names, email endpoints, and region rules
├── datalake.tf          # Encrypted S3 buckets, CloudTrail, and VPC Flow Log streams
├── catalog.tf           # AWS Glue Data Catalog database and Athena table DDLs
├── athena.tf            # Pre-configured Athena workgroups and saved threat hunting queries
├── eventbridge.tf       # EventBridge detection rules and JSON event pattern filters
├── sns.tf               # SNS topic, topic access policies, and email subscriptions
└── outputs.tf           # S3 bucket ARNs, Athena output locations, and SNS Topic ARNs
```

---

## File-by-File Technical Breakdown

### `main.tf`

Configures AWS Provider requirements and provisions AWS KMS customer-managed keys for data lake encryption at rest.

### `variables.tf`

Parameterizes AWS regions (`us-east-1`), S3 naming patterns, and security notification endpoints.

### `datalake.tf`

Provisions the S3 Security Data Lake with public access blocks, bucket policies, and CloudTrail/VPC Flow Log delivery configurations.

### `catalog.tf`

Defines the AWS Glue Data Catalog (`cloud_siem_db`) and creates external table definitions for Hive/OpenCSV SerDe log formats.

### `athena.tf`

Sets up the Athena primary workgroup and attaches saved SQL queries for threat detection.

### `eventbridge.tf`

Deploys the EventBridge rule matching `AccessDenied` API calls across CloudTrail streams.

### `sns.tf`

Provisions the SNS topic `siem-security-alerts`, binds email subscriptions, and attaches resource policies permitting `events.amazonaws.com` publishing.

### `outputs.tf`

Exports the S3 Data Lake ARN, Athena Query Workgroup ID, and SNS Topic ARN.

---

## Technical Difficulties Faced & Engineering Resolutions

### Challenge 1: Hive / SerDe Syntax Mismatches During Athena Table Creation

**Root Cause Analysis:** Manually authoring Athena DDL scripts for CloudTrail JSON logs resulted in SerDe parsing errors (`mismatched input 'EXTERNAL'`) due to strict nested JSON structure requirements in CloudTrail logs.

**Architectural Resolution:** Leveraged AWS CloudTrail's native **Create Athena Table** integration to automatically generate the optimized SerDe table schema (`cloudtrail_logs_cloud_siem_security_datalake_cloudtrail`) inside the default Glue catalog, resolving schema parsing issues.

---

### Challenge 2: EventBridge Event Injection Restrictions (`NotAuthorizedForSourceException`)

**Root Cause Analysis:** Attempting to inject simulated test events into EventBridge via the CLI using `"Source": "aws.s3"` threw a `NotAuthorizedForSourceException` because AWS prevents manual CLI calls from spoofing official AWS service namespaces.

**Architectural Resolution:** Updated the EventBridge event pattern filter to accept both official service events (`aws.s3`) and custom application sources (`custom.siem`). Executed real API calls via a custom Bash script (`simulate_threats.sh`), allowing CloudTrail to emit authentic S3 events.

---

### Challenge 3: Silent Drop of SNS Messages Due to Missing Principal Permissions

**Root Cause Analysis:** Although EventBridge matched the threat rule, no email notifications reached the inbox. The default SNS Topic Access Policy restricted `sns:Publish` actions to account principals, silently blocking EventBridge (`events.amazonaws.com`) calls.

**Architectural Resolution:** Added a dedicated statement to the SNS Access Policy granting explicit `sns:Publish` permissions to `events.amazonaws.com`.

---

## Verification and Results

* **Verified Live Log Ingestion:** Amazon Athena successfully parsed incoming raw CloudTrail logs, displaying real-time AWS API calls (`PutObject`, `GenerateDataKey`).
* **Caught Active Threats:** Athena Threat Query 2 detected 4 live `AccessDenied` / `HeadBucket` security anomalies generated during simulated threat testing.
* **Audited Root Account & Network Perimeter:** Query 3 verified zero unauthorized AWS Root account logins, while Query 4 validated network perimeter drop checks against VPC Flow Logs.
* **Validated Automated Real-Time Alerts:** Received real-time SNS security alert emails containing JSON threat metadata within seconds of EventBridge rule execution.

---

## Verification Screenshots

### 1. Live CloudTrail Log Telemetry Verification (Athena Query 1)

Displays Amazon Athena executing Query 1 (`SIEM_01_Live_CloudTrail_Stream`) against table `default.cloudtrail_logs_cloud_siem_security_datalake_cloudtrail`. The query returned 10 live log rows (`PutObject`, `GenerateDataKey`, `GetBucketAcl`), scanning 105.22 KB of data and confirming that CloudTrail JSON events are being ingested and parsed correctly.

<img width="1918" height="1210" alt="Screenshot 1" src="https://github.com/user-attachments/assets/11de61ef-ac6f-49ae-b7ca-bb444fb564f5" />


---

### 2. Real-Time Access Denied Threat Detection (Athena Query 2)

Shows Amazon Athena running Query 2 (`SIEM_02_Hunt_Access_Denied`). The query isolated 4 live `AccessDenied` security events (`PutObject` and `HeadBucket` operations) originating from `delivery.logs.amazonaws.com` on `s3.amazonaws.com`, verifying that the threat hunting query filters noise to highlight security anomalies.

<img width="1918" height="1024" alt="Screenshot 2" src="https://github.com/user-attachments/assets/aa9c60b9-a3f5-4ae4-9360-bf03d10aeb7a" />


---

### 3. AWS Root Account Misuse Monitoring (Athena Query 3)

Captures Amazon Athena running Query 3 (`SIEM_03_Detect_Root_Account`) searching for `useridentity.type = 'Root'`. The query scanned 105.22 KB of telemetry and returned 0 results (`Results (0)`), validating query execution and confirming that no unauthorized Root user actions occurred during the audit period.

<img width="1919" height="908" alt="Screenshot 3" src="https://github.com/user-attachments/assets/df70eb9f-c2b7-4b6b-b96f-b32fd3d522a5" />


---

### 4. Blocked VPC Network Perimeter Traffic Probes (Athena Query 4)

Displays Amazon Athena executing Query 4 (`SIEM_04_Hunt_Rejected_VPC`) against `cloud_siem_db.vpc_flow_logs`. The query aggregated blocked network traffic (`action = 'REJECT'`), confirming that the network telemetry schema is properly configured to track external IP port scans.

<img width="1919" height="913" alt="Screenshot 4" src="https://github.com/user-attachments/assets/ea6688cd-5c6e-41b1-8601-6ce82c815946" />


---

### 5. VPC Flow Logs External Schema & Data Catalog DDL Creation

Shows the execution of the SQL DDL statement (`CREATE EXTERNAL TABLE IF NOT EXISTS cloud_siem_db.vpc_flow_logs...`) in Amazon Athena. This statement established the columnar schema mapping for VPC Flow Logs within the AWS Glue Data Catalog.

<img width="1919" height="830" alt="Screenshot 5" src="https://github.com/user-attachments/assets/678222ca-fdbd-4e43-83b5-df31fa276610" />


---

### 6. Amazon EventBridge Automated Threat Detection Rule & Target Binding

Captures the Amazon EventBridge console displaying the active rule `SIEM-AccessDenied-Detection-Rule`. The review screen confirms that the custom event pattern matches `AccessDenied` and `UnauthorizedOperation` errors, with the target bound to SNS Topic `siem-security-alerts`.

<img width="1918" height="1156" alt="Screenshot 6" src="https://github.com/user-attachments/assets/3a29c827-8060-4930-94b5-80370f2a2b47" />


---

### 7. Live Amazon SNS Automated Real-Time Email Alert Payload

Captures a live security notification email delivered to the SOC inbox from `AWS Notifications <no-reply@sns.amazonaws.com>`. The email contains JSON threat details (`"errorCode": "AccessDenied"`, `"eventName": "GetObject"`), matching Event ID `179c1f24-b48a-4fb6-fbb2-5f359e55fadb` and confirming end-to-end automated alerting.

<img width="1626" height="257" alt="Screenshot 7" src="https://github.com/user-attachments/assets/05e2622e-9886-439e-b8a2-9b9657dbf848" />


---

## Future Improvements

* **Amazon QuickSight Security Dashboards:** Build visual SOC dashboards showing threat distributions, geographical IP maps, and `AccessDenied` trend lines.
* **Automated Lambda Incident Remediation:** Attach AWS Lambda functions to EventBridge rules to automatically revoke compromised IAM credentials or block offending IP addresses in AWS WAF upon detection.
* **Apache Parquet Log Compaction:** Deploy AWS Glue ETL jobs to convert raw JSON CloudTrail logs into compressed Apache Parquet formats, reducing Athena query scan costs by up to 80%.

---

## Notes

This project demonstrates an end-to-end cloud security implementation, bridging log aggregation, cataloging, serverless SQL threat hunting, and event-driven alerting. It highlights expertise in core Cloud Security Engineer domains including S3 Data Lake management, KMS encryption, Glue cataloging, Athena threat hunting, EventBridge rule filtering, and SNS notification architecture.

---

## Bottom Line

The **Automated AWS Cloud Threat Hunter & SIEM Platform** establishes an end-to-end cloud security pipeline. By consolidating encrypted telemetry in an S3 Data Lake, cataloging log streams with AWS Glue, executing targeted threat queries in Amazon Athena, and dispatching real-time notifications via EventBridge and SNS, this architecture provides continuous visibility, proactive threat detection, and rapid incident response capabilities across AWS environments.
