#! /bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

set +e

../infrastructure/tf.sh dev network init
../infrastructure/tf.sh dev network apply -auto-approve

../infrastructure/tf.sh dev database init
../infrastructure/tf.sh dev database apply -auto-approve

../infrastructure/tf.sh dev app init
../infrastructure/tf.sh dev app apply -auto-approve

../infrastructure/tf.sh dev dns init
../infrastructure/tf.sh dev dns apply -auto-approve