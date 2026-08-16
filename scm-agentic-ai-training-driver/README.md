# SCM Agentic AI Training Driver

A bright-blue Spring Boot / Thymeleaf presentation UI designed to drive a YouTube course around the
[`scm-end-to-end-poc`](https://github.com/binitdatta/scm-end-to-end-poc) project.

## Stack

- Java 21
- Spring Boot 3.5.9
- Spring MVC
- Thymeleaf
- Bootstrap 5
- Bootstrap Icons
- Maven
- Port `8095`

## Purpose

This application is intentionally separate from the transactional ERP UI and the Python Agent Control Tower.
It acts as the **teaching / narration layer** for the course.

Top navigation:

- Overview
- Purpose
- Business Case
- Architecture
- Live POC
- Training dropdown
- GitHub

The Training dropdown contains 16 lesson pages. Lesson content is stored in
`CourseCatalogService`, while a single reusable Thymeleaf template renders every lesson.

## Run

```bash
mvn clean package
java -jar target/scm-agentic-ai-training-driver-1.0.0-SNAPSHOT.jar
```

Open:

```text
http://localhost:8095
```

## Existing POC links

The application has configurable links to your other two UIs:

```properties
training.links.github=https://github.com/binitdatta/scm-end-to-end-poc
training.links.erp-dashboard=http://localhost:8090
training.links.agent-control-tower=http://127.0.0.1:9000
```

Edit `src/main/resources/application.properties` if your ports change.

## Course Sessions

1. Agentic AI Fundamentals
2. From Business Goal to Supply Chain Workflow
3. LLM Planning with the Anthropic API
4. LangGraph State, Nodes and Orchestration
5. Tool Calling and Enterprise API Contracts
6. Spring Boot REST APIs as Agent Tools
7. Database-per-Service and Bounded Contexts
8. Human-in-the-Loop Approval Gates
9. Failures, Retries and Partial Completion
10. RabbitMQ and Event-Driven Observability
11. Agent Observability, Run History and Audit
12. Security for Human and Agent Clients
13. Agent Memory, State and Long-Running Workflows
14. MCP in an Enterprise Agent Architecture
15. Responsible Enterprise Agent Design
16. End-to-End Source Code Walkthrough

## Project Structure

```text
scm-agentic-ai-training-driver/
├── pom.xml
├── README.md
└── src/
    ├── main/
    │   ├── java/com/enterprise/scmtraining/
    │   │   ├── ScmAgenticAiTrainingApplication.java
    │   │   ├── controller/TrainingController.java
    │   │   ├── model/Lesson.java
    │   │   └── service/CourseCatalogService.java
    │   └── resources/
    │       ├── application.properties
    │       ├── static/
    │       │   ├── css/app.css
    │       │   ├── css/pages.css
    │       │   ├── css/training.css
    │       │   ├── js/app.js
    │       │   └── images/
    │       └── templates/
    │           ├── fragments/
    │           │   ├── head.html
    │           │   ├── navbar.html
    │           │   └── footer.html
    │           └── pages/
    │               ├── home.html
    │               ├── purpose.html
    │               ├── business-case.html
    │               ├── architecture.html
    │               ├── demo.html
    │               ├── training.html
    │               └── lesson.html
    └── test/
```

## Adding another training session

Add one `Lesson` entry to `CourseCatalogService`.

The navbar dropdown and training roadmap update automatically because both iterate over the same catalog.
No additional HTML page is required unless a lesson needs a custom visual layout.

## Design intent

The training driver deliberately separates:

1. **Teaching UI** — this project (`8095`)
2. **Transactional ERP UI** — existing Spring Boot dashboard (`8090`)
3. **Agent execution UI** — existing Python/LangGraph Control Tower (`9000`)
4. **Enterprise APIs** — existing Spring Boot services (`8081`–`8087`)

That separation is useful in the YouTube course because viewers can move from explanation → architecture → live proof
without forcing the production-like applications to carry presentation-only content.
