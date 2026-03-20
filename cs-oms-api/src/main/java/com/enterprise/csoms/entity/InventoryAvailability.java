package com.enterprise.csoms.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "inventory_availability")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class InventoryAvailability {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "sku",               nullable = false, length = 50)
    private String sku;

    @Column(name = "campaign_code",     nullable = false, length = 50)
    private String campaignCode;

    @Column(name = "quantity_available", nullable = false)
    private Integer quantityAvailable = 0;

    @Column(name = "quantity_reserved",  nullable = false)
    private Integer quantityReserved = 0;

    @Column(name = "quantity_remaining", nullable = false)
    private Integer quantityRemaining = 0;

    @Column(name = "source_asn_number",  length = 50)
    private String sourceAsnNumber;

    @Column(name = "last_updated_at",   nullable = false)
    private LocalDateTime lastUpdatedAt;

    @PrePersist @PreUpdate
    protected void onUpdate() { lastUpdatedAt = LocalDateTime.now(); }
}
