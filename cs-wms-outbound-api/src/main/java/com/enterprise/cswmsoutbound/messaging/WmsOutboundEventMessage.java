package com.enterprise.cswmsoutbound.messaging;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * JSON payload published to RabbitMQ for every WMS outbound event.
 *
 * KEY event: erp.wms.outbound.shipment.dispatched
 *   Carries shipment number, carrier PRO, region code, store carton list.
 *   Consumed by cs-tms-api to create delivery loads and track store delivery.
 */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class WmsOutboundEventMessage {

    @Builder.Default
    private String source = "cs-wms-outbound-api";

    private String routingKey;
    private String eventType;

    // ── Pick wave context ─────────────────────────────────────────────────────
    private String waveExternalId;
    private String waveNumber;
    private String waveStatus;

    // ── Shipment context ──────────────────────────────────────────────────────
    private String shipmentExternalId;
    private String shipmentNumber;
    private String shipmentStatus;

    // ── Cross-service refs ────────────────────────────────────────────────────
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

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate requiredDeliveryDate;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate actualShipDate;

    // ── Store lines (populated on dispatched event) ───────────────────────────
    private List<StoreCarton> storeCartons;

    // ── Meta ──────────────────────────────────────────────────────────────────
    private String triggeredBy;
    private String notes;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime eventTimestamp;

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class StoreCarton {
        private String  storeExternalId;
        private String  storeNumber;
        private String  storeName;
        private String  city;
        private String  stateCode;
        private Integer quantity;
        private String  cartonLabel;
    }
}
