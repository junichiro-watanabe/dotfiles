#!/bin/bash

mkdir -p $HOME/Library/Application\ Support/Rectangle

if [ -f "$HOME/Library/Application\ Support/Rectangle/RectangleConfig.json" ]; then
  echo "RectangleConfig.json が存在します"
  cat $HOME/Library/Application\ Support/Rectangle
  echo "存在する $HOME/RectangleConfig.json を削除してからシンボリックリンクを作成します"
  rm $HOME/Library/Application\ Support/Rectangle
fi

ln -fs $HOME/dotfiles/config/rectangle/RectangleConfig.json $HOME/Library/Application\ Support/Rectangle/RectangleConfig.json
echo "$HOME/dotfiles/config/rectangle/RectangleConfig.json -> $HOME/Library/Application\ Support/Rectangle/RectangleConfig.json"