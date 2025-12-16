# Load Testing Guide

## Overview

Load testing is **CRITICAL** before optimizing. You can't optimize what you don't measure.

## Tools

### Option 1: k6 (Recommended)
- JavaScript-based
- Easy to use
- Good documentation
- Free and open source

### Option 2: Locust
- Python-based
- Web UI
- Good for complex scenarios

### Option 3: Custom Flutter Load Test
- Use Flutter test framework
- Test actual app behavior
- More realistic

## Setup

### Install k6
```bash
# macOS
brew install k6

# Linux
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6

# Windows
choco install k6
```

## Running Tests

### Basic Test
```bash
# Set environment variables
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key"

# Run test
k6 run k6_scenarios.js
```

### Custom Load Profile
```bash
# Run with custom VUs (Virtual Users)
k6 run --vus 1000 --duration 5m k6_scenarios.js
```

## Test Scenarios

### Scenario 1: Baseline (1K Users)
- Test current performance
- Identify bottlenecks
- Measure response times

### Scenario 2: Growth (10K Users)
- Test 10x growth
- Identify scaling issues
- Measure performance degradation

### Scenario 3: Target (100K Users)
- Test target capacity
- Identify breaking points
- Measure resource usage

## Metrics to Track

- **Response Time:** p50, p95, p99
- **Error Rate:** Should be < 1%
- **Throughput:** Requests per second
- **Database Query Time:** p95 should be < 100ms
- **API Response Time:** p95 should be < 500ms

## Interpreting Results

### Good Results
- Response times stable under load
- Error rate < 1%
- No memory leaks
- Database queries fast

### Bad Results (Need Optimization)
- Response times increase significantly
- Error rate > 1%
- Memory usage growing
- Database queries slow (> 500ms)

## Next Steps

After load testing:
1. Identify actual bottlenecks
2. Optimize based on real data
3. Re-test after optimizations
4. Compare before/after metrics

## Example Output

```
Load Test Results:
==================
Total Requests: 1,234,567
Failed Requests: 0.5%
Average Response Time: 245ms
P95 Response Time: 487ms
P99 Response Time: 892ms
Error Rate: 0.5%
```

