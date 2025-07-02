#!/bin/bash

set -e

# Configuration
PYTHON_VERSION="3.11.7"
VENV_PATH="/opt/open-interpreter"
GLOBAL_SYMLINK=true  # set to false to skip global symlink
ENV_FILE="$VENV_PATH/.env"

# 1. Install build dependencies
apt update
apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev curl libsqlite3-dev wget libbz2-dev

# 2. Download and build Python 3.11 if not installed
if ! command -v python3.11 >/dev/null 2>&1; then
  echo "Installing Python $PYTHON_VERSION..."
  cd /tmp
  wget https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz
  tar -xf Python-$PYTHON_VERSION.tgz
  cd Python-$PYTHON_VERSION
  ./configure --enable-optimizations
  make -j$(nproc)
  make altinstall
else
  echo "Python 3.11 already installed."
fi

# 3. Create venv directory
mkdir -p $VENV_PATH

# 4. Create Python virtual environment
python3.11 -m venv $VENV_PATH/Open-Interpreter

# 5. Activate venv and upgrade pip
source $VENV_PATH/Open-Interpreter/bin/activate
pip install --upgrade pip

# 6. Install open-interpreter
pip install open-interpreter

# 7. Create a sample .env file for API keys/environment variables
cat > $ENV_FILE << EOF
# Add your environment variables here
# Example:
# OPENAI_API_KEY=your_api_key_here
EOF

echo "Created environment file at $ENV_FILE. Please add your API keys."

# 8. Optionally symlink the interpreter executable globally
if [ "$GLOBAL_SYMLINK" = true ]; then
  ln -sf $VENV_PATH/Open-Interpreter/bin/interpreter /usr/local/bin/interpreter
  echo "Symlink created: interpreter is globally available."
fi

echo "Installation complete! To use, run:"
echo "  source $VENV_PATH/Open-Interpreter/bin/activate"
echo "  interpreter --help"

exit 0