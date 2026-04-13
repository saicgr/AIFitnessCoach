"""URI-addressable MCP resources.

Resources are side-effect-free, read-only. They use the `fitwiz://` URI
scheme. Each submodule registers its own set of resources on the
FastMCP app via a `register(mcp_app)` entry point, mirroring the tools
package layout.
"""
