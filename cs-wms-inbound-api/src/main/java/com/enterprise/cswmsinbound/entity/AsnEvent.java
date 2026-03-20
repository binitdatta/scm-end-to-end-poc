package com.enterprise.cswmsinbound.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "asn_events")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AsnEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "asn_id", nullable = false)
    private AdvanceShipmentNotice asn;

    @Column(name = "event_type",        nullable = false, length = 80)
    private String eventType;

    @Column(name = "previous_status",   length = 30)
    private String previousStatus;

    @Column(name = "new_status",        nullable = false, length = 30)
    private String newStatus;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    @Column(name = "triggered_by",      nullable = false, length = 100)
    private String triggeredBy;

    @Column(name = "event_at",          nullable = false)
    private LocalDateTime eventAt;

    @Column(name = "rabbitmq_published", nullable = false)
    private boolean rabbitmqPublished = false;

    @PrePersist
    protected void onCreate() {
        if (eventAt == null) eventAt = LocalDateTime.now();
    }
}
