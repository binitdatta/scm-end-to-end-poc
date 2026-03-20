package com.enterprise.cstms.messaging;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * JSON payload published to RabbitMQ for every TMS event.
 *
 * KEY event: erp.tms.delivery.pod-confirmed
 *   The FINAL event in the entire supply chain — published once all
 *   store deliveries in a load have POD confirmed. Carries full
 *   per-store delivery details including signatory and delivered quantity.
 *   Consumed by Flask Control Tower for BI dashboards and analytics.
 */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TmsEventMessage {

    @Builder.Default
    private String source = "cs-tms-api";

    private String routingKey;
    private String eventType;

    // ── Load context ──────────────────────────────────────────────────────────
    private String loadExternalId;
    private String loadNumber;
    private String loadStatus;

    // ── Cross-service refs ────────────────────────────────────────────────────
    private String shipmentExternalId;
    private String shipmentNumber;
    private String storeOrderExternalId;
    private String storeOrderNumber;
    private String campaignExternalId;
    private String campaignCode;
    private String regionCode;
    private String distributionDc;

    // ── Product ───────────────────────────────────────────────────────────────
    private String  sku;
    private String  toyDescription;
    private Integer totalCartons;
    private Integer totalUnits;

    // ── Carrier ───────────────────────────────────────────────────────────────
    private String carrierName;
    private String proNumber;
    private String driverName;
    private String truckNumber;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate requiredDeliveryDate;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate pickupDate;

    // ── POD details (populated on pod-confirmed event) ────────────────────────
    private Integer totalStoresDelivered;
    private Integer totalUnitsDelivered;
    private List<StorePod> storePods;

    // ── Meta ──────────────────────────────────────────────────────────────────
    private String triggeredBy;
    private String notes;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime eventTimestamp;

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class StorePod {
        private String   storeExternalId;
        private String   storeNumber;
        private String   storeName;
        private String   city;
        private String   stateCode;
        private Integer  quantity;
        private Integer  deliveredQuantity;
        private String   podSignatory;

        @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
        private LocalDateTime deliveredAt;

        @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
        private LocalDateTime podConfirmedAt;
    }
}
