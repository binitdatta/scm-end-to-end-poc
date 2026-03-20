package com.enterprise.csvendor.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "rfq_vendors")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RfqVendor {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "rfq_id", nullable = false)
    private Rfq rfq;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vendor_id", nullable = false)
    private Vendor vendor;

    @Column(name = "invited_at", nullable = false)
    private LocalDateTime invitedAt;

    @PrePersist
    protected void onCreate() {
        if (invitedAt == null) invitedAt = LocalDateTime.now();
    }
}
