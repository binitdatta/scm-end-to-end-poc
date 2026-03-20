package com.enterprise.cstms.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;
import java.time.LocalDate;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CreateDeliveryLoadRequest {

    @NotBlank @Size(max = 50)
    private String loadNumber;

    @NotBlank @Size(max = 64)
    private String shipmentExternalId;

    @NotBlank @Size(max = 50)
    private String shipmentNumber;

    @NotBlank @Size(max = 64)
    private String storeOrderExternalId;

    @NotBlank @Size(max = 50)
    private String storeOrderNumber;

    @NotBlank @Size(max = 64)
    private String campaignExternalId;

    @NotBlank @Size(max = 50)
    private String campaignCode;

    @NotBlank @Size(max = 20)
    private String regionCode;

    @Size(max = 50)
    private String distributionDc;

    @NotBlank @Size(max = 50)
    private String sku;

    @NotBlank @Size(max = 200)
    private String toyDescription;

    @NotNull @Min(1)
    private Integer totalCartons;

    @NotNull @Min(1)
    private Integer totalUnits;

    @NotBlank @Size(max = 100)
    private String carrierName;

    @NotBlank @Size(max = 100)
    private String proNumber;

    @NotNull
    private LocalDate requiredDeliveryDate;

    @NotBlank
    private String createdBy;

    private String notes;

    /** Per-store carton details from WMS shipment */
    @NotNull @NotEmpty
    private List<StoreCartonInput> storeCartons;

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class StoreCartonInput {
        @NotBlank private String  storeExternalId;
        @NotBlank private String  storeNumber;
        @NotBlank private String  storeName;
        private String  city;
        private String  stateCode;
        @NotBlank private String  sku;
        @NotNull  @Min(1) private Integer quantity;
        private String  cartonLabel;
    }
}
