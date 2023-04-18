#! /bin/bash

CUR_DIR_TF=$(pwd)

cd "$( dirname "${BASH_SOURCE[0]}" )" || exit 1

../tf.sh prod dns init

../tf.sh prod dns import aws_route53_zone.runningdinner ZX9JVHNHZRJLS

../tf.sh prod dns import aws_route53_record.google-site-verification ZX9JVHNHZRJLS_runyourdinner.eu_TXT
../tf.sh prod dns import aws_route53_record.sendgrid-s1-domainkey ZX9JVHNHZRJLS_s1._domainkey.runyourdinner.eu_CNAME
../tf.sh prod dns import aws_route53_record.sendgrid-s2-domainkey ZX9JVHNHZRJLS_s2._domainkey.runyourdinner.eu_CNAME
../tf.sh prod dns import aws_route53_record.sendgrid-mail ZX9JVHNHZRJLS_mail.runyourdinner.eu_CNAME

../tf.sh prod dns import aws_route53_record.cloudfront ZX9JVHNHZRJLS_runyourdinner.eu_A

cd $CUR_DIR_TF