import { HttpClient, provideHttpClient, withInterceptors } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';

import { environment } from '../../../environments/environment';
import { payloadHashInterceptor } from './payload-hash.interceptor';

/**
 * Lets the interceptor's async body hashing settle so the request reaches the testing backend.
 * Reading a FormData body back as bytes takes several turns, so drain more than one.
 */
async function settle(turns = 10): Promise<void> {
  for (let i = 0; i < turns; i++) {
    await new Promise(resolve => setTimeout(resolve));
  }
}

async function sha256(bytes: Uint8Array | string): Promise<string> {
  const data = typeof bytes === 'string' ? new TextEncoder().encode(bytes) : bytes;
  const digest = await crypto.subtle.digest('SHA-256', data as BufferSource);
  return Array.from(new Uint8Array(digest))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
}

describe('payloadHashInterceptor', () => {
  let http: HttpClient;
  let controller: HttpTestingController;
  let originalProduction: boolean;

  beforeEach(() => {
    // The interceptor only engages in production, where the API sits behind CloudFront.
    originalProduction = environment.production;
    (environment as { production: boolean }).production = true;

    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(withInterceptors([payloadHashInterceptor])),
        provideHttpClientTesting()
      ]
    });

    http = TestBed.inject(HttpClient);
    controller = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    controller.verify();
    (environment as { production: boolean }).production = originalProduction;
  });

  it('keeps application/json on an object body instead of letting it degrade to text/plain', async () => {
    // Regression: the interceptor replaces the object body with its serialized string, and Angular
    // detects a string body as text/plain — which the API rejects with 415 Unsupported Media Type.
    http.post('/api/Auth/login', { username: 'u', password: 'p' }).subscribe();
    await settle();

    const req = controller.expectOne('/api/Auth/login');
    expect(req.request.headers.get('Content-Type')).toBe('application/json');
    req.flush({});
  });

  it('sends the SHA-256 of the exact serialized JSON body', async () => {
    const payload = { username: 'u', password: 'p' };
    http.post('/api/Auth/login', payload).subscribe();
    await settle();

    const req = controller.expectOne('/api/Auth/login');
    expect(req.request.headers.get('x-amz-content-sha256')).toBe(await sha256(JSON.stringify(payload)));
    expect(req.request.body).toBe(JSON.stringify(payload));
    req.flush({});
  });

  it('hashes the multipart bytes and keeps the boundary that was hashed', async () => {
    const form = new FormData();
    form.append('file', new File([new Uint8Array([1, 2, 3, 4])], 'logo.png', { type: 'image/png' }));
    http.post('/api/CompanySettings/logo', form).subscribe();
    await settle();

    const req = controller.expectOne('/api/CompanySettings/logo');
    const contentType = req.request.headers.get('Content-Type');
    expect(contentType).toContain('multipart/form-data');
    expect(contentType).toContain('boundary=');

    // The body must be the concrete bytes that were hashed, not the original FormData — otherwise
    // the browser would re-serialize with a different boundary and the signature would not match.
    const body = req.request.body as ArrayBuffer;
    expect(body instanceof ArrayBuffer).toBeTrue();
    expect(req.request.headers.get('x-amz-content-sha256')).toBe(await sha256(new Uint8Array(body)));
    req.flush({});
  });

  it('leaves bodyless requests untouched', async () => {
    http.get('/api/FruitMaster').subscribe();
    await settle();

    const req = controller.expectOne('/api/FruitMaster');
    expect(req.request.headers.has('x-amz-content-sha256')).toBeFalse();
    req.flush([]);
  });

  it('does nothing outside production, where the API is not behind CloudFront', async () => {
    (environment as { production: boolean }).production = false;
    http.post('/api/Auth/login', { username: 'u' }).subscribe();
    await settle();

    const req = controller.expectOne('/api/Auth/login');
    expect(req.request.headers.has('x-amz-content-sha256')).toBeFalse();
    req.flush({});
  });
});
