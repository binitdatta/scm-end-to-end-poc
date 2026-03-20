package com.enterprise.cswmsoutbound.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;
import java.time.LocalDate;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CreateShipmentRequest {

    @NotBlank @Size(max = 50)
    private String shipmentNumber;

    @NotBlank @Size(max = 64)
    private String pickWaveExternalId;

    @Size(max = 50)
    private String distributionDc;

    @Size(max = 100)
    private String carrierName;

    @NotNull
    private LocalDate requiredDeliveryDate;

    private LocalDate estimatedShipDate;

    @NotBlank
    private String createdBy;

    private String notes;

    /** Per-store carton breakdown */
    @NotNull @NotEmpty
    private List<StoreCartonRequest> storeCartons;

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class StoreCartonRequest {
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
