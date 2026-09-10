#!/usr/bin/env bash
set -e

# Colors for presentation
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}    MLOps Continuous Delivery (CD) Simulation        ${NC}"
echo -e "${BLUE}======================================================${NC}"

# 1. CI Stage (Test)
echo -e "\n${YELLOW}[Stage 1: Continuous Integration (CI)]${NC}"
echo "Running pytest test suite in isolated python environment..."
docker run --rm -v "$(pwd):/app" -w /app python:3.12-slim sh -c "pip install -q -r requirements.txt && pytest -v"
echo -e "${GREEN}✓ CI Tests passed successfully!${NC}"

# 2. CD Stage - Build Once (Immutable Artifacts)
echo -e "\n${YELLOW}[Stage 2: Package & Immutable Artifact Creation]${NC}"
echo "Building versioned image: mlops-cd-demo:1.0.0 and tag latest"
docker build -q \
  --build-arg APP_VERSION=1.0.0 \
  --build-arg GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "demo-sha") \
  -t mlops-cd-demo:1.0.0 \
  -t mlops-cd-demo:latest .
echo -e "${GREEN}✓ Artifact built once: mlops-cd-demo:1.0.0${NC}"

# 3. Deploy to Staging
echo -e "\n${YELLOW}[Stage 3: Automated Staging Deployment]${NC}"
echo "Deploying mlops-cd-demo:1.0.0 to staging container (port 5001)..."
docker stop mlops-staging >/dev/null 2>&1 || true
docker rm mlops-staging >/dev/null 2>&1 || true
docker run -d --name mlops-staging --restart unless-stopped -p 5001:5000 mlops-cd-demo:1.0.0
sleep 2

# 4. Smoke Test
echo -e "\n${YELLOW}[Stage 4: Staging Smoke / Health Test]${NC}"
STAGING_RESP=$(curl -s --fail http://localhost:5001/health)
echo "Staging /health response: $STAGING_RESP"
if [[ "$STAGING_RESP" =~ "healthy" ]]; then
  echo -e "${GREEN}✓ Smoke test PASSED: Staging environment is healthy!${NC}"
else
  echo -e "${RED}✗ Smoke test FAILED! Pipeline stopped.${NC}"
  exit 1
fi

# 5. Production Approval Gate Simulation
echo -e "\n${YELLOW}[Stage 5: Production Approval Gate]${NC}"
echo "Pipeline paused at: 'Waiting for manual approval'..."
echo -e "${GREEN}✓ Manual reviewer approved promotion of mlops-cd-demo:1.0.0 to production!${NC}"

# 6. Deploy to Production
echo -e "\n${YELLOW}[Stage 6: Production Deployment]${NC}"
echo "Deploying the SAME immutable artifact mlops-cd-demo:1.0.0 to production (port 5002)..."
docker stop mlops-production >/dev/null 2>&1 || true
docker rm mlops-production >/dev/null 2>&1 || true
docker run -d --name mlops-production --restart unless-stopped -p 5002:5000 mlops-cd-demo:1.0.0
sleep 2

PROD_RESP=$(curl -s --fail http://localhost:5002/health)
echo "Production /health response: $PROD_RESP"
echo -e "${GREEN}✓ Production deployment active on port 5002!${NC}"

# 7. Demonstrate New Release (1.1.0)
echo -e "\n${YELLOW}[Stage 7: Demonstrate New Release (1.1.0)]${NC}"
echo "Building new version: mlops-cd-demo:1.1.0 (with updated model version 1.1)..."
docker build -q \
  --build-arg APP_VERSION=1.1.0 \
  --build-arg MODEL_VERSION=1.1 \
  --build-arg GIT_COMMIT=release-1.1 \
  -t mlops-cd-demo:1.1.0 .

echo "Promoting mlops-cd-demo:1.1.0 to production..."
docker stop mlops-production >/dev/null 2>&1 || true
docker rm mlops-production >/dev/null 2>&1 || true
docker run -d --name mlops-production --restart unless-stopped -p 5002:5000 mlops-cd-demo:1.1.0
sleep 2
NEW_PROD_RESP=$(curl -s --fail http://localhost:5002/health)
echo "Production now running 1.1.0: $NEW_PROD_RESP"

# 8. Demonstrate Instant Rollback (Section 25 of Tutorial)
echo -e "\n${YELLOW}[Stage 8: Rollback Demonstration (Section 25)]${NC}"
echo "Simulating incident: 1.1.0 detected faulty behavior. Performing instant rollback to 1.0.0..."
docker stop mlops-production >/dev/null 2>&1 || true
docker rm mlops-production >/dev/null 2>&1 || true
docker run -d --name mlops-production --restart unless-stopped -p 5002:5000 mlops-cd-demo:1.0.0
sleep 2
ROLLED_BACK_RESP=$(curl -s --fail http://localhost:5002/health)
echo "Production response after rollback: $ROLLED_BACK_RESP"
if [[ "$ROLLED_BACK_RESP" =~ "1.0.0" ]]; then
  echo -e "${GREEN}✓ Rollback successful! Restored known-good version 1.0.0 in seconds.${NC}"
fi

echo -e "\n${BLUE}======================================================${NC}"
echo -e "${GREEN}    Full Continuous Delivery Simulation Completed!    ${NC}"
echo -e "${BLUE}======================================================${NC}"
