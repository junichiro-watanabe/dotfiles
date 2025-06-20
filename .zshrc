# homebrew関連のPATH
eval "$(/opt/homebrew/bin/brew shellenv)"

# asdf のPATH
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

# git補完設定
fpath=($(brew --prefix)/share/zsh/site-functions $fpath)
autoload -Uz compinit && compinit -i

# git色付け
function rprompt-git-current-branch {
  local branch_name st branch_status
 
  if [ ! -e  ".git" ]; then
    # git 管理されていないディレクトリは何も返さない
    return
  fi
  branch_name=`git rev-parse --abbrev-ref HEAD 2> /dev/null`
  st=`git status 2> /dev/null`
  if [[ -n `echo "$st" | grep "^nothing to"` ]]; then
    # 全て commit されてクリーンな状態
    branch_status="%F{green}"
  elif [[ -n `echo "$st" | grep "^Untracked files"` ]]; then
    # git 管理されていないファイルがある状態
    branch_status="%F{red}?"
  elif [[ -n `echo "$st" | grep "^Changes not staged for commit"` ]]; then
    # git add されていないファイルがある状態
    branch_status="%F{red}+"
  elif [[ -n `echo "$st" | grep "^Changes to be committed"` ]]; then
    # git commit されていないファイルがある状態
    branch_status="%F{yellow}!"
  elif [[ -n `echo "$st" | grep "^rebase in progress"` ]]; then
    # コンフリクトが起こった状態
    echo "%F{red}!(no branch)"
    return
  else
    # 上記以外の状態の場合
    branch_status="%F{blue}"
  fi
  # ブランチ名を色付きで表示する
  echo "${branch_status}[${branch_name}]%F{default}"
}
 
# プロンプトが表示されるたびにプロンプト文字列を評価、置換する
setopt prompt_subst
 
# プロンプトの右側にメソッドの結果を表示させる
RPROMPT='`rprompt-git-current-branch`'

# プロンプト表示変更
export PS1="%n:%~ %1 %# "

# エイリアス
alias gs="git status"
alias gch="git checkout"
alias gcm="git commit"
alias gd="git diff"
alias gb="git branch"
alias gp="git pull origin"
alias gf="git fetch origin"
alias gph="git push --set-upstream origin HEAD"
alias gl="git log --oneline"
alias glg="git log --oneline --graph"
alias gfup="git fetch upstream"
alias grau="git rebase -i --autosquash"
alias gmupdev="git merge upstream/main"
alias gsyncpayroll="gh repo sync junichiro-watanabe/freee-payroll -b main"
alias railsrun="bundle ex rails s -p 3001 -b 0.0.0.0"
alias resrun="TERM_CHILD=1 QUEUE=* bundle exec rake environment resque:work"
alias yarnwatch="yarn && NODE_OPTIONS='--max-old-space-size=8192' DISABLE_FORK_TS_CHECKER_WEBPACK_PLUGIN=1 XDISABLE_UNUSED_FILES_WEBPACK_PLUGIN=1 XWEBPACK_ENTRIES='application,settings' yarn watch"
alias mysqllogin="mysql --port 23306 --host 127.0.0.1 --user root -proot"
alias brails="bundle ex rails"
alias brspec="bundle ex rspec"

alias sshdev="ssh -Y junichiro-watanabe-eng-dev"
alias awslogin="saml2aws login --skip-prompt --force"

alias ecsexe='aws ecs execute-command --cluster bundle-ecs-cluster --task $(aws ecs list-tasks --cluster bundle-ecs-cluster --service-name bundle-ecs-worker | jq --raw-output ".taskArns[0]" | awk -F/ "{print $NF}") --container sidekiq --interactive --command "bash"'
alias unsetaws="unset AWS_ACCESS_KEY_ID AWS_ACCESS_KEY_ID AWS_SESSION_TOKEN"

alias k="kubectl"
alias kb="kubectl -n bundle"
alias kc="kubectl config"
alias kcus="kubectl config use-context staging-bundle"
alias kcup="kubectl config use-context production-bundle"
alias kbexe='kubectl -n bundle exec -it $(kubectl -n bundle get pod | grep -E "bundle-console-write-[a-z0-9]+-[a-z0-9]+") -- /bin/bash'

startdev() {
  developer=junichiro-watanabe

  # get instance-id
  instance_id=$(
      aws ec2 describe-instances --filters "Name=tag:Name,Values=${developer}-eng-dev" | jq '.Reservations[0].Instances[0].InstanceId' -r
  )

  # start instance
  aws ec2 start-instances --instance-ids $instance_id
  echo "start instance: $instance_id"
  aws ec2 wait instance-running --instance-ids $instance_id
  echo "running"
  aws ec2 wait instance-status-ok --instance-ids $instance_id
  echo "status ok"
}

stopdev() {
  developer=junichiro-watanabe

  # get instance-id
  instance_id=$(
      aws ec2 describe-instances --filters "Name=tag:Name,Values=${developer}-eng-dev" | jq '.Reservations[0].Instances[0].InstanceId' -r
  )

  # stop instance
  aws ec2 stop-instances --instance-ids $instance_id
  echo "stop instance: $instance_id"
}

# direnvの設定
eval "$(direnv hook zsh)"

# EKS upgradeで追加
alias xargs="gxargs"

# bin/rails コマンドを実行するために必要
export DISABLE_SPRING=true
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

# yarn add global でインストールしたコマンドを実行するために必要
export PATH="$PATH:$HOME/.yarn/bin"

# libpq を使うために必要
export PATH="$PATH:/opt/homebrew/opt/libpq/bin"

# fdev から環境変数を設定
eval $(fdev pat load)
eval "$(fdev secrets --enable-encryption load zuora_sandbox_api)"
eval "$(fdev secrets --enable-encryption load aws_ses_credentials)"

# bundleサービス起動
bootbundle() {
    tmux has-session -t bundle
    if [ $? != 0 ]
    then
        tmux new-session -s bundle -n "rails" -c ~/C-FO/bundle -d
        tmux new-window -n grpc -c ~/C-FO/bundle
        tmux new-window -n sidekiq -c ~/C-FO/bundle
        tmux new-window -n client -c ~/C-FO/bundle

        tmux send-keys -t rails.0 'bin/rails s' C-m
        tmux send-keys -t grpc.0 'bin/gruf' C-m
        tmux send-keys -t sidekiq.0 'bin/sidekiq' C-m
        tmux send-keys -t client.0 'yarn client:start' C-m
    fi
    tmux attach -t bundle:rails
}

# bundleサービス停止
killbundle() {
    # ctrl + c 送信
    tmux list-panes -s -F '#{session_name}:#{window_index}' -t bundle | while read pane; do
      tmux send-keys -t $pane C-c
    done

    # 少し待つ
    sleep 1

    # session kill
    tmux kill-session -t bundle
}

# payrollサービス起動
bootpayroll() {
    tmux has-session -t payroll
    if [ $? != 0 ]
    then
        tmux new-session -s payroll -n "rails" -c ~/C-FO/freee-payroll -d
        tmux new-window -n client -c ~/C-FO/freee-payroll

        tmux send-keys -t rails.0 'railsrun' C-m
        tmux send-keys -t client.0 'yarnwatch' C-m
    fi
    tmux attach -t payroll:rails
}

# payrollサービス停止
killpayroll() {
    # ctrl + c 送信
    tmux list-panes -s -F '#{session_name}:#{window_index}' -t payroll | while read pane; do
      tmux send-keys -t $pane C-c
    done

    # 少し待つ
    sleep 1

    # session kill
    tmux kill-session -t payroll
}