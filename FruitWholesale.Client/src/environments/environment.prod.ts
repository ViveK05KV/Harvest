// TODO: replace with your actual Cloud Run URL after deploying the API
// (step 2 of the hosting tutorial) — e.g. 'https://fruitwholesale-api-xxxxx-uc.a.run.app'.
// Vercel and Cloud Run are different origins, so this can't be a relative
// path like '/api' the way same-origin deployments could get away with.
const apiBase = 'https://fruitwholesale-api-xxxxx-uc.a.run.app';

export const environment = {
  production: true,
  apiUrl: `${apiBase}/api`,
  serverUrl: apiBase
};
