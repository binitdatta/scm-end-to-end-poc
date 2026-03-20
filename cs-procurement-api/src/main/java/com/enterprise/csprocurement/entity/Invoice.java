package com.enterprise.csprocurement.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "invoices")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Invoice {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "external_id",        nullable = false, unique = true, length = 64)
    private String externalId;

    @Column(name = "invoice_number",     nullable = false, unique = true, length = 50)
    private String invoiceNumber;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "po_id",          nullable = false)
    private PurchaseOrder purchaseOrder;

    @Column(name = "vendor_external_id", nullable = false, length = 64)
    private String vendorExternalId;

    @Column(name = "invoice_amount_usd", nullable = false, precision = 15, scale = 2)
    private BigDecimal invoiceAmountUsd;

    @Column(name = "tax_amount_usd",     nullable = false, precision = 15, scale = 2)
    private BigDecimal taxAmountUsd = BigDecimal.ZERO;

    @Column(name = "total_amount_usd",   nullable = false, precision = 15, scale = 2)
    private BigDecimal totalAmountUsd;

    @Column(name = "invoice_date",       nullable = false)
    private LocalDate invoiceDate;

    @Column(name = "due_date",           nullable = false)
    private LocalDate dueDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "status",             nullable = false, length = 20)
    private Status status = Status.RECEIVED;

    @Column(name = "paid_at")
    private LocalDateTime paidAt;

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

    public enum Status { RECEIVED, UNDER_REVIEW, APPROVED, PAID, DISPUTED }
}
