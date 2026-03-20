package com.enterprise.csvendor.messaging;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * JSON payload published to RabbitMQ for every vendor domain event.
 * The Control Tower Flask app deserializes this from the queue.
 *
 * Routing key pattern: erp.vendor.<entity>.<event>
 */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class VendorEventMessage {

    @Builder.Default
    private String source = "cs-vendor-api";

    private String routingKey;
    private String eventType;

    // ── RFQ context ──
    private String rfqExternalId;
    private String rfqNumber;
    private String campaignExternalId;
    private String campaignCode;
    private String rfqStatus;

    // ── Vendor context ──
    private String vendorExternalId;
    private String vendorCode;
    private String vendorName;
    private String vendorCountry;

    // ── Award context (populated on rfq.awarded events only) ──
    private String  awardExternalId;
    private Integer awardedQuantity;
    private BigDecimal awardedUnitCostUsd;
    private BigDecimal totalAwardValueUsd;
    private String  awardedBy;

    private String triggeredBy;
    private String notes;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime eventTimestamp;
}
