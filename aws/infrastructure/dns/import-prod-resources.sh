#! /bin/bash

CUR_DIR_TF=$(pwd)

cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

../tf.sh prod dns init

../tf.sh prod dns import aws_route53_zone.runningdinner ZX9JVHNHZRJLS

cd $CUR_DIR_TF