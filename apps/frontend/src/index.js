// ~/novascope/apps/frontend/src/index.js
export default {
  async fetch(request, env, ctx) {
    return new Response('Hello from NovaScope Worker (placeholder)!');
  },
};