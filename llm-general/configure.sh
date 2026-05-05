#!/bin/bash
set -e

mkdir -p /home/work/.jupyter/lab/user-settings/@jupyterlab/apputils-extension \
         /home/work/.jupyter/lab/user-settings/@jupyterlab/shortcuts-extension \
         /home/work/.config/matplotlib

printf "font.family : Noto Sans CJK SC\naxes.unicode_minus : False\n" \
    > /home/work/.config/matplotlib/matplotlibrc

MPLCONFIGDIR=/home/work/.config/matplotlib \
    "$CONDA_ENV_PATH/bin/python" -c \
    "import matplotlib.font_manager as fm; fm._load_fontmanager(try_read_cache=False)"

cat > /home/work/.jupyter/jupyter_lab_config.py << 'EOF'
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.token = ''
c.ServerApp.allow_origin = '*'
c.ServerApp.allow_remote_access = True
c.ServerApp.disable_check_xsrf = True
c.ServerApp.root_dir = '/home/work'
c.ServerApp.open_browser = False
c.LabApp.open_browser = False
EOF

cat > /home/work/.jupyter/lab/user-settings/@jupyterlab/shortcuts-extension/shortcuts.jupyterlab-settings << 'EOF'
{
  "shortcuts": [
    {
      "command": "apputils:activate-command-palette",
      "keys": ["Accel Shift C"],
      "selector": "body",
      "disabled": true
    },
    {
      "command": "apputils:activate-command-palette",
      "keys": ["Accel Alt C"],
      "selector": "body"
    }
  ]
}
EOF
