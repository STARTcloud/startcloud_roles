#!/bin/bash
# generate_client_cert.sh - Script to generate client certificates for repository access
# Usage: ./generate_client_cert.sh <client_name> [password]

set -e

# Configuration
CA_DIR="./ca"
CLIENTS_DIR="./clients"
CA_KEY="${CA_DIR}/ca.key"
CA_CERT="${CA_DIR}/ca.crt"
DAYS_VALID=365
KEY_SIZE=4096
COUNTRY="US"
STATE="Illinois"
LOCALITY="Chicago"
ORGANIZATION="STARTcloud"
ORGANIZATIONAL_UNIT="Package Repository"
CA_CN="STARTcloud Package Repository CA"
SERVER_CN="private.packages.prominic.net"
DEFAULT_PASSWORD="changeit"

# Check if client name is provided
if [ -z "$1" ]; then
    echo "Error: Client name is required"
    echo "Usage: $0 <client_name> [password]"
    exit 1
fi

CLIENT_NAME="$1"
# Use provided password or default if not provided
CLIENT_PASSWORD="${2:-$DEFAULT_PASSWORD}"
CLIENT_DIR="${CLIENTS_DIR}/${CLIENT_NAME}"
CLIENT_KEY="${CLIENT_DIR}/${CLIENT_NAME}.key"
CLIENT_CSR="${CLIENT_DIR}/${CLIENT_NAME}.csr"
CLIENT_CERT="${CLIENT_DIR}/${CLIENT_NAME}.crt"
CLIENT_P12="${CLIENT_DIR}/${CLIENT_NAME}.p12"
CLIENT_PEM="${CLIENT_DIR}/${CLIENT_NAME}.pem"
CLIENT_CN="${CLIENT_NAME}"

# Create directories if they don't exist
mkdir -p "${CA_DIR}"
mkdir -p "${CLIENTS_DIR}"
mkdir -p "${CLIENT_DIR}"

# Generate CA if it doesn't exist
if [ ! -f "${CA_KEY}" ]; then
    echo "Generating CA key and certificate..."
    openssl genrsa -out "${CA_KEY}" "${KEY_SIZE}"
    openssl req -new -x509 -days "${DAYS_VALID}" -key "${CA_KEY}" -out "${CA_CERT}" \
        -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${ORGANIZATIONAL_UNIT}/CN=${CA_CN}"
    echo "CA certificate generated."
fi

# Generate client key
echo "Generating client key for ${CLIENT_NAME}..."
openssl genrsa -out "${CLIENT_KEY}" "${KEY_SIZE}"

# Generate client CSR
echo "Generating client certificate signing request..."
openssl req -new -key "${CLIENT_KEY}" -out "${CLIENT_CSR}" \
    -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${ORGANIZATIONAL_UNIT}/CN=${CLIENT_CN}"

# Sign client certificate with CA
echo "Signing client certificate with CA..."
openssl x509 -req -days "${DAYS_VALID}" -in "${CLIENT_CSR}" -CA "${CA_CERT}" -CAkey "${CA_KEY}" \
    -CAcreateserial -out "${CLIENT_CERT}"

# Create PKCS#12 file for browser import
echo "Creating PKCS#12 file for browser import..."
openssl pkcs12 -export -clcerts -in "${CLIENT_CERT}" -inkey "${CLIENT_KEY}" -out "${CLIENT_P12}" \
    -name "${CLIENT_NAME}" -passout "pass:${CLIENT_PASSWORD}"

# Create combined PEM file for APT
echo "Creating combined PEM file for APT..."
cat "${CLIENT_KEY}" "${CLIENT_CERT}" > "${CLIENT_PEM}"

# Set permissions
chmod 600 "${CLIENT_KEY}" "${CLIENT_P12}" "${CLIENT_PEM}"
chmod 644 "${CLIENT_CERT}" "${CLIENT_CSR}"

echo "Client certificate generation complete!"
echo "Files generated in ${CLIENT_DIR}:"
echo "  - Private key: ${CLIENT_KEY}"
echo "  - Certificate: ${CLIENT_CERT}"
echo "  - PKCS#12 (for browser): ${CLIENT_P12} (password: ${CLIENT_PASSWORD})"
echo "  - Combined PEM (for APT): ${CLIENT_PEM}"
echo ""
echo "Instructions for the client:"
echo "1. Save the ${CLIENT_NAME}.pem file to /etc/apt/certs/"
echo "2. Configure APT to use the certificate"
echo "3. Import ${CLIENT_NAME}.p12 into your browser for web access"

# Create a README file with instructions
cat > "${CLIENT_DIR}/README.txt" << EOF
STARTcloud Private Repository Access Certificate
===============================================

Client: ${CLIENT_NAME}
Generated: $(date)
Valid until: $(date -d "+${DAYS_VALID} days")

Files included:
- ${CLIENT_NAME}.key: Your private key (keep secure)
- ${CLIENT_NAME}.crt: Your certificate
- ${CLIENT_NAME}.p12: PKCS#12 bundle for browser import (password: ${CLIENT_PASSWORD})
- ${CLIENT_NAME}.pem: Combined key and certificate for APT

APT Configuration Instructions:
------------------------------
1. Create a directory for your certificates:
   sudo mkdir -p /etc/apt/certs

2. Copy the PEM file to the certs directory:
   sudo cp ${CLIENT_NAME}.pem /etc/apt/certs/

3. Set proper permissions:
   sudo chmod 600 /etc/apt/certs/${CLIENT_NAME}.pem

4. Create or edit /etc/apt/apt.conf.d/90ssl-certs with:
   Acquire::https::private.packages.prominic.net::SslCert "/etc/apt/certs/${CLIENT_NAME}.pem";
   Acquire::https::private.packages.prominic.net::SslKey "/etc/apt/certs/${CLIENT_NAME}.pem";

Browser Access Instructions:
---------------------------
1. Import the ${CLIENT_NAME}.p12 file into your browser:
   - Chrome: Settings → Privacy and security → Security → Manage certificates → Import
   - Firefox: Settings → Privacy & Security → Certificates → View Certificates → Import

2. When prompted, enter the password: ${CLIENT_PASSWORD}

3. After import, you should be able to access the repository in your browser.

Security Notes:
-------------
- Keep your private key and PEM file secure
- Do not share your certificate with others
- If your certificate is compromised, contact the repository administrator
EOF

echo "README.txt with instructions created in ${CLIENT_DIR}"
