package com.enterprise.cswmsoutbound.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "outbound_shipments")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class OutboundShipment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "external_id",              nullable = false, unique = true, length = 64)
    private String externalId;

    @Column(name = "shipment_number",          nullable = false, unique = true, length = 50)
    private String shipmentNumber;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "pick_wave_id",         nullable = false, unique = true)
    private PickWave pickWave;

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

    @Column(name = "distribution_dc",          length = 50)
    private String distributionDc;

    @Column(name = "sku",                      nullable = false, length = 50)
    private String sku;

    @Column(name = "toy_description",          nullable = false, length = 200)
    private String toyDescription;

    @Column(name = "total_cartons",            nullable = false)
    private Integer totalCartons;

    @Column(name = "total_units",              nullable = false)
    private Integer totalUnits;

    @Column(name = "units_per_carton",         nullable = false)
    private Integer unitsPerCarton = 1;

    @Column(name = "carrier_name",             length = 100)
    private String carrierName;

    @Column(name = "pro_number",               length = 100)
    private String proNumber;

    @Column(name = "destination_region",       length = 100)
    private String destinationRegion;

    @Column(name = "required_delivery_date",   nullable = false)
    private LocalDate requiredDeliveryDate;

    @Column(name = "estimated_ship_date")
    private LocalDate estimatedShipDate;

    @Column(name = "actual_ship_date")
    private LocalDate actualShipDate;

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

    @OneToMany(mappedBy = "shipment", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private List<ShipmentStoreLine> storeLines = new ArrayList<>();

    public enum Status { CREATED, PACKED, MANIFESTED, DISPATCHED, CANCELLED }
}
