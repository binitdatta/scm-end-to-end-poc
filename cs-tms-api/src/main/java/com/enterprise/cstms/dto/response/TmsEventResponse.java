package com.enterprise.cstms.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TmsEventResponse {
    private Long    id;
    private String  eventType;
    private String  previousStatus;
    private String  newStatus;
    private String  notes;
    private String  triggeredBy;
    private boolean rabbitmqPublished;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime eventAt;
}
