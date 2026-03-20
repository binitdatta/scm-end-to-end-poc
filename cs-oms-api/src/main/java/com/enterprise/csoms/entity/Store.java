package com.enterprise.csoms.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "stores")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Store {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "external_id",   nullable = false, unique = true, length = 64)
    private String externalId;

    @Column(name = "store_number",  nullable = false, unique = true, length = 20)
    private String storeNumber;

    @Column(name = "store_name",    nullable = false, length = 150)
    private String storeName;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "region_id", nullable = false)
    private StoreRegion region;

    @Column(name = "address",       length = 255)
    private String address;

    @Column(name = "city",          length = 100)
    private String city;

    @Column(name = "state_code",    length = 10)
    private String stateCode;

    @Column(name = "zip_code",      length = 10)
    private String zipCode;

    @Enumerated(EnumType.STRING)
    @Column(name = "status",        nullable = false, length = 10)
    private Status status = Status.ACTIVE;

    @Column(name = "created_at",    nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() { createdAt = LocalDateTime.now(); }

    public enum Status { ACTIVE, INACTIVE, CLOSED }
}
