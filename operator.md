## AWS VPC Peering Connection

A VPC Peering Connection is a networking connection between two VPCs that enables routing traffic between them using private IP addresses. VPC peering can connect VPCs within the same region or across different regions, making it possible to share resources such as EC2 instances, RDS databases, and other AWS services without exposing them to the internet.

### Design Decisions

This module is designed with the following key principles:

- **Provider Configuration**: Separate provider setups for the requester and accepter VPCs to handle cross-account and cross-region peering.
- **VPC Peering Connections**: Conditional creation of the accepter VPC and its related resources based on the input configuration.
- **Route Configuration**: Automatic route table updates to facilitate bi-directional communication between the VPCs.
- **Auto Acceptance**: Configurable auto-accept for the accepter side of the peering connection to streamline the setup.
- **DNS Resolution**: Enable DNS resolution across the peered VPCs to facilitate easy resource discovery.

### Runbook

#### VPC Peering Connection Not Established

If the peering connection isn't active, you can verify its status with AWS CLI:

```sh
aws ec2 describe-vpc-peering-connections --filter "Name=status-code,Values=pending-acceptance,active" 
```

You should see details and the current status of the VPC peering connections. Ensure it is `active`.

#### Route Tables Not Configured Properly

If VPCs aren't communicating, ensure route tables have the correct routes:

```sh
aws ec2 describe-route-tables --filters Name=vpc-id,Values=<your_vpc_id>
```

Check if the route table entries include routes for the peered VPC CIDR blocks.

#### DNS Resolution Issues

To verify DNS resolution settings, check VPC attributes:

```sh
aws ec2 describe-vpc-attribute --vpc-id <vpc-id> --attribute enableDnsSupport
aws ec2 describe-vpc-attribute --vpc-id <vpc-id> --attribute enableDnsHostnames
```

Ensure both `enableDnsSupport` and `enableDnsHostnames` are set to `true`.

#### Peering Connection Rejected or Pending Acceptance

If the connection status is `rejected` or `pending-acceptance`, manually accept the peering connection using:

```sh
aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id <connection-id>
```

Alternatively, reject unwanted connections:

```sh
aws ec2 reject-vpc-peering-connection --vpc-peering-connection-id <connection-id>
```

