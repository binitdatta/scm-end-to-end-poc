package com.enterprise.cswmsoutbound.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "shipment_store_lines")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ShipmentStoreLine {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "external_id",       nullable = false, unique = true, length = 64)
    private String externalId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shipment_id",   nullable = false)
    private OutboundShipment shipment;

    @Column(name = "store_external_id", nullable = false, length = 64)
    private String storeExternalId;

    @Column(name = "store_number",      nullable = false, length = 20)
    private String storeNumber;

    @Column(name = "store_name",        nullable = false, length = 150)
    private String storeName;

    @Column(name = "city",              length = 100)
    private String city;

    @Column(name = "state_code",        length = 10)
    private String stateCode;

    @Column(name = "sku",               nullable = false, length = 50)
    private String sku;

    @Column(name = "quantity",          nullable = false)
    private Integer quantity;

    @Column(name = "carton_label",      length = 50)
    private String cartonLabel;

    @Enumerated(EnumType.STRING)
    @Column(name = "status",            nullable = false, length = 20)
    private Status status = Status.PENDING;

    public enum Status { PENDING, PACKED, DISPATCHED, DELIVERED }
}
