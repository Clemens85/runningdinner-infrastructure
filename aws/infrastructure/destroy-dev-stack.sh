#! /bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

set +e

../infrastructure/tf.sh dev dns init
../infrastructure/tf.sh dev dns destroy -auto-approve

../infrastructure/tf.sh dev app init
../infrastructure/tf.sh dev app destroy -auto-approve

../infrastructure/tf.sh dev database init
../infrastructure/tf.sh dev database destroy -auto-approve

../scripts/delete-access-tokens-ci-user.sh dev # Otherwise terraform cannot delete ci-user
../infrastructure/tf.sh dev network init
../infrastructure/tf.sh dev network destroy -auto-approve