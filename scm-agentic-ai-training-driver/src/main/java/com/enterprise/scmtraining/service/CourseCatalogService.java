package com.enterprise.scmtraining.service;

import com.enterprise.scmtraining.model.Lesson;
import org.springframework.stereotype.Service;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
public class CourseCatalogService {

    private final Map<String, Lesson> lessons = new LinkedHashMap<>();

    public CourseCatalogService() {
        add(new Lesson(
                1, "agentic-ai-fundamentals",
                "Agentic AI Fundamentals", "Agentic AI Fundamentals", "7–9 min", "Foundation",
                "Establish the difference between a conversational LLM, a tool-using agent, and an enterprise agentic system.",
                "The LLM is the reasoning component. The enterprise system still owns APIs, policy, state, identity, data, transactions, and auditability.",
                List.of(
                        "LLM versus agent versus agentic system",
                        "Reasoning, planning, acting and observing",
                        "Deterministic enterprise services surrounding probabilistic reasoning",
                        "Why autonomy must be bounded by policy and permissions"
                ),
                List.of(
                        "Human states a business goal in natural language",
                        "Agent interprets intent and produces a plan",
                        "Agent chooses approved tools",
                        "Tools call enterprise APIs",
                        "Agent observes results and decides the next step",
                        "Human receives an outcome plus an auditable execution trail"
                ),
                List.of(
                        "Show the end-to-end user prompt",
                        "Run the agent and point out the generated execution steps",
                        "Contrast the natural-language goal with the deterministic REST calls underneath"
                ),
                List.of(
                        "Agentic AI is not a replacement for enterprise application architecture",
                        "The safest agents operate through explicit, governed tools",
                        "Autonomy should be granted deliberately, not implicitly"
                )
        ));

        add(new Lesson(
                2, "business-workflow",
                "From Business Goal to Supply Chain Workflow", "Business Workflow", "6–8 min", "Foundation",
                "Translate the Burger Bliss promotion scenario into a cross-domain enterprise workflow.",
                "The business goal crosses CRM, sourcing, procurement, warehousing, order management and transportation; no single service owns the entire outcome.",
                List.of(
                        "Campaign-to-delivery business process",
                        "Cross-domain orchestration",
                        "Business outcome versus technical transaction",
                        "Long-running workflow boundaries"
                ),
                List.of(
                        "CRM campaign creation and launch",
                        "Vendor RFQ, quote collection and scoring",
                        "Purchase Order creation and approval",
                        "Inbound receiving and inventory update",
                        "Store order fulfillment",
                        "Outbound shipment dispatch",
                        "Transportation and proof of delivery"
                ),
                List.of(
                        "Use the ERP Control Centre to show the seven services",
                        "Show how each service owns a different part of the business lifecycle",
                        "Run the full-cycle prompt from the Agent Control Tower"
                ),
                List.of(
                        "Agentic use cases become compelling when a goal spans multiple bounded contexts",
                        "The agent coordinates; systems of record remain authoritative",
                        "Business process visibility is as important as model capability"
                )
        ));

        add(new Lesson(
                3, "anthropic-planning",
                "LLM Planning with the Anthropic API", "LLM Planning", "8–10 min", "AI Orchestration",
                "Explain how an LLM turns an open-ended goal into a constrained execution plan.",
                "A useful enterprise planner is not asked to invent arbitrary actions; it plans against a known catalog of allowed capabilities.",
                List.of(
                        "System prompts and capability catalogs",
                        "Structured plans and step schemas",
                        "Confidence and uncertainty",
                        "Plan validation before execution"
                ),
                List.of(
                        "Receive the user's goal",
                        "Attach enterprise execution context",
                        "Ask the model for a structured plan",
                        "Validate planned actions against the tool catalog",
                        "Execute only recognized operations"
                ),
                List.of(
                        "Show a sample full-cycle prompt",
                        "Show planner output or step list",
                        "Explain where validation should reject unknown tools or malformed arguments"
                ),
                List.of(
                        "Prompt quality matters, but contract quality matters more",
                        "Plans should be machine-validated before they touch transactional APIs",
                        "Model confidence is advisory, not authorization"
                )
        ));

        add(new Lesson(
                4, "langgraph-orchestration",
                "LangGraph State, Nodes and Orchestration", "LangGraph Orchestration", "9–10 min", "AI Orchestration",
                "Show why a graph-based state machine is useful for multi-step agent execution.",
                "LangGraph makes orchestration explicit: state moves through planner, executor, validator, HITL and completion nodes rather than hiding the workflow in one giant prompt.",
                List.of(
                        "Graph state",
                        "Nodes and edges",
                        "Conditional transitions",
                        "Checkpointing and resumability",
                        "Execution metadata"
                ),
                List.of(
                        "Initialize run state",
                        "Plan the goal",
                        "Execute one step",
                        "Capture the observation",
                        "Branch on success, failure or approval requirement",
                        "Continue until completed or stopped"
                ),
                List.of(
                        "Map the visible run steps to graph nodes",
                        "Point out where a failed node can be isolated",
                        "Explain where a checkpoint could allow later resume"
                ),
                List.of(
                        "Explicit graphs improve explainability and control",
                        "State should be treated as a first-class execution artifact",
                        "Long-running workflows need resumability, not only retries"
                )
        ));

        add(new Lesson(
                5, "tool-calling",
                "Tool Calling and Enterprise API Contracts", "Tool Calling", "8–10 min", "Integration",
                "Explain how agent tools turn model intent into bounded enterprise operations.",
                "A tool is an adapter between probabilistic model output and a deterministic API contract.",
                List.of(
                        "Tool name, description and argument schema",
                        "Input validation",
                        "Idempotency",
                        "Timeouts and error mapping",
                        "Tool results as observations"
                ),
                List.of(
                        "Planner selects an approved tool",
                        "Arguments are validated",
                        "Tool adapter invokes the REST endpoint",
                        "HTTP response is normalized",
                        "Observation is written back to graph state"
                ),
                List.of(
                        "Pick one operation such as create Purchase Order",
                        "Show the REST request contract",
                        "Show the tool adapter's responsibility before and after the call"
                ),
                List.of(
                        "Do not expose arbitrary HTTP access to the model",
                        "Design small tools around business capabilities",
                        "Tool responses should be normalized for reliable downstream reasoning"
                )
        ));

        add(new Lesson(
                6, "spring-boot-api-tools",
                "Spring Boot REST APIs as Agent Tools", "Spring Boot as Tools", "8–10 min", "Integration",
                "Demonstrate how existing Spring Boot services can serve both human clients and AI agents without becoming AI-specific applications.",
                "The backend should remain a normal enterprise API. The agent is simply another authorized client.",
                List.of(
                        "REST controllers and service-layer policy",
                        "DTO validation",
                        "HTTP status semantics",
                        "Human and machine clients",
                        "Stable API contracts"
                ),
                List.of(
                        "Human UI calls a Spring Boot API",
                        "Agent tool calls the same business API",
                        "Service validates request and domain rules",
                        "MySQL schema persists authoritative state",
                        "Response returns a deterministic business result"
                ),
                List.of(
                        "Open one ERP function in the Spring Boot UI",
                        "Perform the same capability through the agent workflow",
                        "Emphasize that domain rules stay in the service"
                ),
                List.of(
                        "Do not move domain logic into prompts",
                        "AI clients should consume the same governed contracts as other clients",
                        "Good APIs are a prerequisite for reliable enterprise agents"
                )
        ));

        add(new Lesson(
                7, "database-per-service",
                "Database-per-Service and Bounded Contexts", "Database per Service", "7–9 min", "Architecture",
                "Explain why each ERP microservice owns its own MySQL schema and how the agent coordinates without bypassing those ownership boundaries.",
                "Data ownership remains with the service that owns the business capability; the agent should not become a cross-database superuser.",
                List.of(
                        "Bounded contexts",
                        "Schema ownership",
                        "Loose coupling",
                        "API-based data access",
                        "Consistency across distributed workflows"
                ),
                List.of(
                        "CRM writes CRM state",
                        "Procurement writes procurement state",
                        "WMS services write warehouse state",
                        "OMS writes order state",
                        "TMS writes transportation state",
                        "Agent reads and changes state through service contracts"
                ),
                List.of(
                        "Use the architecture page to show independent schemas",
                        "Explain why direct cross-schema writes create coupling",
                        "Show an example where an API response becomes input to the next service"
                ),
                List.of(
                        "Agent orchestration does not eliminate service boundaries",
                        "Database isolation improves ownership and independent evolution",
                        "Cross-service consistency must be handled intentionally"
                )
        ));

        add(new Lesson(
                8, "human-in-the-loop",
                "Human-in-the-Loop Approval Gates", "HITL Approval", "7–9 min", "Governance",
                "Show how an autonomous workflow can pause before sensitive or high-impact actions.",
                "HITL is a policy control in the execution graph, not a decorative confirmation dialog.",
                List.of(
                        "Approval thresholds",
                        "Risk-based autonomy",
                        "Pause/resume state",
                        "Approver context",
                        "Audit evidence"
                ),
                List.of(
                        "Agent reaches a gated action",
                        "Policy determines whether approval is required",
                        "Execution is suspended with state preserved",
                        "Human approves or rejects",
                        "Graph resumes from the approved checkpoint"
                ),
                List.of(
                        "Point out the HITL gates in the Agent Control Tower log",
                        "Discuss examples such as high-value PO approval or shipment dispatch",
                        "Explain what should be persisted before the pause"
                ),
                List.of(
                        "Autonomy can vary by action and risk",
                        "The approval decision must be auditable",
                        "A production design needs durable pause/resume semantics"
                )
        ));

        add(new Lesson(
                9, "failure-recovery",
                "Failures, Retries and Partial Completion", "Failure Recovery", "8–10 min", "Reliability",
                "Teach how to reason about partial failure when some steps succeed and a later step fails.",
                "An enterprise agent must know the difference between retrying a technical call and compensating for a business transaction that already committed.",
                List.of(
                        "Technical retry versus business compensation",
                        "Idempotency keys",
                        "Partial completion",
                        "Dead-letter/manual intervention",
                        "Error classification"
                ),
                List.of(
                        "Capture the failed tool call",
                        "Classify transient versus permanent failure",
                        "Retry only when safe",
                        "Preserve completed step results",
                        "Escalate or compensate when business state has already changed"
                ),
                List.of(
                        "Use the anomaly-detector failure visible in the run",
                        "Explain why the workflow can record a failure while other steps remain observable",
                        "Discuss how you would harden this for production"
                ),
                List.of(
                        "Retries are not a universal recovery mechanism",
                        "Every side-effecting tool needs an idempotency strategy",
                        "Run history is essential for operational recovery"
                )
        ));

        add(new Lesson(
                10, "event-driven-architecture",
                "RabbitMQ and Event-Driven Observability", "Events & RabbitMQ", "7–9 min", "Architecture",
                "Explain how domain events can provide a cross-system execution trail without coupling every service to the agent.",
                "Commands change business state; events communicate what happened.",
                List.of(
                        "Domain events",
                        "Topic exchanges and routing keys",
                        "Event consumers",
                        "Asynchronous integration",
                        "Operational timelines"
                ),
                List.of(
                        "Spring Boot service completes a business action",
                        "Service publishes a domain event",
                        "RabbitMQ routes the event",
                        "Control Tower consumes and records it",
                        "UI shows the event as part of the business timeline"
                ),
                List.of(
                        "Show the Events tab in the control tower",
                        "Relate one business action to its emitted event",
                        "Explain how events differ from direct command APIs"
                ),
                List.of(
                        "Events improve decoupled visibility",
                        "Event delivery semantics and duplicate handling matter",
                        "An event stream can become part of the agent's observation layer"
                )
        ));

        add(new Lesson(
                11, "observability-audit",
                "Agent Observability, Run History and Audit", "Observability & Audit", "8–10 min", "Operations",
                "Define the telemetry needed to operate an agentic workflow safely.",
                "A production agent should be explainable as a sequence of model decisions, tool calls, policies, approvals, errors and business outcomes.",
                List.of(
                        "Run IDs and correlation IDs",
                        "Step status and latency",
                        "Prompt/model metadata",
                        "Tool request/response summaries",
                        "Audit and replay"
                ),
                List.of(
                        "Create a run ID",
                        "Record the plan",
                        "Record each tool invocation and result",
                        "Record policy and HITL decisions",
                        "Close the run with a final status and outcome"
                ),
                List.of(
                        "Show run history and agent log",
                        "Show step-level status and confidence",
                        "Explain what data should be redacted before logging"
                ),
                List.of(
                        "If you cannot reconstruct what the agent did, you cannot govern it",
                        "Correlation across AI and application telemetry is critical",
                        "Observability data must itself be protected"
                )
        ));

        add(new Lesson(
                12, "security",
                "Security for Human and Agent Clients", "Security", "9–10 min", "Governance",
                "Frame identity, authorization and secrets as core parts of agent design.",
                "An LLM deciding to call a tool is not an authorization decision. Every request still needs enterprise identity and policy enforcement.",
                List.of(
                        "OAuth2/OIDC client identities",
                        "Human delegation versus workload identity",
                        "Least privilege",
                        "Secrets management",
                        "Authorization at the API boundary"
                ),
                List.of(
                        "Authenticate the human or agent workload",
                        "Obtain a scoped access token",
                        "Invoke the business API",
                        "Resource server validates issuer, audience and permissions",
                        "Domain service enforces business policy"
                ),
                List.of(
                        "Show where authentication would sit in front of the current POC",
                        "Contrast user identity with agent/workload identity",
                        "Identify which credentials must never appear in prompts or logs"
                ),
                List.of(
                        "Tool availability is not permission",
                        "Use short-lived credentials and least privilege",
                        "Keep authorization deterministic and outside the model"
                )
        ));

        add(new Lesson(
                13, "memory-state",
                "Agent Memory, State and Long-Running Workflows", "Memory & State", "8–10 min", "AI Orchestration",
                "Separate conversational memory from durable workflow state.",
                "A user may resume a conversation, but the business workflow must resume from persisted execution state rather than from model recollection alone.",
                List.of(
                        "Short-term conversation context",
                        "Persistent chat history",
                        "Workflow checkpoints",
                        "Business state versus model context",
                        "Resume semantics"
                ),
                List.of(
                        "Persist conversation identifiers",
                        "Persist graph/run checkpoint",
                        "Reload prior state",
                        "Rehydrate only the context needed for the next decision",
                        "Continue from the last valid business checkpoint"
                ),
                List.of(
                        "Compare chat history with run history",
                        "Explain what can be summarized versus what must be stored exactly",
                        "Discuss yesterday-to-today resume behavior"
                ),
                List.of(
                        "Memory is not one thing",
                        "Durable business state must not depend on a model context window",
                        "Resume should be deterministic even when the LLM changes"
                )
        ));

        add(new Lesson(
                14, "mcp",
                "MCP in an Enterprise Agent Architecture", "MCP", "8–10 min", "Integration",
                "Place Model Context Protocol in context without confusing it with the business APIs themselves.",
                "MCP can standardize how an agent discovers and invokes tools or resources, while the underlying enterprise services continue to own their contracts and authorization.",
                List.of(
                        "MCP client and server roles",
                        "Tools, resources and prompts",
                        "Adapter/gateway pattern",
                        "Capability discovery",
                        "Security boundaries"
                ),
                List.of(
                        "Enterprise APIs remain systems of record",
                        "MCP server exposes selected capabilities",
                        "Agent/MCP client discovers approved tools",
                        "MCP invocation maps to backend API call",
                        "Result returns as structured context"
                ),
                List.of(
                        "Map one Spring Boot capability to a hypothetical MCP tool",
                        "Show what MCP standardizes and what it does not",
                        "Discuss where authorization must still be enforced"
                ),
                List.of(
                        "MCP is an integration protocol, not an authorization system",
                        "It can reduce bespoke tool adapters",
                        "Do not bypass domain APIs merely because MCP is available"
                )
        ));

        add(new Lesson(
                15, "responsible-agent-design",
                "Responsible Enterprise Agent Design", "Responsible Design", "9–10 min", "Governance",
                "Close the course with a practical architecture checklist for responsible autonomy.",
                "Production readiness comes from the whole system: identity, policy, bounded tools, validation, HITL, observability, recovery and data governance.",
                List.of(
                        "Bounded autonomy",
                        "Policy enforcement",
                        "Prompt/data protection",
                        "Evaluation",
                        "Operational controls",
                        "Change management"
                ),
                List.of(
                        "Define the business outcome",
                        "Classify action risk",
                        "Expose only required tools",
                        "Validate every model-produced argument",
                        "Add approval gates for material actions",
                        "Instrument, evaluate and continuously review"
                ),
                List.of(
                        "Walk through the architecture from user to database",
                        "Identify the guardrail at each boundary",
                        "End with a production-readiness checklist"
                ),
                List.of(
                        "Do not confuse a successful demo with a production control model",
                        "Every autonomous action needs an accountable owner",
                        "Responsible agent design is architecture plus governance"
                )
        ));

        add(new Lesson(
                16, "source-code-walkthrough",
                "End-to-End Source Code Walkthrough", "Source Walkthrough", "9–10 min", "Hands-on",
                "Connect the visual architecture to the actual GitHub repository and runtime components.",
                "The most useful proof is traceability: business goal → agent node → tool adapter → REST endpoint → schema update → event → UI evidence.",
                List.of(
                        "Repository structure",
                        "Python control tower",
                        "Spring Boot microservices",
                        "Spring Boot ERP dashboard",
                        "Runtime ports and startup sequence"
                ),
                List.of(
                        "Open the combined GitHub repository",
                        "Locate the control tower",
                        "Locate each Spring Boot service",
                        "Locate the ERP dashboard",
                        "Run the example prompt",
                        "Trace one transaction through the stack"
                ),
                List.of(
                        "Use the GitHub button in the navbar",
                        "Open one agent service file and one Spring Boot REST controller",
                        "Complete the trace in the two live UIs"
                ),
                List.of(
                        "A POC is stronger when viewers can inspect every layer",
                        "Keep the demo reproducible and configuration-driven",
                        "Traceability turns architecture claims into visible evidence"
                )
        ));
    }

    private void add(Lesson lesson) {
        lessons.put(lesson.slug(), lesson);
    }

    public List<Lesson> findAll() {
        return List.copyOf(lessons.values());
    }

    public Optional<Lesson> findBySlug(String slug) {
        return Optional.ofNullable(lessons.get(slug));
    }
}
