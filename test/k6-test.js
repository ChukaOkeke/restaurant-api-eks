import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
  stages: [
    // Stage 1: Spike traffic to breach CPU threshold & trigger HPA (0 -> 800 VUs)
    { duration: '30s', target: 800 },
    // Stage 2: Sustain high traffic to exceed node capacity & trigger Karpenter (800 VUs)
    { duration: '3m', target: 800 },
    // Stage 3: Drop traffic to 0 to trigger scale-down & consolidation
    { duration: '30s', target: 0 },
  ],
  //thresholds: {
   // http_req_failed: ['rate<0.05'], // Expect < 5% error rate
  //},
};

export default function () {
  // Replace with your ALB Ingress URL or service domain
  const url = 'http://asgardcuisines.link/api/menu-items/'; 
  http.get(url);
  // sleep(0.1); // Sleep for 100ms between requests to simulate user think time 
}