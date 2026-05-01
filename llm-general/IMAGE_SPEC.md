# llm-general RunPod 通用学习镜像规格

本文档是 `llm-general` 镜像的规格源。后续维护时，优先修改本文档，再根据本文档 Review 并生成或更新 `Dockerfile.runpod`、`entrypoint.sh`、`configure.sh`、`requirements-general.in`、`constraints*.txt`、`check_env.py` 等文件。

## 目录

- [1. 镜像定位](#1-镜像定位)
- [2. 维护原则](#2-维护原则)
- [3. 镜像版本](#3-镜像版本)
- [4. 用户、目录与权限](#4-用户目录与权限)
- [5. 系统工具](#5-系统工具)
- [6. Python 环境](#6-python-环境)
- [7. 环境变量](#7-环境变量)
- [8. Python 依赖](#8-python-依赖)
- [9. JupyterLab](#9-jupyterlab)
- [10. SSH](#10-ssh)
- [11. Notebook 与中文绘图](#11-notebook-与中文绘图)
- [12. Shell、编辑器与 Git](#12-shell编辑器与-git)
- [13. Optional: 启动时拉取项目](#13-optional-启动时拉取项目)
- [14. 端口](#14-端口)
- [15. Dockerfile 构建参数](#15-dockerfile-构建参数)
- [16. 文件清单](#16-文件清单)
- [17. 构建、Pin 与发布](#17-构建pin-与发布)
- [18. 环境检查](#18-环境检查)
- [19. RunPod 使用方式](#19-runpod-使用方式)
- [20. Review Checklist](#20-review-checklist)
- [21. 待决策项](#21-待决策项)

## 1. 镜像定位

`llm-general` 是一个面向 RunPod 的通用 LLM/ML/Python 学习与测试镜像。它应该能在新 Pod 启动后直接提供可用的 GPU Python 环境、JupyterLab、SSH、命令行工具和常见机器学习依赖。

核心目标：

- 启动后可直接使用 JupyterLab、SSH、tmux、vim 和常用 Linux 工具。
- 默认提供 CUDA/PyTorch 可用的 GPU Python 环境。
- 预装常见 LLM、HuggingFace、Notebook、数据处理、可视化、Gradio 和测试工具。
- 支持通过 RunPod Secrets 注入 GitHub、HuggingFace、SSH 公钥等敏感配置。
- 保持镜像可复现：Python 依赖使用 constraints 文件冻结。
- 保持构建缓存友好：PyTorch 与普通 Python 依赖分层安装。

明确不做：

- 不绑定任何课程仓库、项目仓库或个人代码仓库。
- 不在镜像中提交个人私钥、公钥明文、token 或其他 secrets。
- 不依赖容器启动时必须 clone 某个仓库才能正常工作。

## 2. 维护原则

本文档按“先规格、后实现”的方式维护：

1. 先修改本文档，明确镜像目标、依赖、启动行为或安全策略。
2. 根据本文档 Review 当前镜像文件。
3. 生成或修改 Dockerfile 和辅助脚本。
4. 构建、检查、pin constraints。
5. 再提交代码。

维护时优先保证：

- 文档中的配置能直接映射到具体文件和脚本。
- 敏感信息只通过 RunPod Secrets 注入。
- 默认行为适合交互式学习和临时代码测试。
- 可选行为必须显式由环境变量打开。

## 3. 镜像版本

建议维护两个 CUDA tag：

| Tag | RunPod 基础镜像 | PyTorch | Torch index | 用途 |
| --- | --- | --- | --- | --- |
| `cu1281` | `runpod/pytorch:1.0.3-cu1281-torch280-ubuntu2404` | `torch==2.8.0+cu128` | `https://download.pytorch.org/whl/cu128` | 默认推荐版本 |
| `cu1263` | `runpod/pytorch:0.7.0-cu1263-torch260-ubuntu2404` | `torch==2.6.0+cu126` | `https://download.pytorch.org/whl/cu126` | 兼容旧 CUDA/PyTorch 环境 |

如果只维护一个版本，保留 `cu1281`。

Docker Hub 镜像名：

```text
goosmanlei/runpod-learn-general
```

推荐 tags：

```text
cu1281
cu1263
```

## 4. 用户、目录与权限

容器内默认用户：

```text
user: work
home: /home/work
shell: /bin/bash
sudo: passwordless
```

默认工作目录：

```text
/home/work
```

RunPod 常见挂载目录：

```text
/workspace
```

启动时应尝试修正 `/workspace` 属主：

```bash
chown work:work /workspace 2>/dev/null || true
```

`work` 用户不设置固定 SSH 密码。远程登录默认依赖 RunPod Secret 注入的 SSH public key。

## 5. 系统工具

必须安装：

```text
git
openssh-client
openssh-server
graphviz
vim
curl
wget
fonts-noto-cjk
ffmpeg
gosu
sudo
tmux
locales
nodejs
nvtop
btop
```

Node.js 使用 NodeSource 22.x：

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
```

需要启用 UTF-8 locale：

```text
LANG=en_US.UTF-8
LANGUAGE=en_US:en
LC_ALL=en_US.UTF-8
```

## 6. Python 环境

使用 Miniforge3 + mamba 管理 Python 环境。

路径与环境名：

```text
CONDA_ROOT=/home/work/miniforge3
MAMBA_ROOT_PREFIX=/home/work/miniforge3
CONDA_ENV_PATH=/home/work/miniforge3/envs/llm-general
Python=3.11
env name=llm-general
```

交互式 shell 需要自动激活环境。写入 `/etc/bash.bashrc`：

```bash
source /home/work/miniforge3/etc/profile.d/mamba.sh
mamba activate llm-general
[ -f /home/work/.env_runpod ] && source /home/work/.env_runpod
```

## 7. 环境变量

镜像内固定环境变量：

```bash
LANG=en_US.UTF-8
LANGUAGE=en_US:en
LC_ALL=en_US.UTF-8
NVIDIA_VISIBLE_DEVICES=all
NVIDIA_DRIVER_CAPABILITIES=all
CONDA_ROOT=/home/work/miniforge3
MAMBA_ROOT_PREFIX=/home/work/miniforge3
CONDA_ENV_PATH=/home/work/miniforge3/envs/llm-general
PATH=/home/work/bin:$PATH
JUPYTERLAB_SETTINGS_DIR=/home/work/.jupyter/lab/user-settings
MPLCONFIGDIR=/home/work/.config/matplotlib
HF_HOME=/home/work/.cache/huggingface
PIP_CACHE_DIR=/home/work/.cache/pip
```

RunPod Secrets 支持：

```text
GITHUB_PERSONAL_ACCESS_TOKEN
HF_TOKEN
LEIGUOGUO_MBP_M5_RSA_PUB
```

启动时应将可安全暴露给交互式 shell 的 secrets 写入：

```text
/home/work/.env_runpod
```

权限：

```bash
chown work:work /home/work/.env_runpod
chmod 600 /home/work/.env_runpod
```

## 8. Python 依赖

依赖入口文件：

```text
requirements-general.in
```

基础依赖：

```text
jupyterlab==4.5.5
transformers
datasets
accelerate
peft
trl
bitsandbytes
sentencepiece
tokenizers
huggingface_hub
evaluate
gradio
diffusers
optimum
ipykernel
ipywidgets
numpy
pandas
matplotlib
seaborn
scikit-learn
scipy
plotly
rich
tqdm
requests
httpx
python-dotenv
pytest
ruff
black
```

安装分层：

1. 创建 mamba 环境，只包含 Python。
2. 使用 `constraints-torch-<tag>.txt` 安装 `torch torchvision torchaudio`。
3. 使用 `constraints-<tag>.txt` 安装 `requirements-general.in`。

PyTorch 单独分层的原因：PyTorch 层体积很大，普通依赖调整不应导致 PyTorch 重装。

## 9. JupyterLab

容器默认命令：

```bash
$CONDA_ENV_PATH/bin/jupyter lab
```

JupyterLab 配置：

```python
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.token = ''
c.ServerApp.allow_origin = '*'
c.ServerApp.allow_remote_access = True
c.ServerApp.disable_check_xsrf = True
c.ServerApp.root_dir = '/home/work'
```

说明：该配置面向 RunPod 受控环境。若容器直接暴露到公网，应重新启用 token 或其他访问控制。

## 10. SSH

暴露端口：

```text
22
```

sshd 配置要求：

```text
Port 22
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
```

启动时运行：

```bash
/usr/sbin/sshd
```

SSH 公钥注入规则：

- 不在 git 中保存个人 SSH 公钥明文。
- 本机公钥保存为 RunPod Secret：`LEIGUOGUO_MBP_M5_RSA_PUB`。
- 容器启动时读取该 secret 并写入 `/home/work/.ssh/authorized_keys`。

实现逻辑：

```bash
if [ -n "$LEIGUOGUO_MBP_M5_RSA_PUB" ]; then
    mkdir -p /home/work/.ssh
    printf '%s\n' "$LEIGUOGUO_MBP_M5_RSA_PUB" > /home/work/.ssh/authorized_keys
    chown -R work:work /home/work/.ssh
    chmod 700 /home/work/.ssh
    chmod 600 /home/work/.ssh/authorized_keys
fi
```

## 11. Notebook 与中文绘图

安装中文字体：

```text
fonts-noto-cjk
```

Matplotlib 配置文件：

```text
/home/work/.config/matplotlib/matplotlibrc
```

内容：

```text
font.family : Noto Sans CJK SC
axes.unicode_minus : False
```

构建时预热 matplotlib font cache。

## 12. Shell、编辑器与 Git

复制到用户目录：

```text
/home/work/.tmux.conf
/home/work/.vimrc
/home/work/bin/t
```

`t` 脚本是个人化 tmux 辅助工具。它可以保留在个人学习镜像中；如果镜像变成多人通用镜像，应单独 Review 是否需要精简或移除。

Git alias：

```bash
git config --system alias.co checkout
git config --system alias.br branch
git config --system alias.ci commit
git config --system alias.st status
```

Git 提交身份不硬编码。Dockerfile 可支持以下构建参数：

```text
GIT_USER_NAME
GIT_USER_EMAIL
```

只有参数非空时才设置：

```bash
git config --system user.name "$GIT_USER_NAME"
git config --system user.email "$GIT_USER_EMAIL"
```

## 13. Optional: 启动时拉取项目

默认不 clone 任何仓库。

如需在 Pod 启动时自动拉取项目，使用显式环境变量：

```text
STARTUP_GIT_REPO
STARTUP_GIT_DIR
```

规则：

- `STARTUP_GIT_REPO` 为空时不做任何 clone/pull。
- `STARTUP_GIT_DIR` 默认 `/home/work/project`。
- 目标目录不存在 `.git` 时执行 clone。
- 目标目录存在 `.git` 时执行 `git pull --ff-only`。
- 对 GitHub HTTPS 私有仓库，可使用 `GITHUB_PERSONAL_ACCESS_TOKEN` 生成 clone URL。
- clone/pull 失败不应阻止容器启动，但需要打印清晰日志。

## 14. 端口

必须暴露：

```text
22
8888
```

建议额外暴露：

```text
8000
```

用途：

- `8000`: FastAPI/uvicorn 或其他临时测试服务

## 15. Dockerfile 构建参数

`Dockerfile.runpod` 应支持：

```text
BASE_IMAGE
CONSTRAINTS_FILE
TORCH_CONSTRAINTS_FILE
TORCH_INDEX_URL
PYTHON_VERSION
GIT_USER_NAME
GIT_USER_EMAIL
```

默认值：

```text
BASE_IMAGE=runpod/pytorch:1.0.3-cu1281-torch280-ubuntu2404
CONSTRAINTS_FILE=constraints-cu1281.txt
TORCH_CONSTRAINTS_FILE=constraints-torch-cu1281.txt
TORCH_INDEX_URL=https://download.pytorch.org/whl/cu128
PYTHON_VERSION=3.11
GIT_USER_NAME=
GIT_USER_EMAIL=
```

## 16. 文件清单

镜像目录应包含：

```text
llm-general/
  IMAGE_SPEC.md
  Dockerfile.runpod
  .dockerignore
  entrypoint.sh
  configure.sh
  check_env.py
  requirements-general.in
  constraints-cu1281.txt
  constraints-cu1263.txt
  constraints-torch-cu1281.txt
  constraints-torch-cu1263.txt
  build-push-commit.sh
  .tmux.conf
  .vimrc
  t
```

## 17. 构建、Pin 与发布

`build-push-commit.sh` 应支持：

1. 构建所有 tags。
2. `--pin` 模式：运行镜像并执行 `pip freeze --exclude-editable`，写回对应 constraints 文件；该模式不 push、不 commit。
3. 普通模式：build 后 push 到 Docker Hub。
4. 如果 git 有变化，可以生成 commit message、commit、push。

`--pin` 输出需要过滤：

```bash
grep -v ' @ file:///'
grep -v '^\['
```

发布目标：

```text
goosmanlei/runpod-learn-general:cu1281
goosmanlei/runpod-learn-general:cu1263
```

## 18. 环境检查

`check_env.py` 应检查：

- Python 版本
- PyTorch 版本
- CUDA 是否可用
- CUDA version
- cuDNN version
- GPU 数量、名称、显存
- 一个简单 CUDA matmul
- `bitsandbytes`
- `triton`
- 常见库版本：
  - `transformers`
  - `datasets`
  - `accelerate`
  - `peft`
  - `trl`
  - `diffusers`
  - `tokenizers`
  - `safetensors`
  - `huggingface_hub`
  - `gradio`
  - `numpy`
  - `pandas`
  - `matplotlib`
  - `sklearn`
  - `scipy`
  - `seaborn`
  - `pytest`
  - `ruff`

常用命令：

```bash
python /home/work/check_env.py
```

## 19. RunPod 使用方式

启动后默认服务：

- JupyterLab: `8888`
- SSH: `22`
- shell 自动激活 `llm-general`
- RunPod Secrets 写入 `/home/work/.env_runpod`

本机 SSH 登录依赖：

- RunPod Secret `LEIGUOGUO_MBP_M5_RSA_PUB` 已配置为本机公钥。
- Pod 暴露或映射 SSH 端口。
- 容器启动脚本已写入 `/home/work/.ssh/authorized_keys`。

## 20. Review Checklist

根据本文档生成或修改镜像文件时，检查：

- 镜像不硬编码任何课程仓库、项目仓库或个人代码仓库。
- git 中不存在私钥、公钥明文、token 或其他 secrets。
- conda 环境名统一为 `llm-general`。
- `CONDA_ENV_PATH` 与环境名一致。
- PyTorch 只在 torch constraints 层安装。
- 普通 Python 依赖来自 `requirements-general.in`。
- constraints 文件与目标 CUDA tag 匹配。
- `entrypoint.sh` 不强制 clone 任何仓库。
- `LEIGUOGUO_MBP_M5_RSA_PUB` 只从运行时环境变量读取。
- `/home/work/.env_runpod` 权限为 `600`。
- `/home/work/.ssh` 权限为 `700`，`authorized_keys` 权限为 `600`。
- JupyterLab 监听 `0.0.0.0:8888`。
- SSH 启动，root login 关闭，password authentication 关闭。

## 21. 待决策项

- 是否保留个人 `.tmux.conf`、`.vimrc`、`t` 脚本。
- 是否实现可选的 `STARTUP_GIT_REPO` clone/pull 机制。
