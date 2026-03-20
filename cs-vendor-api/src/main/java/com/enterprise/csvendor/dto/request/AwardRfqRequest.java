package com.enterprise.csvendor.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AwardRfqRequest {

    @NotBlank
    private String winningVendorExternalId;

    @NotNull @Min(1)
    private Integer awardedQuantity;

    @NotBlank
    private String awardedBy;

    private String awardNotes;
}
