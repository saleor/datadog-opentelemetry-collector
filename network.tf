resource "aws_vpc" "vpc" {
  cidr_block = var.network_cidr_block
  tags = {
    Name = var.name
  }
}

resource "aws_subnet" "public" {
  for_each = { for index, zone in var.availability_zones : zone => {
    index  = index
    suffix = substr(zone, -1, -1)
  } }

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 3, each.value.index * 2)
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-public-${each.value.suffix}"
  }
}

resource "aws_subnet" "private" {
  for_each = { for index, zone in var.availability_zones : zone => {
    index  = index
    suffix = substr(zone, -1, -1)
  } }

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 3, each.value.index * 2 + 1)
  availability_zone = each.key

  tags = {
    Name = "${var.name}-private-${each.value.suffix}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.name}-igw"
  }
}

resource "aws_eip" "nat_gateway" {
  tags = {
    Name = "${var.name}-nat"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public[var.availability_zones[0]].id

  tags = {
    Name = "${var.name}-nat"
  }

  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.name}-public"
  }
}

resource "aws_route_table" "private" {
  for_each = toset(var.availability_zones)

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "${var.name}-private-${substr(each.key, -1, -1)}"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
