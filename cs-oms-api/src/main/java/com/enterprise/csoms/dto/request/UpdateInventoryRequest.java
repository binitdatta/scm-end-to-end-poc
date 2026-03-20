package com.enterprise.csoms.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class UpdateInventoryRequest {

    @NotBlank @Size(max = 50)
    private String sku;

    @NotBlank @Size(max = 50)
    private String campaignCode;

    @NotNull @Min(0)
    private Integer quantityAvailable;

    @Size(max = 50)
    private String sourceAsnNumber;
}
