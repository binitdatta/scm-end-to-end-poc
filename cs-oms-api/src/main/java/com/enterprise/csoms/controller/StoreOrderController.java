package com.enterprise.csoms.controller;

import com.enterprise.csoms.dto.request.AllocateOrderRequest;
import com.enterprise.csoms.dto.request.CreateStoreOrderRequest;
import com.enterprise.csoms.dto.response.ApiResponse;
import com.enterprise.csoms.dto.response.OrderEventResponse;
import com.enterprise.csoms.dto.response.StoreOrderResponse;
import com.enterprise.csoms.service.StoreOrderService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/store-orders")
@RequiredArgsConstructor
public class StoreOrderController {

    private final StoreOrderService orderService;

    /** POST /api/v1/store-orders — Create store order (DRAFT) */
    @PostMapping
    public ResponseEntity<ApiResponse<StoreOrderResponse>> createOrder(
            @Valid @RequestBody CreateStoreOrderRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(orderService.createOrder(request),
                        "Store order created successfully"));
    }

    /** GET /api/v1/store-orders */
    @GetMapping
    public ResponseEntity<ApiResponse<List<StoreOrderResponse>>> getAllOrders() {
        return ResponseEntity.ok(ApiResponse.ok(orderService.getAllOrders(), "Orders retrieved"));
    }

    /** GET /api/v1/store-orders/{externalId} */
    @GetMapping("/{externalId}")
    public ResponseEntity<ApiResponse<StoreOrderResponse>> getOrder(
            @PathVariable String externalId) {
        return ResponseEntity.ok(ApiResponse.ok(orderService.getOrder(externalId), "Order retrieved"));
    }

    /** GET /api/v1/store-orders/status/{status} */
    @GetMapping("/status/{status}")
    public ResponseEntity<ApiResponse<List<StoreOrderResponse>>> getByStatus(
            @PathVariable String status) {
        return ResponseEntity.ok(ApiResponse.ok(
                orderService.getOrdersByStatus(status.toUpperCase()),
                "Orders retrieved for status: " + status));
    }

    /** GET /api/v1/store-orders/campaign/{campaignCode} */
    @GetMapping("/campaign/{campaignCode}")
    public ResponseEntity<ApiResponse<List<StoreOrderResponse>>> getByCampaign(
            @PathVariable String campaignCode) {
        return ResponseEntity.ok(ApiResponse.ok(
                orderService.getOrdersByCampaign(campaignCode),
                "Orders retrieved for campaign: " + campaignCode));
    }

    /** GET /api/v1/store-orders/{externalId}/events */
    @GetMapping("/{externalId}/events")
    public ResponseEntity<ApiResponse<List<OrderEventResponse>>> getEvents(
            @PathVariable String externalId) {
        return ResponseEntity.ok(ApiResponse.ok(
                orderService.getOrderEvents(externalId), "Order events retrieved"));
    }

    /**
     * POST /api/v1/store-orders/{externalId}/submit
     * DRAFT → SUBMITTED. Publishes erp.oms.store-order.submitted
     */
    @PostMapping("/{externalId}/submit")
    public ResponseEntity<ApiResponse<StoreOrderResponse>> submitOrder(
            @PathVariable String externalId,
            @RequestBody(required = false) Map<String, String> body) {
        String by    = body != null ? body.getOrDefault("triggeredBy", "oms.planner") : "oms.planner";
        String notes = body != null ? body.get("notes") : null;
        return ResponseEntity.ok(ApiResponse.ok(
                orderService.submitOrder(externalId, by, notes), "Order submitted"));
    }

    /**
     * POST /api/v1/store-orders/{externalId}/allocate
     * SUBMITTED → ALLOCATED. Splits inventory across all stores in region.
     * Publishes erp.oms.store-order.allocated — KEY event for WMS Outbound.
     */
    @PostMapping("/{externalId}/allocate")
    public ResponseEntity<ApiResponse<StoreOrderResponse>> allocateOrder(
            @PathVariable String externalId,
            @Valid @RequestBody AllocateOrderRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(
                orderService.allocateOrder(externalId, request),
                "Order allocated successfully"));
    }

    /**
     * POST /api/v1/store-orders/{externalId}/picking
     * ALLOCATED → PICKING. Publishes erp.oms.store-order.picking
     */
    @PostMapping("/{externalId}/picking")
    public ResponseEntity<ApiResponse<StoreOrderResponse>> markPicking(
            @PathVariable String externalId,
            @RequestBody(required = false) Map<String, String> body) {
        String by    = body != null ? body.getOrDefault("triggeredBy", "wms.outbound") : "wms.outbound";
        String notes = body != null ? body.get("notes") : null;
        return ResponseEntity.ok(ApiResponse.ok(
                orderService.markPicking(externalId, by, notes), "Order picking started"));
    }

    /**
     * POST /api/v1/store-orders/{externalId}/shipped
     * PICKING → SHIPPED. Publishes erp.oms.store-order.shipped
     */
    @PostMapping("/{externalId}/shipped")
    public ResponseEntity<ApiResponse<StoreOrderResponse>> markShipped(
            @PathVariable String externalId,
            @RequestBody(required = false) Map<String, String> body) {
        String by    = body != null ? body.getOrDefault("triggeredBy", "tms.carrier") : "tms.carrier";
        String notes = body != null ? body.get("notes") : null;
        return ResponseEntity.ok(ApiResponse.ok(
                orderService.markShipped(externalId, by, notes), "Order shipped"));
    }

    /**
     * POST /api/v1/store-orders/{externalId}/delivered
     * SHIPPED → DELIVERED. Publishes erp.oms.store-order.delivered
     */
    @PostMapping("/{externalId}/delivered")
    public ResponseEntity<ApiResponse<StoreOrderResponse>> markDelivered(
            @PathVariable String externalId,
            @RequestBody(required = false) Map<String, String> body) {
        String by    = body != null ? body.getOrDefault("triggeredBy", "tms.carrier") : "tms.carrier";
        String notes = body != null ? body.get("notes") : null;
        return ResponseEntity.ok(ApiResponse.ok(
                orderService.markDelivered(externalId, by, notes), "Order delivered"));
    }

    /**
     * POST /api/v1/store-orders/{externalId}/cancel
     * → CANCELLED. Releases reserved inventory. Publishes erp.oms.store-order.cancelled
     */
    @PostMapping("/{externalId}/cancel")
    public ResponseEntity<ApiResponse<StoreOrderResponse>> cancelOrder(
            @PathVariable String externalId,
            @RequestBody(required = false) Map<String, String> body) {
        String by    = body != null ? body.getOrDefault("triggeredBy", "oms.planner") : "oms.planner";
        String notes = body != null ? body.get("notes") : null;
        return ResponseEntity.ok(ApiResponse.ok(
                orderService.cancelOrder(externalId, by, notes), "Order cancelled"));
    }
}
