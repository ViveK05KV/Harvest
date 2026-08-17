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

  // Angular only guesses Content-Type from the body it is handed, and the body is about to be
  // replaced with its serialized form. An object would have been detected as application/json, but
  // the JSON string replacing it would be detected as text/plain — which the API rejects with 415.
  // So the original request's content type is resolved here, while the original body is still in
  // place, and set explicitly on the clone.
  let contentType = req.headers.get('Content-Type') ?? req.detectContentTypeHeader();

  // FormData and Blob bodies are turned into bytes via Response so that the boundary and encoding
  // are fixed before hashing; that Content-Type (which carries the boundary) wins.
  let body: ArrayBuffer | string;

  if (typeof serialized === 'string') {
    body = serialized;
  } else {
    const response = new Response(serialized as BodyInit);
    contentType = response.headers.get('Content-Type') ?? contentType;
    body = await response.arrayBuffer();
  }

  const bytes = typeof body === 'string' ? new TextEncoder().encode(body) : new Uint8Array(body);
  const digest = await crypto.subtle.digest('SHA-256', bytes);
  const hash = Array.from(new Uint8Array(digest))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');

  let headers = req.headers.set('x-amz-content-sha256', hash);
  if (contentType) {
    headers = headers.set('Content-Type', contentType);
  }

  return req.clone({ body, headers });
}
