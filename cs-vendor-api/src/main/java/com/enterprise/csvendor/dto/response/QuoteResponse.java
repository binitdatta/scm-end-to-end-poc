package com.enterprise.csvendor.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class QuoteResponse {

    private String externalId;
    private String rfqNumber;
    private String vendorExternalId;
    private String vendorName;
    private String vendorCode;
    private String vendorCountry;
    private BigDecimal quotedUnitCostUsd;
    private Integer quotedQuantity;
    private BigDecimal totalCostUsd;
    private Integer leadTimeDays;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate deliveryDate;

    private String paymentTerms;
    private String notes;
    private String status;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime submittedAt;
}
