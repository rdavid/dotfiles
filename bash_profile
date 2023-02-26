#!/bin/bash
if [ -f ~/.bashrc ]; then
	# shellcheck disable=SC1090 # File not following.
  source ~/.bashrc
fi

export PATH="$HOME/.cargo/bin:$PATH"
