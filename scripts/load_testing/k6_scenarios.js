// k6 Load Testing Scenarios for SABO Arena
// Run with: k6 run k6_scenarios.js

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const apiResponseTime = new Trend('api_response_time');
const dbQueryTime = new Trend('db_query_time');

// Configuration
export const options = {
  stages: [
    { duration: '2m', target: 1000 },   // Ramp up to 1K users
    { duration: '5m', target: 1000 },   // Stay at 1K users
    { duration: '2m', target: 10000 },  // Ramp up to 10K users
    { duration: '5m', target: 10000 },  // Stay at 10K users
    { duration: '2m', target: 50000 },   // Ramp up to 50K users
    { duration: '5m', target: 50000 },   // Stay at 50K users
    { duration: '2m', target: 100000 },  // Ramp up to 100K users
    { duration: '5m', target: 100000 },  // Stay at 100K users
    { duration: '2m', target: 0 },       // Ramp down
  ],
  thresholds: {
    'http_req_duration': ['p(95)<500'], // 95% of requests should be below 500ms
    'http_req_failed': ['rate<0.01'],   // Error rate should be less than 1%
    'errors': ['rate<0.01'],
  },
};

// Base URL (replace with your Supabase URL)
const BASE_URL = __ENV.SUPABASE_URL || 'https://your-project.supabase.co';
const ANON_KEY = __ENV.SUPABASE_ANON_KEY || 'your-anon-key';

export default function () {
  // Scenario 1: Tournament List Query
  const tournamentListStart = Date.now();
  const tournamentRes = http.get(`${BASE_URL}/rest/v1/tournaments?select=*&limit=20`, {
    headers: {
      'apikey': ANON_KEY,
      'Authorization': `Bearer ${ANON_KEY}`,
    },
  });
  const tournamentTime = Date.now() - tournamentListStart;
  apiResponseTime.add(tournamentTime);
  
  check(tournamentRes, {
    'tournament list status is 200': (r) => r.status === 200,
    'tournament list response time < 500ms': (r) => r.timings.duration < 500,
  }) || errorRate.add(1);

  sleep(1);

  // Scenario 2: User Profile Query
  const userId = 'test-user-id'; // Replace with actual user ID
  const userProfileStart = Date.now();
  const userRes = http.get(`${BASE_URL}/rest/v1/profiles?id=eq.${userId}`, {
    headers: {
      'apikey': ANON_KEY,
      'Authorization': `Bearer ${ANON_KEY}`,
    },
  });
  const userTime = Date.now() - userProfileStart;
  apiResponseTime.add(userTime);
  
  check(userRes, {
    'user profile status is 200': (r) => r.status === 200,
    'user profile response time < 300ms': (r) => r.timings.duration < 300,
  }) || errorRate.add(1);

  sleep(1);

  // Scenario 3: Tournament Creation (Write Operation)
  const tournamentCreateStart = Date.now();
  const createRes = http.post(`${BASE_URL}/rest/v1/tournaments`, JSON.stringify({
    name: `Load Test Tournament ${Date.now()}`,
    status: 'draft',
    start_time: new Date().toISOString(),
  }), {
    headers: {
      'apikey': ANON_KEY,
      'Authorization': `Bearer ${ANON_KEY}`,
      'Content-Type': 'application/json',
    },
  });
  const createTime = Date.now() - tournamentCreateStart;
  apiResponseTime.add(createTime);
  
  check(createRes, {
    'tournament creation status is 201': (r) => r.status === 201,
    'tournament creation response time < 1000ms': (r) => r.timings.duration < 1000,
  }) || errorRate.add(1);

  sleep(2);

  // Scenario 4: Real-time Subscription (WebSocket)
  // Note: k6 doesn't support WebSocket natively, use separate tool or k6 extension
  
  // Scenario 5: Image Upload
  const imageUploadStart = Date.now();
  const imageRes = http.post(`${BASE_URL}/storage/v1/object/tournament-images/test-image.jpg`, 
    'test-image-data', // Replace with actual image data
    {
      headers: {
        'apikey': ANON_KEY,
        'Authorization': `Bearer ${ANON_KEY}`,
        'Content-Type': 'image/jpeg',
      },
    }
  );
  const uploadTime = Date.now() - imageUploadStart;
  apiResponseTime.add(uploadTime);
  
  check(imageRes, {
    'image upload status is 200': (r) => r.status === 200,
    'image upload response time < 2000ms': (r) => r.timings.duration < 2000,
  }) || errorRate.add(1);

  sleep(1);
}

export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
    'load_test_results.json': JSON.stringify(data),
  };
}

function textSummary(data, options) {
  return `
Load Test Results:
==================
Total Requests: ${data.metrics.http_reqs.values.count}
Failed Requests: ${data.metrics.http_req_failed.values.rate * 100}%
Average Response Time: ${data.metrics.http_req_duration.values.avg}ms
P95 Response Time: ${data.metrics.http_req_duration.values['p(95)']}ms
P99 Response Time: ${data.metrics.http_req_duration.values['p(99)']}ms
Error Rate: ${data.metrics.errors.values.rate * 100}%
  `;
}

