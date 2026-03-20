package com.enterprise.csprocurement.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CreatePoRequest {

    @NotBlank @Size(max = 50)
    private String poNumber;

    @NotBlank @Size(max = 64)
    private String rfqExternalId;

    @NotBlank @Size(max = 50)
    private String rfqNumber;

    @NotBlank @Size(max = 64)
    private String campaignExternalId;

    @NotBlank @Size(max = 50)
    private String campaignCode;

    @NotBlank @Size(max = 64)
    private String awardExternalId;

    @NotBlank @Size(max = 64)
    private String vendorExternalId;

    @NotBlank @Size(max = 50)
    private String vendorCode;

    @NotBlank @Size(max = 200)
    private String vendorName;

    @NotBlank
    private String vendorCountry;

    @NotBlank @Size(max = 200)
    private String toyDescription;

    @NotNull @Min(1)
    private Integer quantityOrdered;

    @NotNull @DecimalMin("0.0001")
    private BigDecimal unitPriceUsd;

    @Size(max = 100)
    private String paymentTerms;

    @NotNull
    private LocalDate requiredDeliveryDate;

    private LocalDate estimatedShipDate;

    @Size(max = 20)
    private String incoterms;

    @Size(max = 100)
    private String destinationPort;

    @NotBlank
    private String createdBy;

    private String notes;

    private List<LineItemRequest> lineItems;

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class LineItemRequest {
        @NotBlank  private String     itemCode;
        @NotBlank  private String     description;
        @NotNull   private Integer    quantity;
        @NotNull   private BigDecimal unitPriceUsd;
    }
}
