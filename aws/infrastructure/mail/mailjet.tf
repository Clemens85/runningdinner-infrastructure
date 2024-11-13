
resource "aws_route53_record" "mailjet_runningdinner_validation" {
  zone_id = data.aws_route53_zone.runningdinner.zone_id
  name    = "mailjet._46a1ea7b.message.runyourdinner.eu"
  type    = "TXT"
  ttl     = "300"
  records = ["46a1ea7b1f6df60ba41e145725f7d3bf"]
}

resource "aws_route53_record" "mailjet_dkim_validation" {
  zone_id = data.aws_route53_zone.runningdinner.zone_id
  name    = "mailjet._domainkey.message.runyourdinner.eu."
  type    = "TXT"
  ttl     = "300"
  records = ["k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDQD8Sgsd4Sd7g0STUt4YV4vbxUfMX1DM85YgAEtD/bGbUsUWL1ao2MjkAJsA6LkD1+1fKQ5b4jHnLfow0MIeloaddhbgAzR+BkB0OYLdVLlEyE1/ry6zzPuZI7pNEcSUp5WbFgIBfeOCEaKCY33D0uZxcZDu/kbKQe90l1LQA26QIDAQAB"]
}

resource "aws_route53_record" "mailjet_spf_validation" {
  zone_id = data.aws_route53_zone.runningdinner.zone_id
  name    = "message.runyourdinner.eu"
  type    = "TXT"
  ttl     = "300"
  records = ["v=spf1 include:spf.mailjet.com ?all"]
}