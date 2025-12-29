# 0. Data Source: Get Available AZs dynamically
data "aws_availability_zones" "available" {
  state = "available"
}

# checkov:skip=CKV2_AWS_11: "Flow Logs cost extra money, skipping for learning lab"

# 1. Create our VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }

}

# 2. Create a Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main.id
  
  count      = length(var.public_subnets_cidr)   
  # instead of writing two seperate resource blocks ("public 1 & public 2"), we write one that loops
  cidr_block = var.public_subnets_cidr[count.index]   
  # if I ever want 3 subnets, I'd just change the variable list for scalability (DRY Practices - Don't Repeat Yourself) 

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  # for resillience, we don't hardcode regions so using a data block, we ask AWS for a list of healthy available zones
  # and pick the first one for subnet 1, and the second for subnet 2, making our code region-agnostic
  
  map_public_ip_on_launch = true
  # without it, any server I'd launch here would only get a private IP, and be unreachable from the internet so we must have a public IP

  tags = { # dynamically generate names so that in a real account with hundreds of subnets, finding the right one is easy
    Name = "${var.project_name}-public-${count.index + 1}"
    Tier = "Public" # aids in ease of automation, when other tools need to look for our subnets
  }
}

# 3. Create a Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main.id
  count      = length(var.private_subnets_cidr)
  cidr_block = var.private_subnets_cidr[count.index]

  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-private-${count.index + 1}"
    Tier = "Private"
  }
}

# 4. Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}

# 5. Create a Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# 6. Create a Public Route Association
resource "aws_route_table_association" "public_rt_assoc" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}