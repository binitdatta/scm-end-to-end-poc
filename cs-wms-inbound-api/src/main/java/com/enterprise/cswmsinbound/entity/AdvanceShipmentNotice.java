package com.enterprise.cswmsinbound.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "advance_shipment_notices")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AdvanceShipmentNotice {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "external_id",           nullable = false, unique = true, length = 64)
    private String externalId;

    @Column(name = "asn_number",            nullable = false, unique = true, length = 50)
    private String asnNumber;

    // ── Cross-service refs ────────────────────────────────────────────────────
    @Column(name = "po_external_id",        nullable = false, unique = true, length = 64)
    private String poExternalId;

    @Column(name = "po_number",             nullable = false, length = 50)
    private String poNumber;

    @Column(name = "campaign_external_id",  nullable = false, length = 64)
    private String campaignExternalId;

    @Column(name = "campaign_code",         nullable = false, length = 50)
    private String campaignCode;

    @Column(name = "vendor_external_id",    nullable = false, length = 64)
    private String vendorExternalId;

    @Column(name = "vendor_code",           nullable = false, length = 50)
    private String vendorCode;

    @Column(name = "vendor_name",           nullable = false, length = 200)
    private String vendorName;

    @Column(name = "vendor_country",        nullable = false, length = 20)
    private String vendorCountry;

    // ── Shipment details ──────────────────────────────────────────────────────
    @Column(name = "sku",                   nullable = false, length = 50)
    private String sku;

    @Column(name = "toy_description",       nullable = false, length = 200)
    private String toyDescription;

    @Column(name = "expected_quantity",     nullable = false)
    private Integer expectedQuantity;

    @Column(name = "unit_of_measure",       nullable = false, length = 20)
    private String unitOfMeasure = "PIECES";

    @Column(name = "carrier_name",          length = 100)
    private String carrierName;

    @Column(name = "tracking_number",       length = 100)
    private String trackingNumber;

    @Column(name = "origin_port",           length = 100)
    private String originPort;

    @Column(name = "destination_port",      length = 100)
    private String destinationPort;

    @Column(name = "incoterms",             length = 20)
    private String incoterms;

    // ── Dates ─────────────────────────────────────────────────────────────────
    @Column(name = "estimated_arrival_date")
    private LocalDate estimatedArrivalDate;

    @Column(name = "actual_arrival_date")
    private LocalDate actualArrivalDate;

    @Column(name = "dock_appointment_date")
    private LocalDateTime dockAppointmentDate;

    @Column(name = "dock_door",             length = 10)
    private String dockDoor;

    // ── Lifecycle ─────────────────────────────────────────────────────────────
    @Enumerated(EnumType.STRING)
    @Column(name = "status",               nullable = false, length = 30)
    private Status status = Status.CREATED;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    @Column(name = "created_by",           nullable = false, length = 100)
    private String createdBy;

    @Column(name = "created_at",           nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at",           nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    @OneToOne(mappedBy = "asn", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private ReceivingRecord receivingRecord;

    @OneToMany(mappedBy = "asn", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private List<PutawayTask> putawayTasks = new ArrayList<>();

    @OneToMany(mappedBy = "asn", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private List<AsnEvent> events = new ArrayList<>();

    public enum Status {
        CREATED, SCHEDULED, IN_TRANSIT, ARRIVED,
        RECEIVING, RECEIVED, PUTAWAY_IN_PROGRESS,
        PUTAWAY_COMPLETED, CANCELLED
    }
}
