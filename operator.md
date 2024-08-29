## AWS VPC Peering Connection

A VPC Peering Connection is a networking connection between two VPCs that enables routing traffic between them using private IP addresses. VPC peering can connect VPCs within the same region or across different regions, making it possible to share resources such as EC2 instances, RDS databases, and other AWS services without exposing them to the internet.

### Use Cases
#### Network Migration
A peering connection can help facilitate a network migration by allowing services to be migrated from the old VPC to the new VPC individually over time while maintaining network connectivity, as opposed to a riskier all-at-once migration.
#### Multi-Region
By peering VPCs between two regions, they can both communicate privately and effectively act as a single multi-region private network.
#### Multi-Account
Peering connections can go accross AWS accounts, offering many benefits such as workload isolation, simplified account migration and enterprise capabilities (communicate across accounts without cloud account access).

### Design
This bundle is designed for two scenarios:
1. Peering two VPCs, both of which are provisioned by Massdriver and in the same account
2. Peering two VPCs, only one of which is provisioned and managed by Massdriver

#### Both VPCs in Same Account Provisioned by Massdriver
In the first case, where both VPCs are managed by Massdriver and exist in the same AWS account, the user should connect both VPCs to the connection ports on the bundle (one to `requester` the other to `accepter`). The fields in the bundle configuration ("Remote VPC ARN" and "Remote VPC CIDR") can be ignored since these values can be pulled from the accepter VPC. It doesn't matter which VPC is the requester or accepter, they are functionally equivalent. In this scenario, the bundle will handle all the proper configuration for the peering connection, including establishing the connection, accepting it, and updating the route tables of both VPCs to enable communication across the VPCs.

#### VPCs in Separate Accounts, or Only One VPC Managed by Massdriver
In the second case, where one VPC isn't managed by Massdriver, or the VPCs exist in a different account, only one of the connections is used: the `requester` connection. In this case, the bundle won't be able to "accept" the peering connection on behalf of the "accepter" VPC. Additionally, the fields in the bundle configuration ("Remote VPC ARN" and "Remote VPC CIDR") will need to be specified so the bundle can properly initiate the peering connection, and update the route tables of the Massdriver-managed requester VPC. Additional steps will need to be performed by the user in the AWS console to complete the peering connection.

##### Steps to Manually Accept Peering Connection
This is a summary of the tasks required to [accept a peering connection](https://docs.aws.amazon.com/vpc/latest/peering/accept-vpc-peering-connection.html) and [update the route tables](https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-routing.html) of the VPC.
1. Log into the AWS console for the "Accepter" account
2. Navigate to the VPC configuration screen
3. In the navigation pane, choose "Peering Connections"
4. Select the pending VPC peering connection and choose "Actions" -> "Accept request"
5. Choose "Modify route tables now", or select "Route Tables" in the left side navigation pane
6. Filter by the VPC ID of accepter
7. For every route table associated with the VPC perform the following steps:
    1. Select the route table, and choose "Actions" -> "Edit Routes"
    2. Select Add Route
    3. For Destination, use the CIDR of the **Requester** VPC (the one managed by Massdriver)
    4. For Target, select "Peering Connection" and select the peering connection that was just created
    5. Select "Save changes"
8. (Optional) If you would like DNS resolution across the peering connection, select the peering connection and choose "Actions" -> "Edit DNS settings" and select both "Allow accepter VPC" and "Allow requester VPC".

### Design Decisions

This module is designed with the following key principles:

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
