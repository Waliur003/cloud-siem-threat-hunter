cat << 'EOF' > simulate_threats.sh
#!/bin/bash
echo "⚡ Starting Dummy Security Threat Simulation..."

# 1. Trigger S3 AccessDenied Recon
echo "1️⃣ Attempting unauthorized S3 bucket listing..."
aws s3 ls s3://restricted-admin-vault-do-not-access 2>/dev/null

# 2. Trigger IAM Privilege Escalation / Recon Attempt
echo "2️⃣ Attempting unauthorized IAM role listing..."
aws iam list-roles --max-items 2 2>/dev/null

# 3. Trigger KMS Key Enumeration Error
echo "3️⃣ Attempting unauthorized KMS key decryption test..."
aws kms list-keys 2>/dev/null

# 4. Trigger Security Group Discovery
echo "4️⃣ Discovering EC2 Security Groups..."
aws ec2 describe-security-groups --max-items 2 2>/dev/null

echo "✅ Threat simulation batch complete! CloudTrail is recording these events."
EOF

chmod +x simulate_threats.sh