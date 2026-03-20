package com.enterprise.cswmsoutbound.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "pick_waves")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class PickWave {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "external_id",              nullable = false, unique = true, length = 64)
    private String externalId;

    @Column(name = "wave_number",              nullable = false, unique = true, length = 50)
    private String waveNumber;

    @Column(name = "store_order_external_id",  nullable = false, length = 64)
    private String storeOrderExternalId;

    @Column(name = "store_order_number",       nullable = false, length = 50)
    private String storeOrderNumber;

    @Column(name = "campaign_external_id",     nullable = false, length = 64)
    private String campaignExternalId;

    @Column(name = "campaign_code",            nullable = false, length = 50)
    private String campaignCode;

    @Column(name = "region_code",              nullable = false, length = 20)
    private String regionCode;

    @Column(name = "sku",                      nullable = false, length = 50)
    private String sku;

    @Column(name = "toy_description",          nullable = false, length = 200)
    private String toyDescription;

    @Column(name = "total_quantity",           nullable = false)
    private Integer totalQuantity;

    @Column(name = "picked_quantity",          nullable = false)
    private Integer pickedQuantity = 0;

    @Column(name = "pick_zone",                length = 20)
    private String pickZone;

    @Column(name = "assigned_to",              length = 100)
    private String assignedTo;

    @Column(name = "required_ship_date",       nullable = false)
    private LocalDate requiredShipDate;

    @Column(name = "started_at")
    private LocalDateTime startedAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Enumerated(EnumType.STRING)
    @Column(name = "status",                   nullable = false, length = 20)
    private Status status = Status.CREATED;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    @Column(name = "created_by",               nullable = false, length = 100)
    private String createdBy;

    @Column(name = "created_at",               nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at",               nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() { updatedAt = LocalDateTime.now(); }

    @OneToMany(mappedBy = "pickWave", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private List<PickWaveLine> lines = new ArrayList<>();

    @OneToOne(mappedBy = "pickWave", fetch = FetchType.LAZY)
    private OutboundShipment shipment;

    public enum Status { CREATED, ASSIGNED, PICKING, COMPLETED, CANCELLED }
}
