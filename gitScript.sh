SHELL=${SHELL:-/bin/bash}
curbranch=$(git symbolic-ref HEAD 2>/dev/null)
if [ $? -eq 0 ]; then
  curbranch=${curbranch##*/}
else
  curbranch=$(git name-rev --name-only --always HEAD)
fi

git checkout master
git svn rebase &&
  for branch in $(git branch | grep -v \\\*); do
    git checkout "$branch"
    if [[ -n "$( git "config branch.$branch.remote" )" ]]; then
      # remote tracking branch
      git svn rebase
      continue
    fi
    fromrev="$( git log --pretty=tformat:%H $branch '^master' | tail -1 )"
    if [[ -z "$fromrev" ]]; then
      git merge --ff-only --no-stat master || ( echo "Something went wrong while rebasing $branch"; echo "Exit this shell to continue with other branches"; $SHELL )
    else
      git rebase --onto master "${fromrev}~1" "$branch" || ( echo "Something went wrong while rebasing $branch"; echo "Exit this shell to continue with other branches"; $SHELL )
    fi
  done
git checkout "$curbranch"