package com.enterprise.csvendor.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class SubmitQuoteRequest {

    @NotBlank
    private String vendorExternalId;

    @NotNull @DecimalMin("0.0001")
    private BigDecimal quotedUnitCostUsd;

    @NotNull @Min(1)
    private Integer quotedQuantity;

    @NotNull @Min(1)
    private Integer leadTimeDays;

    @NotNull
    private LocalDate deliveryDate;

    @Size(max = 100)
    private String paymentTerms;

    private String notes;
}
