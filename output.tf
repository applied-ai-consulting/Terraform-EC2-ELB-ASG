output "instance_ids" {
    value = ["${aws_instance.Github-Runner.*.public_ip}"]
}
output "elb_dns_name" {
  value = "${aws_elb.Github-Runner-ELB.dns_name}"
}