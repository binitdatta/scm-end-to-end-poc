package com.enterprise.csoms.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "store_order_lines")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class StoreOrderLine {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "external_id",       nullable = false, unique = true, length = 64)
    private String externalId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "store_order_id", nullable = false)
    private StoreOrder storeOrder;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "store_id",       nullable = false)
    private Store store;

    @Column(name = "sku",               nullable = false, length = 50)
    private String sku;

    @Column(name = "quantity_allocated", nullable = false)
    private Integer quantityAllocated = 0;

    @Column(name = "quantity_shipped",   nullable = false)
    private Integer quantityShipped = 0;

    @Column(name = "quantity_delivered", nullable = false)
    private Integer quantityDelivered = 0;

    @Enumerated(EnumType.STRING)
    @Column(name = "status",            nullable = false, length = 20)
    private Status status = Status.PENDING;

    public enum Status { PENDING, ALLOCATED, SHIPPED, DELIVERED, CANCELLED }
}
