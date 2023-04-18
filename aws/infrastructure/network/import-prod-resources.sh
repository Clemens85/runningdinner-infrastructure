#! /bin/bash

CUR_DIR_TF=$(pwd)

cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

../tf.sh prod network init

../tf.sh prod network import aws_iam_user.ci_user ci_user
../tf.sh prod network import aws_iam_policy.ci-user-policy arn:aws:iam::332135779582:policy/ci-user-policy
../tf.sh prod network import aws_iam_user_policy_attachment.ci-user-policy_attachment ci_user/arn:aws:iam::332135779582:policy/ci-user-policy

cd $CUR_DIR_TF
