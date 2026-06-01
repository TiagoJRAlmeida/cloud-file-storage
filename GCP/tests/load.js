import http from 'k6/http';
import { sleep, check } from 'k6';
import { FormData } from 'https://jslib.k6.io/formdata/0.0.2/index.js';
import { randomString } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

export const options = {
    vus: 50,
    duration: '5m',
    thresholds: {
        http_req_duration: ['p(95)<2000'],  // P95 under 2s
        http_req_failed: ['rate<0.05'],      // error rate under 5%
    },
};

const BASE_URL = 'https://35.222.216.191';

export function setup() {
    const res = http.post(
        `${BASE_URL}/auth/login`,
        JSON.stringify({ username: 'alice', password: 'password123' }),
        { headers: { 'Content-Type': 'application/json' } }
    );
    return { token: res.json('access_token') };
}

export default function(data) {
    const headers = {
        Authorization: `Bearer ${data.token}`,
        Host: 'storage.t1gs.com'
    };

    // Upload
    const fd = new FormData();
    fd.append('file', http.file(randomString(1024), 'test.txt', 'text/plain'));
    const uploadRes = http.post(`${BASE_URL}/files/upload`, fd.body(), {
        headers: { ...headers, 'Content-Type': `multipart/form-data; boundary=${fd.boundary}` },
    });
    check(uploadRes, { 'upload 200': (r) => r.status === 200 });

    const fileId = uploadRes.json('file_id');

    // Download
    if (fileId) {
        const downloadRes = http.get(`${BASE_URL}/files/${fileId}`, { headers });
        check(downloadRes, { 'download 200': (r) => r.status === 200 });
    }

    // List
    const listRes = http.get(`${BASE_URL}/files`, { headers });
    check(listRes, { 'list 200': (r) => r.status === 200 });

    sleep(1);
}
