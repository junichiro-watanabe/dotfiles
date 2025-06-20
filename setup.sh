#!/bin/bash

set -e

log() { echo "==> $*"; }
abort() { echo "!!! $*" >&2; exit 1; }

create_symbolic_link_of_dotfiles() {
  for dotfile in .?*; do
    case "$dotfile" in
      ".." ) continue ;;
      ".DS_Store" ) continue ;;
      ".idea" ) continue ;;
      "*.elc" ) continue ;;
      ".git" | ".gitignore" | ".gitmodules" | ".module" ) continue ;;
      * )
        if [ -f "$HOME/$dotfile" ]; then
          echo "${dotfile} が存在します"
          echo "------ $HOME/${dotfile} ------"
          cat $HOME/${dotfile}
          echo "------"
          echo "存在する $HOME/${dotfile} を削除してからシンボリックリンクを作成します"

          rm $HOME/${dotfile}
        fi

        ln -fs $HOME/dotfiles/${dotfile} $HOME
        echo "~/${dotfile} -> $HOME/dotfiles/${dotfile}"
        ;;
    esac
  done
}

run_scripts() {
  find ./scripts -type f -name "*.sh" | sort | while read -r script; do
    echo "実行中: $(basename "$script")"
    chmod +x "$script" && "$script"

    # 実行結果を確認
    if [ $? -eq 0 ]; then
      echo "$(basename "$script") が正常に実行されました"
    else
      echo "警告: $(basename "$script") の実行中にエラーが発生しました"
    fi
    echo "-----------------------------------"
  done

  echo "全てのスクリプトの実行が完了しました"
}

echo "Xcode をインストールします..."
xcode-select --install

echo "homebrew をインストールします..."
which /opt/homebrew/bin/brew >/dev/null 2>&1 || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "brew doctor を実行します..."
which /opt/homebrew/bin/brew >/dev/null 2>&1 && brew doctor

echo "brew update を実行します..."
which /opt/homebrew/bin/brew >/dev/null 2>&1 && brew update --verbose

log "シンボリックリンクを作成します..."
create_symbolic_link_of_dotfiles

echo ".Brewfile で管理しているアプリケーションをインストールします..."
which /opt/homebrew/bin/brew >/dev/null 2>&1 && brew bundle --file ./.Brewfile --verbose

echo "brew cleanup を実行します..."
which brew >/dev/null 2>&1 && brew cleanup --verbose

log "scriptフォルダ内のシェルスクリプトを実行します..."
run_scripts