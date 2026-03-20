package com.enterprise.csprocurement.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "purchase_orders")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class PurchaseOrder {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "external_id",          nullable = false, unique = true, length = 64)
    private String externalId;

    @Column(name = "po_number",            nullable = false, unique = true, length = 50)
    private String poNumber;

    // ── Cross-service references ──────────────────────────────────────────────
    @Column(name = "rfq_external_id",      nullable = false, length = 64)
    private String rfqExternalId;

    @Column(name = "rfq_number",           nullable = false, length = 50)
    private String rfqNumber;

    @Column(name = "campaign_external_id", nullable = false, length = 64)
    private String campaignExternalId;

    @Column(name = "campaign_code",        nullable = false, length = 50)
    private String campaignCode;

    @Column(name = "award_external_id",    nullable = false, unique = true, length = 64)
    private String awardExternalId;

    // ── Vendor (denormalized) ─────────────────────────────────────────────────
    @Column(name = "vendor_external_id",   nullable = false, length = 64)
    private String vendorExternalId;

    @Column(name = "vendor_code",          nullable = false, length = 50)
    private String vendorCode;

    @Column(name = "vendor_name",          nullable = false, length = 200)
    private String vendorName;

    @Enumerated(EnumType.STRING)
    @Column(name = "vendor_country",       nullable = false, length = 20)
    private VendorCountry vendorCountry;

    // ── Line item totals ──────────────────────────────────────────────────────
    @Column(name = "toy_description",      nullable = false, length = 200)
    private String toyDescription;

    @Column(name = "quantity_ordered",     nullable = false)
    private Integer quantityOrdered;

    @Column(name = "unit_price_usd",       nullable = false, precision = 10, scale = 4)
    private BigDecimal unitPriceUsd;

    @Column(name = "total_value_usd",      nullable = false, precision = 15, scale = 2)
    private BigDecimal totalValueUsd;

    @Column(name = "currency",             nullable = false, length = 10)
    private String currency = "USD";

    // ── Logistics ─────────────────────────────────────────────────────────────
    @Column(name = "payment_terms",        length = 100)
    private String paymentTerms;

    @Column(name = "required_delivery_date", nullable = false)
    private LocalDate requiredDeliveryDate;

    @Column(name = "estimated_ship_date")
    private LocalDate estimatedShipDate;

    @Column(name = "incoterms",            length = 20)
    private String incoterms;

    @Column(name = "destination_port",     length = 100)
    private String destinationPort;

    // ── Lifecycle ─────────────────────────────────────────────────────────────
    @Enumerated(EnumType.STRING)
    @Column(name = "status",              nullable = false, length = 30)
    private Status status = Status.DRAFT;

    @Column(name = "created_by",          nullable = false, length = 100)
    private String createdBy;

    @Column(name = "approved_by",         length = 100)
    private String approvedBy;

    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
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

    @OneToMany(mappedBy = "purchaseOrder", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private List<PoLineItem> lineItems = new ArrayList<>();

    @OneToMany(mappedBy = "purchaseOrder", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private List<PoEvent> events = new ArrayList<>();

    @OneToMany(mappedBy = "purchaseOrder", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private List<Invoice> invoices = new ArrayList<>();

    public enum Status {
        DRAFT, APPROVED, SENT_TO_VENDOR, ACKNOWLEDGED,
        IN_PRODUCTION, READY_TO_SHIP, COMPLETED, CANCELLED
    }

    public enum VendorCountry { CHINA, VIETNAM, INDIA, THAILAND, OTHER }
}
