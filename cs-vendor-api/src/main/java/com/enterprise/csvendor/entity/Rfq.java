package com.enterprise.csvendor.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "rfqs")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Rfq {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "external_id", nullable = false, unique = true, length = 64)
    private String externalId;

    @Column(name = "rfq_number", nullable = false, unique = true, length = 50)
    private String rfqNumber;

    @Column(name = "campaign_external_id", nullable = false, length = 64)
    private String campaignExternalId;

    @Column(name = "campaign_code", nullable = false, length = 50)
    private String campaignCode;

    @Column(name = "title", nullable = false, length = 200)
    private String title;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "toy_category", length = 100)
    private String toyCategory;

    @Column(name = "quantity_required", nullable = false)
    private Integer quantityRequired;

    @Column(name = "unit", nullable = false, length = 30)
    private String unit = "PIECES";

    @Column(name = "target_unit_cost_usd", precision = 10, scale = 4)
    private BigDecimal targetUnitCostUsd;

    @Column(name = "required_by_date", nullable = false)
    private LocalDate requiredByDate;

    @Column(name = "submission_deadline", nullable = false)
    private LocalDate submissionDeadline;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private Status status = Status.DRAFT;

    @Column(name = "created_by", nullable = false, length = 100)
    private String createdBy;

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

    @OneToMany(mappedBy = "rfq", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private List<RfqVendor> invitedVendors = new ArrayList<>();

    @OneToMany(mappedBy = "rfq", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private List<VendorQuote> quotes = new ArrayList<>();

    @OneToOne(mappedBy = "rfq", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private RfqAward award;

    public enum Status { DRAFT, OPEN, UNDER_REVIEW, AWARDED, CANCELLED }
}
