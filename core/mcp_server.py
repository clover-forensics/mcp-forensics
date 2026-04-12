from mcp.server.fastmcp.server import FastMCP

from core.tools.linux import (
    register_binary_tools,
    register_content_extraction_tools,
    register_file_discovery_tools,
)
from core.tools.sleuthkit import register_sleuthkit_tools

mcp = FastMCP("forensics-server")

# Register all tools
register_file_discovery_tools(mcp)
register_content_extraction_tools(mcp)
register_binary_tools(mcp)
register_sleuthkit_tools(mcp)

if __name__ == "__main__":
    mcp.run()