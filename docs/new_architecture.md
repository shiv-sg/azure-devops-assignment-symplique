                        +--------------------------+
                        |   Existing Billing API   |
                        +------------+-------------+
                                     |
                                     v
                        +--------------------------+
                        |      Azure Function       |  <- Proxy layer to check data location
                        +------------+-------------+
                                     |
                                     v
                        +--------------------------+
                        |     Cosmos DB (Hot)       |  <- Recent (<90 days) records
                        +------------+-------------+
                                     |
                                     v
                        +--------------------------+
                        |   Azure Blob Storage      |  <- Archived JSON blobs, partitioned by date
                        |  (Cool or Archive Tier)   |
                        +--------------------------+
