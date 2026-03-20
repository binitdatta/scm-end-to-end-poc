package com.enterprise.csprocurement.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class PoResponse {

    private String externalId;
    private String poNumber;
    private String rfqExternalId;
    private String rfqNumber;
    private String campaignExternalId;
    private String campaignCode;
    private String awardExternalId;

    // Vendor
    private String vendorExternalId;
    private String vendorCode;
    private String vendorName;
    private String vendorCountry;

    // Order details
    private String     toyDescription;
    private Integer    quantityOrdered;
    private BigDecimal unitPriceUsd;
    private BigDecimal totalValueUsd;
    private String     currency;
    private String     paymentTerms;
    private String     incoterms;
    private String     destinationPort;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate requiredDeliveryDate;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate estimatedShipDate;

    // Lifecycle
    private String status;
    private String createdBy;
    private String approvedBy;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime approvedAt;

    private String notes;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdAt;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime updatedAt;

    private List<LineItemResponse> lineItems;

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class LineItemResponse {
        private String     externalId;
        private Integer    lineNumber;
        private String     itemCode;
        private String     description;
        private Integer    quantity;
        private String     unit;
        private BigDecimal unitPriceUsd;
        private BigDecimal lineTotalUsd;
    }
}
