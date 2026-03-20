package com.enterprise.csoms.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "store_orders")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class StoreOrder {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "external_id",           nullable = false, unique = true, length = 64)
    private String externalId;

    @Column(name = "order_number",          nullable = false, unique = true, length = 50)
    private String orderNumber;

    @Column(name = "campaign_external_id",  nullable = false, length = 64)
    private String campaignExternalId;

    @Column(name = "campaign_code",         nullable = false, length = 50)
    private String campaignCode;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "region_id",         nullable = false)
    private StoreRegion region;

    @Column(name = "sku",                   nullable = false, length = 50)
    private String sku;

    @Column(name = "toy_description",       nullable = false, length = 200)
    private String toyDescription;

    @Column(name = "quantity_requested",    nullable = false)
    private Integer quantityRequested;

    @Column(name = "quantity_allocated",    nullable = false)
    private Integer quantityAllocated = 0;

    @Column(name = "quantity_per_store")
    private Integer quantityPerStore;

    @Column(name = "requested_delivery_date", nullable = false)
    private LocalDate requestedDeliveryDate;

    @Column(name = "allocated_at")
    private LocalDateTime allocatedAt;

    @Enumerated(EnumType.STRING)
    @Column(name = "status",               nullable = false, length = 20)
    private Status status = Status.DRAFT;

    @Column(name = "created_by",           nullable = false, length = 100)
    private String createdBy;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

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
    protected void onUpdate() { updatedAt = LocalDateTime.now(); }

    @OneToMany(mappedBy = "storeOrder", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private List<StoreOrderLine> orderLines = new ArrayList<>();

    @OneToMany(mappedBy = "storeOrder", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private List<OrderEvent> events = new ArrayList<>();

    public enum Status {
        DRAFT, SUBMITTED, ALLOCATED, PICKING, SHIPPED, DELIVERED, CANCELLED
    }
}
