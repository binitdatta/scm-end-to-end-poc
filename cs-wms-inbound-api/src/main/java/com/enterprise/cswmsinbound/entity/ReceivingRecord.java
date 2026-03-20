package com.enterprise.cswmsinbound.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "receiving_records")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ReceivingRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "external_id",        nullable = false, unique = true, length = 64)
    private String externalId;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "asn_id",         nullable = false, unique = true)
    private AdvanceShipmentNotice asn;

    @Column(name = "received_quantity",  nullable = false)
    private Integer receivedQuantity;

    @Column(name = "damaged_quantity",   nullable = false)
    private Integer damagedQuantity = 0;

    @Column(name = "rejected_quantity",  nullable = false)
    private Integer rejectedQuantity = 0;

    @Column(name = "accepted_quantity",  nullable = false)
    private Integer acceptedQuantity;

    @Column(name = "variance_quantity")
    private Integer varianceQuantity;

    @Column(name = "received_by",        nullable = false, length = 100)
    private String receivedBy;

    @Column(name = "received_at",        nullable = false)
    private LocalDateTime receivedAt;

    @Column(name = "qc_passed",          nullable = false)
    private boolean qcPassed = false;

    @Column(name = "qc_notes", columnDefinition = "TEXT")
    private String qcNotes;

    @PrePersist
    protected void onCreate() {
        if (receivedAt == null) receivedAt = LocalDateTime.now();
    }
}
