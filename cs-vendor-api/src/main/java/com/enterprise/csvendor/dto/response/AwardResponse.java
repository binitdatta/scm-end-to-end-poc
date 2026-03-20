package com.enterprise.csvendor.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AwardResponse {

    private String externalId;
    private String rfqNumber;
    private String campaignCode;

    // Winning vendor summary
    private String winningVendorExternalId;
    private String winningVendorCode;
    private String winningVendorName;
    private String winningVendorCountry;

    // Award financials
    private Integer awardedQuantity;
    private BigDecimal awardedUnitCostUsd;
    private BigDecimal totalAwardValueUsd;

    private String awardNotes;
    private String awardedBy;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime awardedAt;
}
