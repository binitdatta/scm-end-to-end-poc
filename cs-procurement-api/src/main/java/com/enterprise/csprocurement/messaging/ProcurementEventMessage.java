package com.enterprise.csprocurement.messaging;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * JSON payload published to RabbitMQ for every PO and invoice lifecycle event.
 *
 * Routing key pattern: erp.procurement.<entity>.<event>
 *
 * KEY downstream event: erp.procurement.po.ready-to-ship
 *   Payload carries vendor, quantity, ship date, port details.
 *   Consumed by cs-wms-inbound-api to create an ASN and schedule receiving.
 */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ProcurementEventMessage {

    @Builder.Default
    private String source = "cs-procurement-api";

    private String routingKey;
    private String eventType;

    // ── PO context ────────────────────────────────────────────────────────────
    private String poExternalId;
    private String poNumber;
    private String rfqExternalId;
    private String rfqNumber;
    private String campaignExternalId;
    private String campaignCode;
    private String poStatus;

    // ── Vendor context ────────────────────────────────────────────────────────
    private String vendorExternalId;
    private String vendorCode;
    private String vendorName;
    private String vendorCountry;

    // ── Order details ─────────────────────────────────────────────────────────
    private String      toyDescription;
    private Integer     quantityOrdered;
    private BigDecimal  unitPriceUsd;
    private BigDecimal  totalValueUsd;
    private String      paymentTerms;
    private String      incoterms;
    private String      destinationPort;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate   requiredDeliveryDate;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate   estimatedShipDate;

    // ── Invoice context (populated for invoice events only) ───────────────────
    private String     invoiceExternalId;
    private String     invoiceNumber;
    private BigDecimal invoiceTotalUsd;

    // ── Meta ──────────────────────────────────────────────────────────────────
    private String triggeredBy;
    private String notes;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime eventTimestamp;
}
