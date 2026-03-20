package com.enterprise.csoms.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "store_regions")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class StoreRegion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "external_id",    nullable = false, unique = true, length = 64)
    private String externalId;

    @Column(name = "region_code",    nullable = false, unique = true, length = 20)
    private String regionCode;

    @Column(name = "region_name",    nullable = false, length = 100)
    private String regionName;

    @Column(name = "store_count",    nullable = false)
    private Integer storeCount = 0;

    @Column(name = "distribution_dc", length = 50)
    private String distributionDc;

    @Enumerated(EnumType.STRING)
    @Column(name = "status",         nullable = false, length = 10)
    private Status status = Status.ACTIVE;

    @Column(name = "created_at",     nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() { createdAt = LocalDateTime.now(); }

    @OneToMany(mappedBy = "region", fetch = FetchType.LAZY)
    @Builder.Default
    private List<Store> stores = new ArrayList<>();

    public enum Status { ACTIVE, INACTIVE }
}
