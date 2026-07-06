// Post-approval landing page logic. External file for the same reason as
// authorize.js: the app-wide CSP (`default-src 'self'`) blocks inline
// <script> blocks outright.
document.getElementById("closeBtn").addEventListener("click", () => {
  window.close();
});
setTimeout(() => {
  try { window.close(); } catch (_) { /* ignored */ }
}, 2500);
