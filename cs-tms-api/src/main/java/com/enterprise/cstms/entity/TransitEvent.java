package com.enterprise.cstms.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "transit_events")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TransitEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "delivery_load_id", nullable = false)
    private DeliveryLoad deliveryLoad;

    @Column(name = "event_code",        nullable = false, length = 50)
    private String eventCode;

    @Column(name = "event_description", length = 255)
    private String eventDescription;

    @Column(name = "location",          length = 200)
    private String location;

    @Column(name = "event_at",          nullable = false)
    private LocalDateTime eventAt;

    @Column(name = "recorded_at",       nullable = false)
    private LocalDateTime recordedAt;

    @Column(name = "source",            length = 50)
    private String source;

    @PrePersist
    protected void onCreate() { if (recordedAt == null) recordedAt = LocalDateTime.now(); }
}
