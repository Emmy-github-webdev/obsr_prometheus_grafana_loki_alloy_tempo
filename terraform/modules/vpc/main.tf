##########################
# VPC
##########################
resource "aws_vpc" "observastack_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-vpc"
    }
  )
}

############################
# Internet Gateway
############################
resource "aws_internet_gateway" "observastack_igw" {
  vpc_id = aws_vpc.observastack_vpc.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-igw"
    }
  )
}

###########################
# Public Subnets
###########################
resource "aws_subnet" "pub_subnet" {
  for_each = {
    for index, az in var.availability_zones :
    az => index
  }

  vpc_id                  = aws_vpc.observastack_vpc.id
  availability_zone       = each.key
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, each.value)
  map_public_ip_on_launch = false

  tags = merge(
    local.common_tags,
    {
      Name                     = "${local.name_prefix}-public-${each.key}"
      Tier                     = "public"
      "kubernetes.io/role/elb" = "1"
    }
  )
}

############################
# Private application subnets
############################
resource "aws_subnet" "priv_subnet" {
  for_each = {
    for index, az in var.availability_zones :
    az => index
  }

  vpc_id            = aws_vpc.observastack_vpc.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, each.value + 4)

  tags = merge(
    local.common_tags,
    {
      Name                              = "${local.name_prefix}-private-${each.key}"
      Tier                              = "private"
      "kubernetes.io/role/internal-elb" = "1"
    }
  )
}

#############################
# Database subnets
#############################
resource "aws_subnet" "database" {
  for_each = {
    for index, az in var.availability_zones :
    az => index
  }

  vpc_id            = aws_vpc.observastack_vpc.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, each.value + 8)

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-database-${each.key}"
      Tier = "database"
    }
  )
}

############################
# Public route table
############################
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.observastack_vpc.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-public-rt"
    }
  )
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.observastack_igw.id
}

resource "aws_route_table_association" "public_rt_association" {
  for_each = aws_subnet.pub_subnet

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rt.id
}

#############################
# Private route table   
#############################
resource "aws_route_table" "private_rt" {
  for_each = aws_subnet.priv_subnet

  vpc_id = aws_vpc.observastack_vpc.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-private-rt-${each.key}"
    }
  )
}

resource "aws_route_table_association" "private_rt_association" {
  for_each = aws_subnet.priv_subnet

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_rt[each.key].id
}

#############################
# Database route table  
#############################
resource "aws_route_table" "database" {
  for_each = aws_subnet.database

  vpc_id = aws_vpc.observastack_vpc.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-database-rt-${each.key}"
    }
  )
}

resource "aws_route_table_association" "database" {
  for_each = aws_subnet.database

  subnet_id      = each.value.id
  route_table_id = aws_route_table.database[each.key].id
}


##############################
# Nat Gateways
##############################
resource "aws_nat_gateway" "nat_gateway" {
  for_each = var.enable_nat_gateway ? (
    var.single_nat_gateway
    ? { "${var.availability_zones[0]}" = 0 }
    : {
      for index, az in var.availability_zones :
      az => index
    }
  ) : {}

  allocation_id = aws_eip.eip_nat[each.key].id
  subnet_id     = aws_subnet.pub_subnet[each.key].id

  depends_on = [
    aws_internet_gateway.observastack_igw
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nat-${each.key}"
    }
  )
}

resource "aws_route" "private_nat" {
  for_each = var.enable_nat_gateway ? aws_route_table.private_rt : {}

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = aws_nat_gateway.nat_gateway[
    var.single_nat_gateway
    ? var.availability_zones[0]
    : each.key
  ].id
}


#############################
# Elastic IPs for NAT Gateways
#############################
resource "aws_eip" "eip_nat" {
  for_each = var.enable_nat_gateway ? (
    var.single_nat_gateway
    ? { "${var.availability_zones[0]}" = 0 }
    : {
      for index, az in var.availability_zones :
      az => index
    }
  ) : {}

  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nat-eip-${each.key}"
    }
  )
}

##############################
# VPC Flow Logs
##############################
resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/${local.name_prefix}/flow-logs"
  retention_in_days = var.flow_logs_retention_days

  tags = local.common_tags
}

data "aws_iam_policy_document" "flow_logs_assume_role" {
  count = var.enable_flow_logs ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${local.name_prefix}-vpc-flow-logs"

  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume_role[0].json

  tags = local.common_tags
}

data "aws_iam_policy_document" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.flow_logs[0].arn}:*"
    ]
  }
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${local.name_prefix}-vpc-flow-logs"

  role   = aws_iam_role.flow_logs[0].id
  policy = data.aws_iam_policy_document.flow_logs[0].json
}

resource "aws_flow_log" "flow_log" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id = aws_vpc.observastack_vpc.id

  traffic_type = "ALL"

  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-flow-logs"
    }
  )
}