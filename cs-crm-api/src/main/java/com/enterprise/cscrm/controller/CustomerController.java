package com.enterprise.cscrm.controller;

import com.enterprise.cscrm.dto.request.CreateCustomerRequest;
import com.enterprise.cscrm.dto.response.ApiResponse;
import com.enterprise.cscrm.dto.response.CustomerResponse;
import com.enterprise.cscrm.service.CustomerService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/customers")
@RequiredArgsConstructor
public class CustomerController {

    private final CustomerService customerService;

    /**
     * POST /api/v1/customers
     * Register a new customer.
     * Publishes erp.crm.customer.created to RabbitMQ.
     */
    @PostMapping
    public ResponseEntity<ApiResponse<CustomerResponse>> createCustomer(
            @Valid @RequestBody CreateCustomerRequest request) {
        CustomerResponse response = customerService.createCustomer(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(response, "Customer created successfully"));
    }

    /**
     * GET /api/v1/customers
     * List all customers.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<CustomerResponse>>> getAllCustomers() {
        List<CustomerResponse> customers = customerService.getAllCustomers();
        return ResponseEntity.ok(ApiResponse.ok(customers, "Customers retrieved"));
    }

    /**
     * GET /api/v1/customers/{externalId}
     * Get a single customer by external UUID.
     */
    @GetMapping("/{externalId}")
    public ResponseEntity<ApiResponse<CustomerResponse>> getCustomer(
            @PathVariable String externalId) {
        CustomerResponse response = customerService.getCustomer(externalId);
        return ResponseEntity.ok(ApiResponse.ok(response, "Customer retrieved"));
    }
}
