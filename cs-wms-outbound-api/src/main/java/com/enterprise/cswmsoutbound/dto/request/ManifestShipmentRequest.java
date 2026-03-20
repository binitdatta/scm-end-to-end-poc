package com.enterprise.cswmsoutbound.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ManifestShipmentRequest {

    @NotBlank
    private String carrierName;

    @NotBlank
    private String proNumber;

    private String notes;
}
