package com.enterprise.cswmsinbound.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "inventory_locations")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class InventoryLocation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "sku",                  nullable = false, length = 50)
    private String sku;

    @Column(name = "campaign_code",        nullable = false, length = 50)
    private String campaignCode;

    @Column(name = "warehouse_zone",       nullable = false, length = 20)
    private String warehouseZone;

    @Column(name = "warehouse_aisle",      length = 10)
    private String warehouseAisle;

    @Column(name = "warehouse_bin",        nullable = false, length = 20)
    private String warehouseBin;

    @Column(name = "quantity_on_hand",     nullable = false)
    private Integer quantityOnHand = 0;

    @Column(name = "quantity_reserved",    nullable = false)
    private Integer quantityReserved = 0;

    @Column(name = "quantity_available",   nullable = false)
    private Integer quantityAvailable = 0;

    @Column(name = "last_receipt_date")
    private LocalDate lastReceiptDate;

    @Column(name = "last_updated_at",      nullable = false)
    private LocalDateTime lastUpdatedAt;

    @PrePersist @PreUpdate
    protected void onUpdate() {
        lastUpdatedAt = LocalDateTime.now();
    }
}
