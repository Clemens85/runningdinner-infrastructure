# The main records for Sendgrid are in the dns module and need to be migrated here

resource "aws_route53_record" "sendgrid-dmarc" {
  name = "_dmarc.mail.runyourdinner.eu"
  type = "TXT"
  zone_id = data.aws_route53_zone.runningdinner.id
  records = ["v=DMARC1; p=none;"]
  ttl = 300
}
