package com.enterprise.cscrm.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CreateCampaignRequest {

    @NotBlank(message = "Campaign name is required")
    @Size(max = 200)
    private String campaignName;

    @NotBlank(message = "Campaign code is required")
    @Size(max = 50)
    private String campaignCode;

    private String description;

    @NotBlank
    private String campaignType;   // TOY_SURPRISE | SEASONAL | LOYALTY | PROMO

    @NotNull
    @DecimalMin("0.00")
    private BigDecimal budgetUsd;

    @NotNull
    private LocalDate startDate;

    @NotNull
    private LocalDate endDate;

    private String targetRegion;

    @NotBlank
    private String createdBy;
}
