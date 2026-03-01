#!/bin/bash
set -e

mkdir -p /home/work/.jupyter/lab/user-settings/@jupyterlab/apputils-extension \
         /home/work/.config/matplotlib

# matplotlib font config
printf "font.family : Noto Sans CJK SC\naxes.unicode_minus : False\n" \
    > /home/work/.config/matplotlib/matplotlibrc

# Pre-warm matplotlib font cache
MPLCONFIGDIR=/home/work/.config/matplotlib \
    $VIRTUAL_ENV/bin/python -c \
    "import matplotlib.font_manager as fm; fm._load_fontmanager(try_read_cache=False)"

# JupyterLab server config
cat > /home/work/.jupyter/jupyter_lab_config.py << 'EOF'
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.token = ''
c.ServerApp.allow_origin = '*'
c.ServerApp.allow_remote_access = True
c.ServerApp.disable_check_xsrf = True
c.ServerApp.root_dir = '/home/work/fastai-course-part2'
EOF

# JupyterLab keyboard shortcuts
cat > /home/work/.jupyter/lab/user-settings/@jupyterlab/apputils-extension/shortcuts.jupyterlab-settings << 'EOF'
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

# Register venv as a kernel for system JupyterLab.
# --user installs to ~/.local/share/jupyter/kernels/ which system jupyter discovers automatically.
$VIRTUAL_ENV/bin/python -m ipykernel install --user --name llm-learn --display-name "LLM Learn"
