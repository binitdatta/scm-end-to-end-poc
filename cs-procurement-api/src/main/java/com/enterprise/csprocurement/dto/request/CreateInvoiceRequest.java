package com.enterprise.csprocurement.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CreateInvoiceRequest {

    @NotBlank @Size(max = 50)
    private String invoiceNumber;

    @NotNull @DecimalMin("0.01")
    private BigDecimal invoiceAmountUsd;

    @DecimalMin("0.00")
    private BigDecimal taxAmountUsd;

    @NotNull
    private LocalDate invoiceDate;

    @NotNull
    private LocalDate dueDate;

    private String notes;
}
