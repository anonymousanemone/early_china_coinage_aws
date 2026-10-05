DO NOT PULL INTO THIS FOLDER FROM UPSTREAM.

This scripts/ folder is maintained only in this fork. Upstream's scripts are
not wanted here. When merging upstream, restore this folder to our version
before committing:

    git fetch upstream
    git merge --no-commit upstream/main
    git restore --source=HEAD --staged --worktree -- scripts/
    git commit

Files in this folder:

    deploy-ec2.sh
    pg-to-mysql.py
    redeploy-ans.sh
    setup-ec2.sh
    README.txt
