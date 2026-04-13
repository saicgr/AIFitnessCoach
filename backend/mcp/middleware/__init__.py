"""MCP middleware chain.

Every MCP tool call runs through:
  auth → rate_limit → anomaly → confirmation → audit → tool

Each step is implemented in its own module and exposed as an async helper
that the FastMCP tool wrappers in `mcp/tools/*` invoke at their entry point.
"""
