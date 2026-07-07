// Upgrade-required page logic. External file for the same reason as
// authorize.js: the app-wide CSP (`default-src 'self'`) blocks inline
// <script> blocks outright.
const redirectUri = document.body.dataset.redirectUri || "";
const state = document.body.dataset.state || "";
const closeMsg = document.getElementById("closeMsg");

document.getElementById("closeBtn").addEventListener("click", () => {
  // Preferred path: hand control back to the MCP client with a proper OAuth
  // error so it can detect the decline and stop waiting, instead of hanging
  // forever on an auth code that will never arrive.
  if (redirectUri) {
    const params = new URLSearchParams({
      error: "subscription_required",
      error_description: "MCP access requires a yearly subscription.",
    });
    if (state) params.set("state", state);
    const sep = redirectUri.includes("?") ? "&" : "?";
    window.location.href = `${redirectUri}${sep}${params.toString()}`;
    return;
  }

  // Fallback (no redirect_uri resolved, e.g. an expired/missing consent
  // token): window.close() only works on tabs opened via script, so it
  // silently no-ops on a tab the OS/MCP client launched directly — show
  // visible feedback instead of leaving the click looking broken.
  try { window.close(); } catch (_) { /* ignored */ }
  setTimeout(() => {
    if (closeMsg) {
      closeMsg.textContent = "You can close this tab.";
      closeMsg.hidden = false;
    }
  }, 150);
});
