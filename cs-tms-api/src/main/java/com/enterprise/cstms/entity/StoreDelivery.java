package com.enterprise.cstms.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "store_deliveries")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class StoreDelivery {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "external_id",       nullable = false, unique = true, length = 64)
    private String externalId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "delivery_load_id", nullable = false)
    private DeliveryLoad deliveryLoad;

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

    @Column(name = "delivered_quantity")
    private Integer deliveredQuantity;

    @Column(name = "pod_signatory",     length = 100)
    private String podSignatory;

    @Column(name = "pod_notes", columnDefinition = "TEXT")
    private String podNotes;

    @Column(name = "delivered_at")
    private LocalDateTime deliveredAt;

    @Column(name = "pod_confirmed_at")
    private LocalDateTime podConfirmedAt;

    @Enumerated(EnumType.STRING)
    @Column(name = "status",            nullable = false, length = 20)
    private Status status = Status.PENDING;

    public enum Status { PENDING, OUT_FOR_DELIVERY, DELIVERED, POD_CONFIRMED, FAILED }
}
