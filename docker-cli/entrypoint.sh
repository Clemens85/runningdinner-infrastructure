#!/bin/sh

# symlink all files from the host's ~/.ssh directory
for FILE in /home/tf_user/.ssh-host/*
do
  cp "$FILE" /home/tf_user/.ssh
  chmod 600 /home/tf_user/.ssh/"$(basename "$FILE")"
done

# symlink all files from the host's ~/.aws directory
mkdir -p /home/tf_user/.aws
for FILE in /home/tf_user/.aws-host/*
do
  cp "$FILE" /home/tf_user/.aws
  chmod 600 /home/tf_user/.aws/"$(basename "$FILE")"
done

/bin/bash