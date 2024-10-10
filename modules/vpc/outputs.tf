output "id" {
  value = module.vpc.vpc_id
}

output "nat_public_ip" {
  value = module.vpc.nat_public_ips.0
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}
