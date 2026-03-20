package com.enterprise.csvendor.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "rfq_awards")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RfqAward {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "external_id", nullable = false, unique = true, length = 64)
    private String externalId;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "rfq_id", nullable = false)
    private Rfq rfq;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "winning_vendor_id", nullable = false)
    private Vendor winningVendor;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "winning_quote_id", nullable = false)
    private VendorQuote winningQuote;

    @Column(name = "awarded_quantity", nullable = false)
    private Integer awardedQuantity;

    @Column(name = "awarded_unit_cost_usd", nullable = false, precision = 10, scale = 4)
    private BigDecimal awardedUnitCostUsd;

    @Column(name = "total_award_value_usd", nullable = false, precision = 15, scale = 2)
    private BigDecimal totalAwardValueUsd;

    @Column(name = "award_notes", columnDefinition = "TEXT")
    private String awardNotes;

    @Column(name = "awarded_by", nullable = false, length = 100)
    private String awardedBy;

    @Column(name = "awarded_at", nullable = false)
    private LocalDateTime awardedAt;

    @Column(name = "rabbitmq_published", nullable = false)
    private boolean rabbitmqPublished = false;

    @PrePersist
    protected void onCreate() {
        if (awardedAt == null) awardedAt = LocalDateTime.now();
    }
}
