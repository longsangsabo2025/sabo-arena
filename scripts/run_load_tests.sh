#!/bin/bash

# Run Load Tests for SABO Arena
# Tests scaling infrastructure with k6 or Locust

set -e

echo "🚀 Starting SABO Arena Load Tests..."
echo ""

# Check if k6 is installed
if command -v k6 &> /dev/null; then
    echo "✅ k6 found, running k6 tests..."
    echo ""
    
    cd scripts/load_testing
    
    # Run k6 scenarios
    k6 run k6_scenarios.js \
        --out json=load_test_results.json \
        --summary-export=load_test_summary.json
    
    echo ""
    echo "✅ k6 tests completed!"
    echo "📊 Results saved to:"
    echo "   - load_test_results.json"
    echo "   - load_test_summary.json"
    
elif command -v locust &> /dev/null; then
    echo "✅ Locust found, running Locust tests..."
    echo ""
    
    cd scripts/load_testing
    
    # Run Locust (headless mode)
    locust -f locustfile.py \
        --headless \
        --users 1000 \
        --spawn-rate 10 \
        --run-time 5m \
        --html load_test_results.html \
        --csv load_test_results
    
    echo ""
    echo "✅ Locust tests completed!"
    echo "📊 Results saved to:"
    echo "   - load_test_results.html"
    echo "   - load_test_results_*.csv"
    
else
    echo "❌ Neither k6 nor Locust found!"
    echo ""
    echo "Install k6:"
    echo "  macOS: brew install k6"
    echo "  Linux: https://k6.io/docs/getting-started/installation/"
    echo "  Windows: https://k6.io/docs/getting-started/installation/"
    echo ""
    echo "Or install Locust:"
    echo "  pip install locust"
    echo ""
    exit 1
fi

echo ""
echo "📈 Next steps:"
echo "1. Review load test results"
echo "2. Identify bottlenecks"
echo "3. Optimize based on findings"
echo "4. Re-run tests to verify improvements"

