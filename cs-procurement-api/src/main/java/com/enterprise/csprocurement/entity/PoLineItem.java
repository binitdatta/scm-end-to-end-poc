package com.enterprise.csprocurement.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;

@Entity
@Table(name = "po_line_items")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class PoLineItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "external_id", nullable = false, unique = true, length = 64)
    private String externalId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "po_id", nullable = false)
    private PurchaseOrder purchaseOrder;

    @Column(name = "line_number", nullable = false)
    private Integer lineNumber;

    @Column(name = "item_code", nullable = false, length = 50)
    private String itemCode;

    @Column(name = "description", nullable = false, length = 200)
    private String description;

    @Column(name = "quantity", nullable = false)
    private Integer quantity;

    @Column(name = "unit", nullable = false, length = 30)
    private String unit = "PIECES";

    @Column(name = "unit_price_usd", nullable = false, precision = 10, scale = 4)
    private BigDecimal unitPriceUsd;

    @Column(name = "line_total_usd", nullable = false, precision = 15, scale = 2)
    private BigDecimal lineTotalUsd;
}
