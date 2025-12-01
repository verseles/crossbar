#!/bin/bash
# Test environment variable injection
echo "OS: ${CROSSBAR_OS:-unknown}"
echo "Version: ${CROSSBAR_VERSION:-unknown}"
echo "Plugin: ${CROSSBAR_PLUGIN_ID:-unknown}"
