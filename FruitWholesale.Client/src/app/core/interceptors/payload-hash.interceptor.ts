import { HttpInterceptorFn, HttpRequest } from '@angular/common/http';
import { from, switchMap } from 'rxjs';

import { environment } from '../../../environments/environment';

/**
 * Adds the `x-amz-content-sha256` header required by CloudFront's Origin Access Control.
 *
 * In production the API is a Lambda function URL reached through CloudFront, whose OAC signs every
 * origin request with SigV4. Lambda rejects unsigned payloads, and CloudFront does not hash the body
 * itself — it trusts the value the viewer supplies in `x-amz-content-sha256` and signs that. Without
 * the header, any request carrying a body is rejected with "The request signature we calculated does
 * not match the signature you provided".
 *
 * Bodyless requests (GET/HEAD) need nothing, so they pass straight through.
 *
 * Because the hash must cover the exact bytes that go on the wire, the body is serialized here and
 * the concrete bytes are put back on the request — otherwise Angular would re-serialize afterwards
 * and, for FormData, pick a different multipart boundary than the one we hashed.
 */
export const payloadHashInterceptor: HttpInterceptorFn = (req, next) => {
  if (!environment.production || req.body === null || req.body === undefined) {
    return next(req);
  }

  return from(withPayloadHash(req)).pipe(switchMap(hashed => next(hashed)));
};

async function withPayloadHash(req: HttpRequest<unknown>): Promise<HttpRequest<unknown>> {
  const serialized = req.serializeBody();
  if (serialized === null) {
    return req;
  }

  // FormData and Blob bodies are turned into bytes via Response so that the boundary and encoding
  // are fixed before hashing; the matching Content-Type has to travel with them.
  let body: ArrayBuffer | string;
  let contentType: string | null = null;

  if (typeof serialized === 'string') {
    body = serialized;
  } else {
    const response = new Response(serialized as BodyInit);
    contentType = response.headers.get('Content-Type');
    body = await response.arrayBuffer();
  }

  const bytes = typeof body === 'string' ? new TextEncoder().encode(body) : new Uint8Array(body);
  const digest = await crypto.subtle.digest('SHA-256', bytes);
  const hash = Array.from(new Uint8Array(digest))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');

  const headers = req.headers.set('x-amz-content-sha256', hash);
  return req.clone({
    body,
    headers: contentType && !req.headers.has('Content-Type') ? headers.set('Content-Type', contentType) : headers
  });
}
