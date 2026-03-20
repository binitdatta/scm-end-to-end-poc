package com.enterprise.csvendor.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RfqResponse {

    private String externalId;
    private String rfqNumber;
    private String campaignExternalId;
    private String campaignCode;
    private String title;
    private String description;
    private String toyCategory;
    private Integer quantityRequired;
    private String unit;
    private BigDecimal targetUnitCostUsd;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate requiredByDate;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate submissionDeadline;

    private String status;
    private String createdBy;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdAt;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime updatedAt;
}
