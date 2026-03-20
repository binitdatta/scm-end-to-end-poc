package com.enterprise.csvendor.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CreateRfqRequest {

    @NotBlank @Size(max = 50)
    private String rfqNumber;

    @NotBlank @Size(max = 64)
    private String campaignExternalId;

    @NotBlank @Size(max = 50)
    private String campaignCode;

    @NotBlank @Size(max = 200)
    private String title;

    private String description;

    @Size(max = 100)
    private String toyCategory;

    @NotNull @Min(1)
    private Integer quantityRequired;

    @DecimalMin("0.0001")
    private BigDecimal targetUnitCostUsd;

    @NotNull
    private LocalDate requiredByDate;

    @NotNull
    private LocalDate submissionDeadline;

    @NotBlank
    private String createdBy;

    /** Optional: vendor externalIds to invite immediately on creation */
    private List<String> inviteVendorIds;
}
