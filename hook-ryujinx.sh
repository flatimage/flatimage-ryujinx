#shellcheck disable=2148
export PATH="/fim/mount/ryujinx/bin:$PATH"
export FIM_BINARY_RYUJINX="/fim/mount/ryujinx/boot"

# Configure XDG
if [ -v FIM_XDG_DATA_HOME ]; then
  export XDG_DATA_HOME="$FIM_XDG_DATA_HOME"
else
  export XDG_DATA_HOME="${FIM_DIR_BINARY}"/."${FIM_BASENAME_BINARY}".config/xdg/data
fi

if [ -v FIM_XDG_CONFIG_HOME ]; then
  export XDG_CONFIG_HOME="$FIM_XDG_CONFIG_HOME"
else
  export XDG_CONFIG_HOME="${FIM_DIR_BINARY}"/."${FIM_BASENAME_BINARY}".config/xdg/config
fi
