#!/bin/bash

mkdir -p "$HOME/.hammerspoon"

if [ -f "$HOME/.hammerspoon/init.lua" ]; then
  echo "init.lua が存在します"
  cat $HOME/.hammerspoon/init.lua
  echo "存在する $HOME/init.lua を削除してからシンボリックリンクを作成します"
  rm $HOME/.hammerspoon/init.lua
fi

ln -fs $HOME/dotfiles/config/hammerspoon/init.lua $HOME/.hammerspoon/init.lua
echo "$HOME/dotfiles/config/hammerspoon/init.lua -> $HOME/.hammerspoon/init.lua"