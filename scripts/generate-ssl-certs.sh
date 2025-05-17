#!/bin/bash
# Script to generate self-signed SSL certificates for development

# Create directories if they don't exist
mkdir -p nginx/ssl

# Set variables
DOMAIN="api.example.com"
CERT_DIR="nginx/ssl"
DAYS_VALID=365

echo "Generating self-signed SSL certificates for $DOMAIN..."

# Generate private key
openssl genrsa -out "$CERT_DIR/$DOMAIN.key" 2048

# Generate certificate signing request
openssl req -new -key "$CERT_DIR/$DOMAIN.key" -out "$CERT_DIR/$DOMAIN.csr" -subj "/CN=$DOMAIN/O=API Dart/C=BR"

# Generate self-signed certificate
openssl x509 -req -days $DAYS_VALID -in "$CERT_DIR/$DOMAIN.csr" -signkey "$CERT_DIR/$DOMAIN.key" -out "$CERT_DIR/$DOMAIN.crt"

# Create a combined PEM file (some services require this format)
cat "$CERT_DIR/$DOMAIN.key" "$CERT_DIR/$DOMAIN.crt" > "$CERT_DIR/$DOMAIN.pem"

# Remove the CSR as it's no longer needed
rm "$CERT_DIR/$DOMAIN.csr"

# Set appropriate permissions
chmod 600 "$CERT_DIR/$DOMAIN.key"
chmod 644 "$CERT_DIR/$DOMAIN.crt"
chmod 600 "$CERT_DIR/$DOMAIN.pem"

echo "SSL certificates generated successfully:"
echo "Private key: $CERT_DIR/$DOMAIN.key"
echo "Certificate: $CERT_DIR/$DOMAIN.crt"
echo "Combined PEM: $CERT_DIR/$DOMAIN.pem"
echo ""
echo "Note: These are self-signed certificates for development only."
echo "For production, use certificates from a trusted certificate authority."
echo ""
echo "To use these certificates with your local development environment:"
echo "1. Add the following entry to your /etc/hosts file:"
echo "   127.0.0.1 $DOMAIN"
echo "2. Import the certificate ($CERT_DIR/$DOMAIN.crt) into your browser's trusted certificates."
