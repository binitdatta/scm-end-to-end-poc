# cs-crm-api
**CRM & Campaign Management ERP — Toy Surprise Campaign Simulation**

Spring Boot 3.4.3 | JDK 21 | MySQL 8 | RabbitMQ | JPA

---

## Project Structure

```
cs-crm-api/
├── db/
│   ├── 01_ddl_cs_crm.sql        ← Run first in MySQL Workbench (schema + user)
│   └── 02_seed_cs_crm.sql       ← Run second (reference data)
├── src/main/java/com/enterprise/cscrm/
│   ├── CsCrmApiApplication.java
│   ├── config/
│   │   └── RabbitMQConfig.java
│   ├── controller/
│   │   ├── CampaignController.java
│   │   └── CustomerController.java
│   ├── dto/
│   │   ├── request/  (CreateCampaignRequest, LaunchCampaignRequest, CreateCustomerRequest)
│   │   └── response/ (ApiResponse, CampaignResponse, CustomerResponse)
│   ├── entity/
│   │   ├── Campaign.java
│   │   ├── CampaignCustomer.java
│   │   ├── CampaignEvent.java
│   │   └── Customer.java
│   ├── exception/
│   │   ├── GlobalExceptionHandler.java
│   │   ├── ResourceNotFoundException.java
│   │   ├── InvalidStateException.java
│   │   └── DuplicateResourceException.java
│   ├── messaging/
│   │   ├── CampaignEventMessage.java
│   │   └── CampaignEventPublisher.java
│   ├── repository/
│   │   ├── CampaignRepository.java
│   │   ├── CampaignEventRepository.java
│   │   └── CustomerRepository.java
│   └── service/
│       ├── CampaignService.java
│       └── CustomerService.java
└── src/main/resources/
    └── application.properties
```

---

## Setup Steps

### Step 1 — Start RabbitMQ

```bash
brew services start rabbitmq
rabbitmq-plugins enable rabbitmq_management
```

Verify at: http://localhost:15672 (guest / guest)

---

### Step 2 — Run DDL in MySQL Workbench

Open MySQL Workbench and connect to your local MySQL 8 instance as root/admin.

**Run `db/01_ddl_cs_crm.sql` first:**
- Creates the `cs_crm` database
- Creates the `crm_app` application user with SELECT/INSERT/UPDATE/DELETE only
- Creates all tables: customers, campaigns, campaign_events, campaign_customers
- Creates all indexes

**Then run `db/02_seed_cs_crm.sql`:**
- Inserts 10 sample customers
- Inserts 3 campaigns in DRAFT status
- Enrolls GOLD/PLATINUM customers into the Summer Surprise campaign

> The app user `crm_app` has NO DDL privileges. Spring Boot is configured with
> `spring.jpa.hibernate.ddl-auto=none` — it will never attempt to create or
> alter tables.

---

### Step 3 — Open in IntelliJ

1. File → Open → select the `cs-crm-api` folder
2. IntelliJ will detect the `pom.xml` and import the Maven project automatically
3. Wait for Maven to download dependencies (first time only)
4. Enable annotation processing for Lombok:
   - Preferences → Build, Execution, Deployment → Compiler → Annotation Processors
   - Check "Enable annotation processing"

---

### Step 4 — Verify application.properties

The datasource is pre-configured to connect as `crm_app`. If you changed
the password in the DDL script, update it here:

```
spring.datasource.password=CrmApp#2025!
```

The app runs on **port 8081** to leave 8080 free for other services.

---

### Step 5 — Run the Application

From IntelliJ: Right-click `CsCrmApiApplication.java` → Run

Or from terminal:
```bash
cd cs-crm-api
mvn spring-boot:run
```

Confirm startup log contains:
```
Started CsCrmApiApplication on port 8081
```

---

### Step 6 — Run the Curl Test Script

```bash
chmod +x test_cs_crm_api.sh
./test_cs_crm_api.sh
```

This runs the full lifecycle:
1. Creates 2 new customers → publishes `erp.crm.customer.created`
2. Creates a new campaign in DRAFT
3. Launches it → publishes `erp.crm.campaign.launched`
4. Pauses it → publishes `erp.crm.campaign.paused`
5. Attempts invalid re-launch (expects 409)
6. Completes it → publishes `erp.crm.campaign.completed`
7. Tests duplicate email guard (expects 409)
8. Checks actuator health

---

## RabbitMQ Events Published

| Action            | Routing Key                      |
|-------------------|----------------------------------|
| Campaign launched | `erp.crm.campaign.launched`      |
| Campaign paused   | `erp.crm.campaign.paused`        |
| Campaign completed| `erp.crm.campaign.completed`     |
| Customer created  | `erp.crm.customer.created`       |

Exchange: `erp.topic.exchange` (Topic, durable)

The Control Tower Flask app subscribes to `erp.crm.#` to capture all CRM events.

---

## REST Endpoints

| Method | Path                                    | Description                    |
|--------|-----------------------------------------|--------------------------------|
| POST   | /api/v1/campaigns                       | Create campaign (DRAFT)        |
| GET    | /api/v1/campaigns                       | List all campaigns             |
| GET    | /api/v1/campaigns/{externalId}          | Get campaign by ID             |
| POST   | /api/v1/campaigns/{externalId}/launch   | DRAFT → ACTIVE + publish event |
| POST   | /api/v1/campaigns/{externalId}/pause    | ACTIVE → PAUSED + publish event|
| POST   | /api/v1/campaigns/{externalId}/complete | → COMPLETED + publish event    |
| POST   | /api/v1/customers                       | Create customer + publish event|
| GET    | /api/v1/customers                       | List all customers             |
| GET    | /api/v1/customers/{externalId}          | Get customer by ID             |
| GET    | /actuator/health                        | Health check                   |

``` 
binit.datta@C6NWKQ290Y cs-crm-api % chmod +x test_cs_crm_api.sh && ./test_cs_crm_api.sh

══════════════════════════════════════
  1. Create Customers
══════════════════════════════════════
→ Creating PLATINUM customer...
{
    "success": true,
    "message": "Customer created successfully",
    "data": {
        "externalId": "0819d19e-3920-4bbf-a1d5-9a3968809611",
        "firstName": "Jessica",
        "lastName": "Park",
        "email": "jessica.park@test.com",
        "phone": "312-555-9001",
        "tier": "PLATINUM",
        "status": "ACTIVE",
        "createdAt": "2026-03-18T10:10:39",
        "updatedAt": "2026-03-18T10:10:39"
    },
    "timestamp": "2026-03-18T10:10:39"
}
✔ Customer 1 externalId: 0819d19e-3920-4bbf-a1d5-9a3968809611

→ Creating GOLD customer...
{
    "success": true,
    "message": "Customer created successfully",
    "data": {
        "externalId": "10fdb68f-fb3b-4ba7-bd09-c819bc07c9b0",
        "firstName": "Marcus",
        "lastName": "Lee",
        "email": "marcus.lee@test.com",
        "phone": "773-555-9002",
        "tier": "GOLD",
        "status": "ACTIVE",
        "createdAt": "2026-03-18T10:10:39",
        "updatedAt": "2026-03-18T10:10:39"
    },
    "timestamp": "2026-03-18T10:10:39"
}
✔ Customer 2 externalId: 10fdb68f-fb3b-4ba7-bd09-c819bc07c9b0

══════════════════════════════════════
  2. List All Customers
══════════════════════════════════════
{
    "success": true,
    "message": "Customers retrieved",
    "data": [
        {
            "externalId": "cust-001-uuid",
            "firstName": "Sarah",
            "lastName": "Mitchell",
            "email": "sarah.mitchell@example.com",
            "phone": "312-555-0101",
            "tier": "PLATINUM",
            "status": "ACTIVE",
            "createdAt": "2026-03-18T10:08:04",
            "updatedAt": "2026-03-18T10:08:04"
        },
        {
            "externalId": "cust-002-uuid",
            "firstName": "James",
            "lastName": "Hargrove",
            "email": "james.hargrove@example.com",
            "phone": "773-555-0102",
            "tier": "GOLD",
            "status": "ACTIVE",
            "createdAt": "2026-03-18T10:08:04",
            "updatedAt": "2026-03-18T10:08:04"
        },
        {
            "externalId": "cust-003-uuid",
            "firstName": "Maria",
            "lastName": "Delgado",
            "email": "maria.delgado@example.com",
            "phone": "847-555-0103",
            "tier": "STANDARD",
            "status": "ACTIVE",
            "createdAt": "2026-03-18T10:08:04",
            "updatedAt": "2026-03-18T10:08:04"
        },
        {
            "externalId": "cust-004-uuid",
            "firstName": "Kevin",
            "lastName": "Okafor",
            "email": "kevin.okafor@example.com",
            "phone": "630-555-0104",
            "tier": "GOLD",
            "status": "ACTIVE",
            "createdAt": "2026-03-18T10:08:04",
            "updatedAt": "2026-03-18T10:08:04"
        },
        {
            "externalId": "cust-005-uuid",
            "firstName": "Linda",
            "lastName": "Fujimoto",
            "email": "linda.fujimoto@example.com",
            "phone": "312-555-0105",
            "tier": "PLATINUM",
            "status": "ACTIVE",
            "createdAt": "2026-03-18T10:08:04",
            "updatedAt": "2026-03-18T10:08:04"
        },
        {
            "externalId": "cust-006-uuid",
            "firstName": "Thomas",
            "lastName": "Brennan",
            "email": "thomas.brennan@example.com",
            "phone": "708-555-0106",
            "tier": "STANDARD",
            "status": "INACTIVE",
            "createdAt": "2026-03-18T10:08:04",
            "updatedAt": "2026-03-18T10:08:04"
        },
        {
            "externalId": "cust-007-uuid",
            "firstName": "Aisha",
            "lastName": "Rahman",
            "email": "aisha.rahman@example.com",
            "phone": "773-555-0107",
            "tier": "GOLD",
            "status": "ACTIVE",
            "createdAt": "2026-03-18T10:08:04",
            "updatedAt": "2026-03-18T10:08:04"
        },
        {
            "externalId": "cust-008-uuid",
            "firstName": "Carlos",
            "lastName": "Espinoza",
            "email": "carlos.espinoza@example.com",
            "phone": "312-555-0108",
            "tier": "STANDARD",
            "status": "ACTIVE",
            "createdAt": "2026-03-18T10:08:04",
            "updatedAt": "2026-03-18T10:08:04"
        },
        {
            "externalId": "cust-009-uuid",
            "firstName": "Priya",
            "lastName": "Sharma",
            "email": "priya.sharma@example.com",
            "phone": "847-555-0109",
            "tier": "PLATINUM",
            "status": "ACTIVE",
            "createdAt": "2026-03-18T10:08:04",
            "updatedAt": "2026-03-18T10:08:04"
        },
        {
            "externalId": "cust-010-uuid",
            "firstName": "Derek",
            "lastName": "Walton",
            "email": "derek.walton@example.com",
            "phone": "630-555-0110",
            "tier": "STANDARD",
            "status": "ACTIVE",
            "createdAt": "2026-03-18T10:08:04",
            "updatedAt": "2026-03-18T10:08:04"
        },
        {
            "externalId": "0819d19e-3920-4bbf-a1d5-9a3968809611",
            "firstName": "Jessica",
            "lastName": "Park",
            "email": "jessica.park@test.com",
            "phone": "312-555-9001",
            "tier": "PLATINUM",
            "status": "ACTIVE",
            "createdAt": "2026-03-18T10:10:39",
            "updatedAt": "2026-03-18T10:10:39"
        },
        {
            "externalId": "10fdb68f-fb3b-4ba7-bd09-c819bc07c9b0",
            "firstName": "Marcus",
            "lastName": "Lee",
            "email": "marcus.lee@test.com",
            "phone": "773-555-9002",
            "tier": "GOLD",
            "status": "ACTIVE",
            "createdAt": "2026-03-18T10:10:39",
            "updatedAt": "2026-03-18T10:10:39"
        }
    ],
    "timestamp": "2026-03-18T10:10:39"
}

══════════════════════════════════════
  3. Get Customer by externalId
══════════════════════════════════════
{
    "success": true,
    "message": "Customer retrieved",
    "data": {
        "externalId": "0819d19e-3920-4bbf-a1d5-9a3968809611",
        "firstName": "Jessica",
        "lastName": "Park",
        "email": "jessica.park@test.com",
        "phone": "312-555-9001",
        "tier": "PLATINUM",
        "status": "ACTIVE",
        "createdAt": "2026-03-18T10:10:39",
        "updatedAt": "2026-03-18T10:10:39"
    },
    "timestamp": "2026-03-18T10:10:39"
}

══════════════════════════════════════
  4. Create Campaign (DRAFT)
══════════════════════════════════════
{
    "success": true,
    "message": "Campaign created successfully",
    "data": {
        "externalId": "39e3b4cb-8b7c-4e67-b0c9-fc145ea6016e",
        "campaignName": "Autumn Adventure 2025",
        "campaignCode": "AUTUMN25-TOY",
        "description": "Fall season toy surprise campaign. Mystery dinosaur figures sourced from Vietnam vendor.",
        "campaignType": "TOY_SURPRISE",
        "status": "DRAFT",
        "budgetUsd": 850000.0,
        "startDate": "2025-09-01",
        "endDate": "2025-11-30",
        "targetRegion": "US-MIDWEST",
        "createdBy": "campaign.manager",
        "createdAt": "2026-03-18T10:10:39",
        "updatedAt": "2026-03-18T10:10:39"
    },
    "timestamp": "2026-03-18T10:10:39"
}
✔ Campaign externalId: 39e3b4cb-8b7c-4e67-b0c9-fc145ea6016e

══════════════════════════════════════
  5. List All Campaigns
══════════════════════════════════════
{
    "success": true,
    "message": "Campaigns retrieved",
    "data": [
        {
            "externalId": "camp-001-uuid",
            "campaignName": "Summer Surprise 2025",
            "campaignCode": "SUMMER25-TOY",
            "description": "Kids meal toy surprise campaign for summer 2025. Toys sourced from Thailand and Vietnam vendors. Packaged as a mystery surprise inside every kids meal.",
            "campaignType": "TOY_SURPRISE",
            "status": "DRAFT",
            "budgetUsd": 750000.0,
            "startDate": "2025-06-01",
            "endDate": "2025-08-31",
            "targetRegion": "NATIONAL",
            "createdBy": "admin",
            "createdAt": "2026-03-18T10:08:04",
            "updatedAt": "2026-03-18T10:08:04"
        },
        {
            "externalId": "camp-002-uuid",
            "campaignName": "Holiday Collectibles 2025",
            "campaignCode": "HOLIDAY25-TOY",
            "description": "Winter holiday collectible toy series. Limited edition figurines across 6 characters. Sourced from China vendor.",
            "campaignType": "TOY_SURPRISE",
            "status": "DRAFT",
            "budgetUsd": 1200000.0,
            "startDate": "2025-11-15",
            "endDate": "2025-12-31",
            "targetRegion": "NATIONAL",
            "createdBy": "admin",
            "createdAt": "2026-03-18T10:08:04",
            "updatedAt": "2026-03-18T10:08:04"
        },
        {
            "externalId": "camp-003-uuid",
            "campaignName": "Spring Loyalty Boost",
            "campaignCode": "SPRING25-LOYAL",
            "description": "Loyalty points double-up promotion for Gold and Platinum customers during spring.",
            "campaignType": "LOYALTY",
            "status": "DRAFT",
            "budgetUsd": 200000.0,
            "startDate": "2025-03-20",
            "endDate": "2025-05-31",
            "targetRegion": "US-MIDWEST",
            "createdBy": "admin",
            "createdAt": "2026-03-18T10:08:04",
            "updatedAt": "2026-03-18T10:08:04"
        },
        {
            "externalId": "39e3b4cb-8b7c-4e67-b0c9-fc145ea6016e",
            "campaignName": "Autumn Adventure 2025",
            "campaignCode": "AUTUMN25-TOY",
            "description": "Fall season toy surprise campaign. Mystery dinosaur figures sourced from Vietnam vendor.",
            "campaignType": "TOY_SURPRISE",
            "status": "DRAFT",
            "budgetUsd": 850000.0,
            "startDate": "2025-09-01",
            "endDate": "2025-11-30",
            "targetRegion": "US-MIDWEST",
            "createdBy": "campaign.manager",
            "createdAt": "2026-03-18T10:10:40",
            "updatedAt": "2026-03-18T10:10:40"
        }
    ],
    "timestamp": "2026-03-18T10:10:39"
}

══════════════════════════════════════
  6. Get Campaign by externalId
══════════════════════════════════════
{
    "success": true,
    "message": "Campaign retrieved",
    "data": {
        "externalId": "39e3b4cb-8b7c-4e67-b0c9-fc145ea6016e",
        "campaignName": "Autumn Adventure 2025",
        "campaignCode": "AUTUMN25-TOY",
        "description": "Fall season toy surprise campaign. Mystery dinosaur figures sourced from Vietnam vendor.",
        "campaignType": "TOY_SURPRISE",
        "status": "DRAFT",
        "budgetUsd": 850000.0,
        "startDate": "2025-09-01",
        "endDate": "2025-11-30",
        "targetRegion": "US-MIDWEST",
        "createdBy": "campaign.manager",
        "createdAt": "2026-03-18T10:10:40",
        "updatedAt": "2026-03-18T10:10:40"
    },
    "timestamp": "2026-03-18T10:10:39"
}

══════════════════════════════════════
  7. Launch Campaign → publishes erp.crm.campaign.launched
══════════════════════════════════════
{
    "success": true,
    "message": "Campaign launched successfully",
    "data": {
        "externalId": "39e3b4cb-8b7c-4e67-b0c9-fc145ea6016e",
        "campaignName": "Autumn Adventure 2025",
        "campaignCode": "AUTUMN25-TOY",
        "description": "Fall season toy surprise campaign. Mystery dinosaur figures sourced from Vietnam vendor.",
        "campaignType": "TOY_SURPRISE",
        "status": "ACTIVE",
        "budgetUsd": 850000.0,
        "startDate": "2025-09-01",
        "endDate": "2025-11-30",
        "targetRegion": "US-MIDWEST",
        "createdBy": "campaign.manager",
        "createdAt": "2026-03-18T10:10:40",
        "updatedAt": "2026-03-18T10:10:40"
    },
    "timestamp": "2026-03-18T10:10:39"
}
✔ Check RabbitMQ management UI: http://localhost:15672 → Exchanges → erp.topic.exchange

══════════════════════════════════════
  8. Pause Campaign → publishes erp.crm.campaign.paused
══════════════════════════════════════
{
    "success": true,
    "message": "Campaign paused",
    "data": {
        "externalId": "39e3b4cb-8b7c-4e67-b0c9-fc145ea6016e",
        "campaignName": "Autumn Adventure 2025",
        "campaignCode": "AUTUMN25-TOY",
        "description": "Fall season toy surprise campaign. Mystery dinosaur figures sourced from Vietnam vendor.",
        "campaignType": "TOY_SURPRISE",
        "status": "PAUSED",
        "budgetUsd": 850000.0,
        "startDate": "2025-09-01",
        "endDate": "2025-11-30",
        "targetRegion": "US-MIDWEST",
        "createdBy": "campaign.manager",
        "createdAt": "2026-03-18T10:10:40",
        "updatedAt": "2026-03-18T10:10:40"
    },
    "timestamp": "2026-03-18T10:10:39"
}

══════════════════════════════════════
  9. Attempt to launch a PAUSED campaign (expect 409 CONFLICT)
══════════════════════════════════════
{
    "success": false,
    "message": "Campaign can only be launched from DRAFT status. Current: PAUSED",
    "data": null,
    "timestamp": "2026-03-18T10:10:39"
}

══════════════════════════════════════
  10. Complete Campaign → publishes erp.crm.campaign.completed
══════════════════════════════════════
{
    "success": true,
    "message": "Campaign completed",
    "data": {
        "externalId": "39e3b4cb-8b7c-4e67-b0c9-fc145ea6016e",
        "campaignName": "Autumn Adventure 2025",
        "campaignCode": "AUTUMN25-TOY",
        "description": "Fall season toy surprise campaign. Mystery dinosaur figures sourced from Vietnam vendor.",
        "campaignType": "TOY_SURPRISE",
        "status": "COMPLETED",
        "budgetUsd": 850000.0,
        "startDate": "2025-09-01",
        "endDate": "2025-11-30",
        "targetRegion": "US-MIDWEST",
        "createdBy": "campaign.manager",
        "createdAt": "2026-03-18T10:10:40",
        "updatedAt": "2026-03-18T10:10:40"
    },
    "timestamp": "2026-03-18T10:10:39"
}

══════════════════════════════════════
  11. Verify Final Campaign Status
══════════════════════════════════════
{
    "success": true,
    "message": "Campaign retrieved",
    "data": {
        "externalId": "39e3b4cb-8b7c-4e67-b0c9-fc145ea6016e",
        "campaignName": "Autumn Adventure 2025",
        "campaignCode": "AUTUMN25-TOY",
        "description": "Fall season toy surprise campaign. Mystery dinosaur figures sourced from Vietnam vendor.",
        "campaignType": "TOY_SURPRISE",
        "status": "COMPLETED",
        "budgetUsd": 850000.0,
        "startDate": "2025-09-01",
        "endDate": "2025-11-30",
        "targetRegion": "US-MIDWEST",
        "createdBy": "campaign.manager",
        "createdAt": "2026-03-18T10:10:40",
        "updatedAt": "2026-03-18T10:10:40"
    },
    "timestamp": "2026-03-18T10:10:39"
}

══════════════════════════════════════
  12. Duplicate customer email (expect 409 CONFLICT)
══════════════════════════════════════
{
    "success": false,
    "message": "Customer already exists with email: jessica.park@test.com",
    "data": null,
    "timestamp": "2026-03-18T10:10:39"
}

══════════════════════════════════════
  13. Actuator Health Check
══════════════════════════════════════
{
    "status": "UP",
    "components": {
        "db": {
            "status": "UP",
            "details": {
                "database": "MySQL",
                "validationQuery": "isValid()"
            }
        },
        "diskSpace": {
            "status": "UP",
            "details": {
                "total": 994662584320,
                "free": 895017988096,
                "threshold": 10485760,
                "path": "/Users/binit.datta/tms_enterprise_poc/cs-crm-api/.",
                "exists": true
            }
        },
        "ping": {
            "status": "UP"
        },
        "rabbit": {
            "status": "UP",
            "details": {
                "version": "4.2.5"
            }
        },
        "ssl": {
            "status": "UP",
            "details": {
                "validChains": [],
                "invalidChains": []
            }
        }
    }
}

✔ All tests complete. Check RabbitMQ UI at http://localhost:15672 (guest/guest)
✔ Exchange: erp.topic.exchange | Routing keys: erp.crm.campaign.* and erp.crm.customer.created
binit.datta@C6NWKQ290Y cs-crm-api % 
```

## RabbitMQ

``` 
binit.datta@C6NWKQ290Y cs-crm-api % curl -s -u guest:guest -X PUT http://localhost:15672/api/queues/%2F/control-tower-test \
  -H "Content-Type: application/json" \
  -d '{"durable": true}' | python3 -m json.tool
Expecting value: line 1 column 1 (char 0)
binit.datta@C6NWKQ290Y cs-crm-api % curl -s -u guest:guest -X POST \
  http://localhost:15672/api/bindings/%2F/e/erp.topic.exchange/q/control-tower-test \
  -H "Content-Type: application/json" \
  -d '{"routing_key": "erp.#"}' | python3 -m json.tool
Expecting value: line 1 column 1 (char 0)
binit.datta@C6NWKQ290Y cs-crm-api % # Grab the externalId of the SUMMER25-TOY seeded campaign
CAMP_ID="camp-001-uuid"

curl -s -X POST "http://localhost:8081/api/v1/campaigns/$CAMP_ID/launch" \
  -H "Content-Type: application/json" \
  -d '{"triggeredBy":"test.validation","notes":"RabbitMQ message proof test"}' \
  | python3 -m json.tool
zsh: command not found: #
{
    "success": true,
    "message": "Campaign launched successfully",
    "data": {
        "externalId": "camp-001-uuid",
        "campaignName": "Summer Surprise 2025",
        "campaignCode": "SUMMER25-TOY",
        "description": "Kids meal toy surprise campaign for summer 2025. Toys sourced from Thailand and Vietnam vendors. Packaged as a mystery surprise inside every kids meal.",
        "campaignType": "TOY_SURPRISE",
        "status": "ACTIVE",
        "budgetUsd": 750000.0,
        "startDate": "2025-06-01",
        "endDate": "2025-08-31",
        "targetRegion": "NATIONAL",
        "createdBy": "admin",
        "createdAt": "2026-03-18T10:08:04",
        "updatedAt": "2026-03-18T10:08:04"
    },
    "timestamp": "2026-03-18T10:15:54"
}
binit.datta@C6NWKQ290Y cs-crm-api % # 3. Consume and inspect the message (requeue=true so it stays in the queue)
curl -s -u guest:guest -X POST \
  http://localhost:15672/api/queues/%2F/control-tower-test/get \
  -H "Content-Type: application/json" \
  -d '{"count":5,"requeue":true,"encoding":"auto","truncate":50000}' \
  | python3 -m json.tool
zsh: unknown username 'u'
{
    "error": "bad_request",
    "reason": "[{key_missing,ackmode}]"
}
binit.datta@C6NWKQ290Y cs-crm-api % 
```

``` 
binit.datta@C6NWKQ290Y cs-crm-api % curl -s -u guest:guest -X PUT \
  "http://localhost:15672/api/queues/%2F/control-tower-test" \
  -H "Content-Type: application/json" \
  -d '{"durable":true}'
binit.datta@C6NWKQ290Y cs-crm-api % curl -s -u guest:guest -X POST \
  "http://localhost:15672/api/bindings/%2F/e/erp.topic.exchange/q/control-tower-test" \
  -H "Content-Type: application/json" \
  -d '{"routing_key":"erp.#"}'
binit.datta@C6NWKQ290Y cs-crm-api % curl -s -X POST "http://localhost:8081/api/v1/campaigns/camp-002-uuid/launch" \
  -H "Content-Type: application/json" \
  -d '{"triggeredBy":"rabbitmq.test","notes":"Validating queue binding"}' \
  | python3 -m json.tool
{
    "success": true,
    "message": "Campaign launched successfully",
    "data": {
        "externalId": "camp-002-uuid",
        "campaignName": "Holiday Collectibles 2025",
        "campaignCode": "HOLIDAY25-TOY",
        "description": "Winter holiday collectible toy series. Limited edition figurines across 6 characters. Sourced from China vendor.",
        "campaignType": "TOY_SURPRISE",
        "status": "ACTIVE",
        "budgetUsd": 1200000.0,
        "startDate": "2025-11-15",
        "endDate": "2025-12-31",
        "targetRegion": "NATIONAL",
        "createdBy": "admin",
        "createdAt": "2026-03-18T10:08:04",
        "updatedAt": "2026-03-18T10:08:04"
    },
    "timestamp": "2026-03-18T10:18:17"
}
binit.datta@C6NWKQ290Y cs-crm-api % curl -s -u guest:guest -X POST \
  "http://localhost:15672/api/queues/%2F/control-tower-test/get" \
  -H "Content-Type: application/json" \
  -d '{"count":5,"requeue":true,"encoding":"auto","ackmode":"ack_requeue_true"}' \
  | python3 -m json.tool
[
    {
        "payload_bytes": 365,
        "redelivered": false,
        "exchange": "erp.topic.exchange",
        "routing_key": "erp.crm.campaign.launched",
        "message_count": 1,
        "properties": {
            "priority": 0,
            "delivery_mode": 2,
            "headers": {
                "__TypeId__": "com.enterprise.cscrm.messaging.CampaignEventMessage"
            },
            "content_encoding": "UTF-8",
            "content_type": "application/json"
        },
        "payload": "{\"source\":null,\"routingKey\":\"erp.crm.campaign.launched\",\"campaignExternalId\":\"camp-001-uuid\",\"campaignCode\":\"SUMMER25-TOY\",\"campaignName\":\"Summer Surprise 2025\",\"previousStatus\":\"DRAFT\",\"newStatus\":\"ACTIVE\",\"eventType\":\"LAUNCHED\",\"triggeredBy\":\"test.validation\",\"targetRegion\":\"NATIONAL\",\"notes\":\"RabbitMQ message proof test\",\"eventTimestamp\":\"2026-03-18T10:15:54\"}",
        "payload_encoding": "string"
    },
    {
        "payload_bytes": 366,
        "redelivered": false,
        "exchange": "erp.topic.exchange",
        "routing_key": "erp.crm.campaign.launched",
        "message_count": 0,
        "properties": {
            "priority": 0,
            "delivery_mode": 2,
            "headers": {
                "__TypeId__": "com.enterprise.cscrm.messaging.CampaignEventMessage"
            },
            "content_encoding": "UTF-8",
            "content_type": "application/json"
        },
        "payload": "{\"source\":null,\"routingKey\":\"erp.crm.campaign.launched\",\"campaignExternalId\":\"camp-002-uuid\",\"campaignCode\":\"HOLIDAY25-TOY\",\"campaignName\":\"Holiday Collectibles 2025\",\"previousStatus\":\"DRAFT\",\"newStatus\":\"ACTIVE\",\"eventType\":\"LAUNCHED\",\"triggeredBy\":\"rabbitmq.test\",\"targetRegion\":\"NATIONAL\",\"notes\":\"Validating queue binding\",\"eventTimestamp\":\"2026-03-18T10:18:17\"}",
        "payload_encoding": "string"
    }
]
binit.datta@C6NWKQ290Y cs-crm-api % 
```

``` 
binit.datta@C6NWKQ290Y cs-crm-api % curl -s -X POST "http://localhost:8081/api/v1/campaigns/camp-003-uuid/launch" \
  -H "Content-Type: application/json" \
  -d '{"triggeredBy":"source.field.test","notes":"Testing source field fix"}' \
  | python3 -m json.tool
{
    "success": true,
    "message": "Campaign launched successfully",
    "data": {
        "externalId": "camp-003-uuid",
        "campaignName": "Spring Loyalty Boost",
        "campaignCode": "SPRING25-LOYAL",
        "description": "Loyalty points double-up promotion for Gold and Platinum customers during spring.",
        "campaignType": "LOYALTY",
        "status": "ACTIVE",
        "budgetUsd": 200000.0,
        "startDate": "2025-03-20",
        "endDate": "2025-05-31",
        "targetRegion": "US-MIDWEST",
        "createdBy": "admin",
        "createdAt": "2026-03-18T10:08:04",
        "updatedAt": "2026-03-18T10:08:04"
    },
    "timestamp": "2026-03-18T10:22:29"
}
binit.datta@C6NWKQ290Y cs-crm-api % curl -s -u guest:guest -X POST \
  "http://localhost:15672/api/queues/%2F/control-tower-test/get" \
  -H "Content-Type: application/json" \
  -d '{"count":5,"requeue":true,"encoding":"auto","ackmode":"ack_requeue_true"}' \
  | python3 -m json.tool
[
    {
        "payload_bytes": 365,
        "redelivered": true,
        "exchange": "erp.topic.exchange",
        "routing_key": "erp.crm.campaign.launched",
        "message_count": 2,
        "properties": {
            "priority": 0,
            "delivery_mode": 2,
            "headers": {
                "__TypeId__": "com.enterprise.cscrm.messaging.CampaignEventMessage"
            },
            "content_encoding": "UTF-8",
            "content_type": "application/json"
        },
        "payload": "{\"source\":null,\"routingKey\":\"erp.crm.campaign.launched\",\"campaignExternalId\":\"camp-001-uuid\",\"campaignCode\":\"SUMMER25-TOY\",\"campaignName\":\"Summer Surprise 2025\",\"previousStatus\":\"DRAFT\",\"newStatus\":\"ACTIVE\",\"eventType\":\"LAUNCHED\",\"triggeredBy\":\"test.validation\",\"targetRegion\":\"NATIONAL\",\"notes\":\"RabbitMQ message proof test\",\"eventTimestamp\":\"2026-03-18T10:15:54\"}",
        "payload_encoding": "string"
    },
    {
        "payload_bytes": 366,
        "redelivered": true,
        "exchange": "erp.topic.exchange",
        "routing_key": "erp.crm.campaign.launched",
        "message_count": 1,
        "properties": {
            "priority": 0,
            "delivery_mode": 2,
            "headers": {
                "__TypeId__": "com.enterprise.cscrm.messaging.CampaignEventMessage"
            },
            "content_encoding": "UTF-8",
            "content_type": "application/json"
        },
        "payload": "{\"source\":null,\"routingKey\":\"erp.crm.campaign.launched\",\"campaignExternalId\":\"camp-002-uuid\",\"campaignCode\":\"HOLIDAY25-TOY\",\"campaignName\":\"Holiday Collectibles 2025\",\"previousStatus\":\"DRAFT\",\"newStatus\":\"ACTIVE\",\"eventType\":\"LAUNCHED\",\"triggeredBy\":\"rabbitmq.test\",\"targetRegion\":\"NATIONAL\",\"notes\":\"Validating queue binding\",\"eventTimestamp\":\"2026-03-18T10:18:17\"}",
        "payload_encoding": "string"
    },
    {
        "payload_bytes": 376,
        "redelivered": false,
        "exchange": "erp.topic.exchange",
        "routing_key": "erp.crm.campaign.launched",
        "message_count": 0,
        "properties": {
            "priority": 0,
            "delivery_mode": 2,
            "headers": {
                "__TypeId__": "com.enterprise.cscrm.messaging.CampaignEventMessage"
            },
            "content_encoding": "UTF-8",
            "content_type": "application/json"
        },
        "payload": "{\"source\":\"cs-crm-api\",\"routingKey\":\"erp.crm.campaign.launched\",\"campaignExternalId\":\"camp-003-uuid\",\"campaignCode\":\"SPRING25-LOYAL\",\"campaignName\":\"Spring Loyalty Boost\",\"previousStatus\":\"DRAFT\",\"newStatus\":\"ACTIVE\",\"eventType\":\"LAUNCHED\",\"triggeredBy\":\"source.field.test\",\"targetRegion\":\"US-MIDWEST\",\"notes\":\"Testing source field fix\",\"eventTimestamp\":\"2026-03-18T10:22:29\"}",
        "payload_encoding": "string"
    }
]
binit.datta@C6NWKQ290Y cs-crm-api % 
```