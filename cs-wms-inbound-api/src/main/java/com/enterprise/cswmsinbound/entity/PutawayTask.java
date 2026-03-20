package com.enterprise.cswmsinbound.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "putaway_tasks")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class PutawayTask {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "external_id",          nullable = false, unique = true, length = 64)
    private String externalId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "asn_id",           nullable = false)
    private AdvanceShipmentNotice asn;

    @Column(name = "sku",                  nullable = false, length = 50)
    private String sku;

    @Column(name = "quantity_to_putaway",  nullable = false)
    private Integer quantityToPutaway;

    @Column(name = "quantity_putaway",     nullable = false)
    private Integer quantityPutaway = 0;

    @Column(name = "warehouse_zone",       nullable = false, length = 20)
    private String warehouseZone;

    @Column(name = "warehouse_aisle",      length = 10)
    private String warehouseAisle;

    @Column(name = "warehouse_bin",        nullable = false, length = 20)
    private String warehouseBin;

    @Enumerated(EnumType.STRING)
    @Column(name = "status",              nullable = false, length = 20)
    private Status status = Status.PENDING;

    @Column(name = "assigned_to",         length = 100)
    private String assignedTo;

    @Column(name = "started_at")
    private LocalDateTime startedAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "created_at",          nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at",          nullable = false)
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

    public enum Status { PENDING, IN_PROGRESS, COMPLETED, CANCELLED }
}
