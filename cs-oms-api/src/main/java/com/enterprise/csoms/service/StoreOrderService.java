package com.enterprise.csoms.service;

import com.enterprise.csoms.dto.request.AllocateOrderRequest;
import com.enterprise.csoms.dto.request.CreateStoreOrderRequest;
import com.enterprise.csoms.dto.response.OrderEventResponse;
import com.enterprise.csoms.dto.response.StoreOrderResponse;
import com.enterprise.csoms.entity.*;
import com.enterprise.csoms.exception.*;
import com.enterprise.csoms.messaging.OmsEventMessage;
import com.enterprise.csoms.messaging.OmsEventPublisher;
import com.enterprise.csoms.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class StoreOrderService {

    private final StoreOrderRepository        orderRepo;
    private final StoreOrderLineRepository    lineRepo;
    private final StoreRegionRepository       regionRepo;
    private final StoreRepository             storeRepo;
    private final InventoryAvailabilityRepository inventoryRepo;
    private final OrderEventRepository        eventRepo;
    private final OmsEventPublisher           publisher;

    // ── CREATE ────────────────────────────────────────────────────────────────

    @Transactional
    public StoreOrderResponse createOrder(CreateStoreOrderRequest req) {
        if (orderRepo.existsByOrderNumber(req.getOrderNumber())) {
            throw new DuplicateResourceException(
                    "Order number already exists: " + req.getOrderNumber());
        }

        StoreRegion region = regionRepo.findByRegionCode(req.getRegionCode())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Region not found: " + req.getRegionCode()));

        StoreOrder order = StoreOrder.builder()
                .externalId(UUID.randomUUID().toString())
                .orderNumber(req.getOrderNumber())
                .campaignExternalId(req.getCampaignExternalId())
                .campaignCode(req.getCampaignCode())
                .region(region)
                .sku(req.getSku())
                .toyDescription(req.getToyDescription())
                .quantityRequested(req.getQuantityRequested())
                .quantityAllocated(0)
                .requestedDeliveryDate(req.getRequestedDeliveryDate())
                .status(StoreOrder.Status.DRAFT)
                .createdBy(req.getCreatedBy())
                .notes(req.getNotes())
                .build();

        order = orderRepo.save(order);
        recordEvent(order, "ORDER_CREATED", null, "DRAFT",
                "Order created for region " + region.getRegionCode(), req.getCreatedBy(), false);

        publisher.publishOrderCreated(buildMessage(order, "ORDER_CREATED", req.getCreatedBy(),
                req.getNotes(), null));

        log.info("Store order created: orderNumber={} region={} sku={}",
                order.getOrderNumber(), region.getRegionCode(), order.getSku());
        return toResponse(order);
    }

    // ── SUBMIT ────────────────────────────────────────────────────────────────

    @Transactional
    public StoreOrderResponse submitOrder(String externalId, String triggeredBy, String notes) {
        StoreOrder order = findOrThrow(externalId);
        requireStatus(order, StoreOrder.Status.DRAFT, "submitted");

        String prev = order.getStatus().name();
        order.setStatus(StoreOrder.Status.SUBMITTED);
        order = orderRepo.save(order);

        publisher.publishOrderSubmitted(buildMessage(order, "ORDER_SUBMITTED",
                triggeredBy, notes, null));
        recordEvent(order, "ORDER_SUBMITTED", prev, "SUBMITTED", notes, triggeredBy, true);

        log.info("Order submitted: orderNumber={}", order.getOrderNumber());
        return toResponse(order);
    }

    // ── ALLOCATE ──────────────────────────────────────────────────────────────
    // Core business logic: split inventory evenly across all active stores in region.
    // KEY step — publishes erp.oms.store-order.allocated consumed by WMS Outbound.

    @Transactional
    public StoreOrderResponse allocateOrder(String externalId, AllocateOrderRequest req) {
        StoreOrder order = findOrThrow(externalId);
        requireStatus(order, StoreOrder.Status.SUBMITTED, "allocated");

        // Check inventory availability
        InventoryAvailability inv = inventoryRepo
                .findBySkuAndCampaignCode(order.getSku(), order.getCampaignCode())
                .orElseThrow(() -> new InsufficientInventoryException(
                        "No inventory record for SKU=" + order.getSku()
                                + " campaign=" + order.getCampaignCode()));

        if (inv.getQuantityRemaining() < order.getQuantityRequested()) {
            throw new InsufficientInventoryException(
                    "Insufficient inventory. Requested=" + order.getQuantityRequested()
                            + " Available=" + inv.getQuantityRemaining()
                            + " for SKU=" + order.getSku());
        }

        // Fetch all active stores in this region
        List<Store> stores = storeRepo.findByRegionIdAndStatus(
                order.getRegion().getId(), Store.Status.ACTIVE);

        if (stores.isEmpty()) {
            throw new ResourceNotFoundException(
                    "No active stores found in region: " + order.getRegion().getRegionCode());
        }

        // Compute per-store quantity (floor division; remainder goes to first store)
        int totalStores    = stores.size();
        int baseQty        = order.getQuantityRequested() / totalStores;
        int remainder      = order.getQuantityRequested() % totalStores;
        int totalAllocated = 0;

        List<StoreOrderLine> lines   = new ArrayList<>();
        List<OmsEventMessage.StoreAllocation> allocs = new ArrayList<>();

        for (int i = 0; i < stores.size(); i++) {
            Store store  = stores.get(i);
            int storeQty = baseQty + (i == 0 ? remainder : 0);
            totalAllocated += storeQty;

            StoreOrderLine line = StoreOrderLine.builder()
                    .externalId(UUID.randomUUID().toString())
                    .storeOrder(order)
                    .store(store)
                    .sku(order.getSku())
                    .quantityAllocated(storeQty)
                    .quantityShipped(0)
                    .quantityDelivered(0)
                    .status(StoreOrderLine.Status.ALLOCATED)
                    .build();
            lineRepo.save(line);
            lines.add(line);

            allocs.add(OmsEventMessage.StoreAllocation.builder()
                    .storeExternalId(store.getExternalId())
                    .storeNumber(store.getStoreNumber())
                    .storeName(store.getStoreName())
                    .city(store.getCity())
                    .stateCode(store.getStateCode())
                    .quantityAllocated(storeQty)
                    .build());
        }

        // Update order — capture save result in a NEW final variable
        String prev = order.getStatus().name();
        order.setQuantityAllocated(totalAllocated);
        order.setQuantityPerStore(baseQty);
        order.setAllocatedAt(LocalDateTime.now());
        order.setStatus(StoreOrder.Status.ALLOCATED);
        final StoreOrder savedOrder = orderRepo.save(order);  // ← final, safe for lambdas

        // Reserve inventory
        inv.setQuantityReserved(inv.getQuantityReserved() + totalAllocated);
        inv.setQuantityRemaining(inv.getQuantityAvailable() - inv.getQuantityReserved());
        inventoryRepo.save(inv);

        // Publish KEY event — WMS Outbound consumes this
        publisher.publishOrderAllocated(buildMessage(savedOrder, "ORDER_ALLOCATED",
                req.getAllocatedBy(), req.getNotes(), allocs));
        recordEvent(savedOrder, "ORDER_ALLOCATED", prev, "ALLOCATED",
                totalStores + " stores x ~" + baseQty + " units. Total=" + totalAllocated,
                req.getAllocatedBy(), true);

        log.info("Order allocated: orderNumber={} stores={} totalQty={}",
                savedOrder.getOrderNumber(), totalStores, totalAllocated);
        return toResponse(savedOrder);
    }

    // ── PICKING ───────────────────────────────────────────────────────────────

    @Transactional
    public StoreOrderResponse markPicking(String externalId, String triggeredBy, String notes) {
        StoreOrder order = findOrThrow(externalId);
        requireStatus(order, StoreOrder.Status.ALLOCATED, "picking");

        String prev = order.getStatus().name();
        order.setStatus(StoreOrder.Status.PICKING);
        order = orderRepo.save(order);

        publisher.publishOrderPicking(buildMessage(order, "ORDER_PICKING",
                triggeredBy, notes, null));
        recordEvent(order, "ORDER_PICKING", prev, "PICKING", notes, triggeredBy, true);

        log.info("Order picking: orderNumber={}", order.getOrderNumber());
        return toResponse(order);
    }

    // ── SHIPPED ───────────────────────────────────────────────────────────────

    @Transactional
    public StoreOrderResponse markShipped(String externalId, String triggeredBy, String notes) {
        StoreOrder order = findOrThrow(externalId);
        requireStatus(order, StoreOrder.Status.PICKING, "shipped");

        String prev = order.getStatus().name();
        order.setStatus(StoreOrder.Status.SHIPPED);

        // Update all order lines to SHIPPED
        List<StoreOrderLine> lines = lineRepo.findByStoreOrderId(order.getId());
        lines.forEach(l -> {
            l.setQuantityShipped(l.getQuantityAllocated());
            l.setStatus(StoreOrderLine.Status.SHIPPED);
            lineRepo.save(l);
        });

        order = orderRepo.save(order);

        publisher.publishOrderShipped(buildMessage(order, "ORDER_SHIPPED",
                triggeredBy, notes, null));
        recordEvent(order, "ORDER_SHIPPED", prev, "SHIPPED", notes, triggeredBy, true);

        log.info("Order shipped: orderNumber={}", order.getOrderNumber());
        return toResponse(order);
    }

    // ── DELIVERED ─────────────────────────────────────────────────────────────

    @Transactional
    public StoreOrderResponse markDelivered(String externalId, String triggeredBy, String notes) {
        StoreOrder order = findOrThrow(externalId);
        requireStatus(order, StoreOrder.Status.SHIPPED, "delivered");

        String prev = order.getStatus().name();
        order.setStatus(StoreOrder.Status.DELIVERED);

        List<StoreOrderLine> lines = lineRepo.findByStoreOrderId(order.getId());
        lines.forEach(l -> {
            l.setQuantityDelivered(l.getQuantityShipped());
            l.setStatus(StoreOrderLine.Status.DELIVERED);
            lineRepo.save(l);
        });

        order = orderRepo.save(order);

        publisher.publishOrderDelivered(buildMessage(order, "ORDER_DELIVERED",
                triggeredBy, notes, null));
        recordEvent(order, "ORDER_DELIVERED", prev, "DELIVERED", notes, triggeredBy, true);

        log.info("Order delivered: orderNumber={}", order.getOrderNumber());
        return toResponse(order);
    }

    // ── CANCEL ────────────────────────────────────────────────────────────────

    @Transactional
    public StoreOrderResponse cancelOrder(String externalId, String triggeredBy, String notes) {
        StoreOrder order = findOrThrow(externalId);
        if (order.getStatus() == StoreOrder.Status.SHIPPED
                || order.getStatus() == StoreOrder.Status.DELIVERED
                || order.getStatus() == StoreOrder.Status.CANCELLED) {
            throw new InvalidStateException(
                    "Cannot cancel order in status: " + order.getStatus());
        }

        // Capture values needed in lambda BEFORE any reassignment
        final int    qtyToRelease      = order.getQuantityAllocated();
        final String skuToRelease      = order.getSku();
        final String campaignToRelease = order.getCampaignCode();

        // Release reserved inventory if allocated
        if (order.getStatus() == StoreOrder.Status.ALLOCATED
                || order.getStatus() == StoreOrder.Status.PICKING) {
            inventoryRepo.findBySkuAndCampaignCode(skuToRelease, campaignToRelease)
                    .ifPresent(inv -> {
                        inv.setQuantityReserved(
                                Math.max(0, inv.getQuantityReserved() - qtyToRelease));
                        inv.setQuantityRemaining(
                                inv.getQuantityAvailable() - inv.getQuantityReserved());
                        inventoryRepo.save(inv);
                    });
        }

        String prev = order.getStatus().name();
        order.setStatus(StoreOrder.Status.CANCELLED);
        final StoreOrder savedOrder = orderRepo.save(order);

        publisher.publishOrderCancelled(buildMessage(savedOrder, "ORDER_CANCELLED",
                triggeredBy, notes, null));
        recordEvent(savedOrder, "ORDER_CANCELLED", prev, "CANCELLED", notes, triggeredBy, true);

        log.info("Order cancelled: orderNumber={}", savedOrder.getOrderNumber());
        return toResponse(savedOrder);
    }

    // ── READS ─────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public StoreOrderResponse getOrder(String externalId) {
        return toResponse(findOrThrow(externalId));
    }

    @Transactional(readOnly = true)
    public List<StoreOrderResponse> getAllOrders() {
        return orderRepo.findAll().stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<StoreOrderResponse> getOrdersByStatus(String status) {
        return orderRepo.findByStatus(StoreOrder.Status.valueOf(status))
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<StoreOrderResponse> getOrdersByCampaign(String campaignCode) {
        return orderRepo.findByCampaignCode(campaignCode)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<OrderEventResponse> getOrderEvents(String externalId) {
        StoreOrder order = findOrThrow(externalId);
        return eventRepo.findByStoreOrderIdOrderByEventAtDesc(order.getId())
                .stream().map(this::toEventResponse).collect(Collectors.toList());
    }

    // ── HELPERS ───────────────────────────────────────────────────────────────

    public StoreOrder findOrThrow(String externalId) {
        return orderRepo.findByExternalId(externalId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Store order not found: " + externalId));
    }

    private void requireStatus(StoreOrder order, StoreOrder.Status required, String action) {
        if (order.getStatus() != required) {
            throw new InvalidStateException(
                    "Order must be " + required.name() + " to be " + action
                            + ". Current: " + order.getStatus());
        }
    }

    private void recordEvent(StoreOrder order, String type, String prev, String next,
                              String notes, String by, boolean published) {
        eventRepo.save(OrderEvent.builder()
                .storeOrder(order).eventType(type).previousStatus(prev).newStatus(next)
                .notes(notes).triggeredBy(by).eventAt(LocalDateTime.now())
                .rabbitmqPublished(published).build());
    }

    private OmsEventMessage buildMessage(StoreOrder order, String eventType,
                                          String triggeredBy, String notes,
                                          List<OmsEventMessage.StoreAllocation> allocs) {
        StoreRegion region = order.getRegion();
        return OmsEventMessage.builder()
                .eventType(eventType)
                .orderExternalId(order.getExternalId())
                .orderNumber(order.getOrderNumber())
                .orderStatus(order.getStatus().name())
                .campaignExternalId(order.getCampaignExternalId())
                .campaignCode(order.getCampaignCode())
                .regionCode(region.getRegionCode())
                .regionName(region.getRegionName())
                .distributionDc(region.getDistributionDc())
                .storeCount(region.getStoreCount())
                .sku(order.getSku())
                .toyDescription(order.getToyDescription())
                .quantityRequested(order.getQuantityRequested())
                .quantityAllocated(order.getQuantityAllocated())
                .quantityPerStore(order.getQuantityPerStore())
                .requestedDeliveryDate(order.getRequestedDeliveryDate())
                .storeAllocations(allocs)
                .triggeredBy(triggeredBy)
                .notes(notes)
                .eventTimestamp(LocalDateTime.now())
                .build();
    }

    public StoreOrderResponse toResponse(StoreOrder o) {
        List<StoreOrderLine> lines = lineRepo.findByStoreOrderId(o.getId());
        List<StoreOrderResponse.OrderLineResponse> lineResponses = lines.stream()
                .map(l -> StoreOrderResponse.OrderLineResponse.builder()
                        .storeExternalId(l.getStore().getExternalId())
                        .storeNumber(l.getStore().getStoreNumber())
                        .storeName(l.getStore().getStoreName())
                        .city(l.getStore().getCity())
                        .stateCode(l.getStore().getStateCode())
                        .quantityAllocated(l.getQuantityAllocated())
                        .quantityShipped(l.getQuantityShipped())
                        .quantityDelivered(l.getQuantityDelivered())
                        .status(l.getStatus().name())
                        .build())
                .collect(Collectors.toList());

        StoreRegion region = o.getRegion();
        return StoreOrderResponse.builder()
                .externalId(o.getExternalId())
                .orderNumber(o.getOrderNumber())
                .campaignExternalId(o.getCampaignExternalId())
                .campaignCode(o.getCampaignCode())
                .regionCode(region.getRegionCode())
                .regionName(region.getRegionName())
                .distributionDc(region.getDistributionDc())
                .sku(o.getSku())
                .toyDescription(o.getToyDescription())
                .quantityRequested(o.getQuantityRequested())
                .quantityAllocated(o.getQuantityAllocated())
                .quantityPerStore(o.getQuantityPerStore())
                .requestedDeliveryDate(o.getRequestedDeliveryDate())
                .allocatedAt(o.getAllocatedAt())
                .status(o.getStatus().name())
                .createdBy(o.getCreatedBy())
                .notes(o.getNotes())
                .createdAt(o.getCreatedAt())
                .updatedAt(o.getUpdatedAt())
                .orderLines(lineResponses)
                .build();
    }

    private OrderEventResponse toEventResponse(OrderEvent e) {
        return OrderEventResponse.builder()
                .id(e.getId()).eventType(e.getEventType())
                .previousStatus(e.getPreviousStatus()).newStatus(e.getNewStatus())
                .notes(e.getNotes()).triggeredBy(e.getTriggeredBy())
                .rabbitmqPublished(e.isRabbitmqPublished()).eventAt(e.getEventAt())
                .build();
    }
}
