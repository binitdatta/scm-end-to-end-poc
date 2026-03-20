package com.enterprise.cswmsinbound.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ReceivingResponse {
    private String  externalId;
    private String  asnNumber;
    private Integer receivedQuantity;
    private Integer damagedQuantity;
    private Integer rejectedQuantity;
    private Integer acceptedQuantity;
    private Integer varianceQuantity;
    private String  receivedBy;
    private boolean qcPassed;
    private String  qcNotes;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime receivedAt;
}
