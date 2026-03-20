package com.enterprise.cswmsinbound.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ReceiveShipmentRequest {

    @NotNull @Min(0)
    private Integer receivedQuantity;

    @Min(0)
    private Integer damagedQuantity;

    @Min(0)
    private Integer rejectedQuantity;

    @NotBlank
    private String receivedBy;

    private Boolean qcPassed;
    private String  qcNotes;
}
