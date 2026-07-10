# Setup template msr/1101/sel25924

This template groups a specific selection of components installed on microservices runtime 11.1:

- Adapters
  - 6.0 SP1 for AS 400
  - 10.11 for IBM Power
  - 10.3 for JDBC
  - 9.6 for Apache Kafka
- CloudStreams Server 11.1
- End-to-End Monitoring
  - Integration Server or Microservices Runtime Plug-in 11.1
- Infrastructure
  - End-to-End Monitoring Core 11.1
- Integration Server or Microservices Runtime Libraries
  - Common Directory Service Support 11.1
  - Custom Character Encoding Support 11.1
  - External RDBMS Support 11.1
- Integration Server or Microservices Runtime Packages
  - Central User Management 11.1
  - Monitor 11.1

See [installer selection trace](./products-installer-view.txt) for details.

This selection is intended to be used for technology patters related to ESB use cases, in particular:

- Asynchronous and event-driven communication via messaging
- Reliable messaging with persistent audited and resubmittable discards
- Microservices
- SOA

Default values are arranged for postgres database, but other databases may be used as well.
