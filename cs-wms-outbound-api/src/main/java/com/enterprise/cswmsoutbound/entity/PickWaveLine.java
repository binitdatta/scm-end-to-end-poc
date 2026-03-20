package com.enterprise.cswmsoutbound.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "pick_wave_lines")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class PickWaveLine {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "external_id",       nullable = false, unique = true, length = 64)
    private String externalId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "pick_wave_id",  nullable = false)
    private PickWave pickWave;

    @Column(name = "sku",               nullable = false, length = 50)
    private String sku;

    @Column(name = "warehouse_zone",    length = 20)
    private String warehouseZone;

    @Column(name = "warehouse_aisle",   length = 10)
    private String warehouseAisle;

    @Column(name = "warehouse_bin",     nullable = false, length = 20)
    private String warehouseBin;

    @Column(name = "quantity_to_pick",  nullable = false)
    private Integer quantityToPick;

    @Column(name = "quantity_picked",   nullable = false)
    private Integer quantityPicked = 0;

    @Enumerated(EnumType.STRING)
    @Column(name = "status",            nullable = false, length = 20)
    private Status status = Status.PENDING;

    public enum Status { PENDING, PICKED, SHORT, CANCELLED }
}
