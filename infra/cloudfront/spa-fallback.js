// CloudFront Function (viewer-request) attached to the S3 default behaviour.
//
// Replaces the distribution-wide 403/404 -> /index.html custom error responses, which also
// swallowed genuine API errors from the /api/* behaviour and rewrote them to 200 + index.html.
// This function is scoped to the SPA's own behaviour, so /api/* responses now pass through with
// their real status codes.
//
// Rule: anything that does not look like a file request (no dot in the last path segment) is a
// client-side route and is served index.html. Real asset requests fall through to S3 and a missing
// asset now correctly returns 404.
function handler(event) {
    var request = event.request;
    var uri = request.uri;

    if (uri.endsWith('/')) {
        request.uri = '/index.html';
        return request;
    }

    var lastSegment = uri.substring(uri.lastIndexOf('/') + 1);
    if (lastSegment.indexOf('.') === -1) {
        request.uri = '/index.html';
    }

    return request;
}
