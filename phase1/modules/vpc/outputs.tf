output "vpc_id"                 { value = aws_vpc.this.id }
output "vpc_cidr"               { value = aws_vpc.this.cidr_block }
output "public_subnet_ids"      { value = aws_subnet.public[*].id }
output "private_subnet_ids"     { value = aws_subnet.private[*].id }
output "public_route_table_id"  { value = aws_route_table.public.id }
output "private_route_table_id" { value = aws_route_table.private.id }

output "subnets_to_privatelink" {
  value = {
    for s in aws_subnet.private :
    s.availability_zone_id => s.id
  }
}
