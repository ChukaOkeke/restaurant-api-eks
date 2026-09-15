import http from 'k6/http';
import { sleep, check } from 'k6';

export const options = {
  stages: [
    // 1. Ramp-up: Gradually increase to standard concurrent load (50 VUs) over 2 minutes
    { duration: '2m', target: 50 },
    // 2. Steady state: Hold baseline load for 5 minutes to measure performance metrics
    { duration: '5m', target: 50 },
    // 3. Ramp-down: Gracefully reduce traffic back to 0 over 1 minute
    { duration: '1m', target: 0 },
  ],
  thresholds: {
    // Assert Service Level Objectives (SLOs) for standard conditions
    http_req_failed: ['rate<0.01'],   // HTTP error rate must remain under 1%
    http_req_duration: ['p(95)<500'], // 95% of API requests must complete within 500ms
  },
};

export default function () {
  const url = 'http://asgardcuisines.link/api/menu-items/';
  const res = http.get(url);

  // Validate successful HTTP responses
  check(res, {
    'status is 200': (r) => r.status === 200,
  });

  // Simulate realistic user think time (1 second between iterations)
  sleep(1);
}