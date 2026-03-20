package com.enterprise.csoms.messaging;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * JSON payload published to RabbitMQ for every OMS store order event.
 *
 * KEY event: erp.oms.store-order.allocated
 *   Carries order number, region, SKU, total qty allocated,
 *   and per-store line breakdown. Consumed by cs-wms-outbound-api
 *   to create pick waves and pack store shipments.
 */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class OmsEventMessage {

    @Builder.Default
    private String source = "cs-oms-api";

    private String routingKey;
    private String eventType;

    // ── Order context ─────────────────────────────────────────────────────────
    private String orderExternalId;
    private String orderNumber;
    private String orderStatus;
    private String campaignExternalId;
    private String campaignCode;

    // ── Region ────────────────────────────────────────────────────────────────
    private String regionCode;
    private String regionName;
    private String distributionDc;
    private Integer storeCount;

    // ── Product ───────────────────────────────────────────────────────────────
    private String  sku;
    private String  toyDescription;
    private Integer quantityRequested;
    private Integer quantityAllocated;
    private Integer quantityPerStore;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate requestedDeliveryDate;

    // ── Per-store lines (populated on allocated event) ─────────────────────────
    private List<StoreAllocation> storeAllocations;

    // ── Meta ──────────────────────────────────────────────────────────────────
    private String triggeredBy;
    private String notes;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime eventTimestamp;

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class StoreAllocation {
        private String  storeExternalId;
        private String  storeNumber;
        private String  storeName;
        private String  city;
        private String  stateCode;
        private Integer quantityAllocated;
    }
}
