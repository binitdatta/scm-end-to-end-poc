package com.enterprise.cscrm.service;

import com.enterprise.cscrm.dto.request.CreateCustomerRequest;
import com.enterprise.cscrm.dto.response.CustomerResponse;
import com.enterprise.cscrm.entity.Customer;
import com.enterprise.cscrm.exception.DuplicateResourceException;
import com.enterprise.cscrm.exception.ResourceNotFoundException;
import com.enterprise.cscrm.messaging.CampaignEventMessage;
import com.enterprise.cscrm.messaging.CampaignEventPublisher;
import com.enterprise.cscrm.repository.CustomerRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class CustomerService {

    private final CustomerRepository     customerRepository;
    private final CampaignEventPublisher publisher;

    // ── CREATE ────────────────────────────────────────────────────────────────

    @Transactional
    public CustomerResponse createCustomer(CreateCustomerRequest req) {
        if (customerRepository.existsByEmail(req.getEmail())) {
            throw new DuplicateResourceException(
                    "Customer already exists with email: " + req.getEmail());
        }

        Customer.Tier tier = (req.getTier() != null)
                ? Customer.Tier.valueOf(req.getTier())
                : Customer.Tier.STANDARD;

        Customer customer = Customer.builder()
                .externalId(UUID.randomUUID().toString())
                .firstName(req.getFirstName())
                .lastName(req.getLastName())
                .email(req.getEmail())
                .phone(req.getPhone())
                .tier(tier)
                .status(Customer.Status.ACTIVE)
                .build();

        customer = customerRepository.save(customer);

        // Notify Control Tower of new customer via RabbitMQ
        CampaignEventMessage message = CampaignEventMessage.builder()
                .source("cs-crm-api")
                .eventType("CUSTOMER_CREATED")
                .newStatus("ACTIVE")
                .campaignExternalId(null)
                .campaignCode("N/A")
                .campaignName("N/A")
                .triggeredBy("system")
                .notes("New customer: " + customer.getEmail() + " tier=" + customer.getTier())
                .eventTimestamp(LocalDateTime.now())
                .build();
        publisher.publishCustomerCreated(message);

        log.info("Customer created: externalId={} email={}", customer.getExternalId(), customer.getEmail());
        return toResponse(customer);
    }

    // ── GET ───────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public CustomerResponse getCustomer(String externalId) {
        return toResponse(findByExternalIdOrThrow(externalId));
    }

    @Transactional(readOnly = true)
    public List<CustomerResponse> getAllCustomers() {
        return customerRepository.findAll()
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    // ── HELPERS ───────────────────────────────────────────────────────────────

    private Customer findByExternalIdOrThrow(String externalId) {
        return customerRepository.findByExternalId(externalId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Customer not found: " + externalId));
    }

    private CustomerResponse toResponse(Customer c) {
        return CustomerResponse.builder()
                .externalId(c.getExternalId())
                .firstName(c.getFirstName())
                .lastName(c.getLastName())
                .email(c.getEmail())
                .phone(c.getPhone())
                .tier(c.getTier().name())
                .status(c.getStatus().name())
                .createdAt(c.getCreatedAt())
                .updatedAt(c.getUpdatedAt())
                .build();
    }
}
