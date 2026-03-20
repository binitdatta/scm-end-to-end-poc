package com.enterprise.csvendor.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class VendorResponse {

    private String externalId;
    private String vendorName;
    private String vendorCode;
    private String country;
    private String contactName;
    private String contactEmail;
    private String contactPhone;
    private String address;
    private String status;
    private String category;
    private Integer leadTimeDays;
    private String paymentTerms;
    private BigDecimal scorecardRating;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdAt;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime updatedAt;
}
