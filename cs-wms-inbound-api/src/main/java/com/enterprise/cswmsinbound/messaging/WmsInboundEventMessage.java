package com.enterprise.cswmsinbound.messaging;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * JSON payload published to RabbitMQ for every WMS inbound lifecycle event.
 *
 * KEY event: erp.wms.inbound.putaway.completed
 *   Carries SKU, accepted quantity, and bin locations.
 *   Consumed by cs-oms-api to mark inventory available for store allocation.
 */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class WmsInboundEventMessage {

    @Builder.Default
    private String source = "cs-wms-inbound-api";

    private String routingKey;
    private String eventType;

    // ── ASN context ───────────────────────────────────────────────────────────
    private String asnExternalId;
    private String asnNumber;
    private String asnStatus;

    // ── Cross-service refs ────────────────────────────────────────────────────
    private String poExternalId;
    private String poNumber;
    private String campaignExternalId;
    private String campaignCode;
    private String vendorExternalId;
    private String vendorCode;
    private String vendorName;

    // ── Shipment details ──────────────────────────────────────────────────────
    private String  sku;
    private String  toyDescription;
    private Integer expectedQuantity;
    private Integer acceptedQuantity;
    private Integer damagedQuantity;
    private Integer varianceQuantity;
    private String  carrierName;
    private String  trackingNumber;
    private String  destinationPort;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate actualArrivalDate;

    // ── Putaway locations (populated on putaway.completed only) ───────────────
    private List<BinLocation> binLocations;

    // ── Meta ──────────────────────────────────────────────────────────────────
    private String triggeredBy;
    private String notes;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime eventTimestamp;

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class BinLocation {
        private String warehouseZone;
        private String warehouseAisle;
        private String warehouseBin;
        private Integer quantity;
    }
}
