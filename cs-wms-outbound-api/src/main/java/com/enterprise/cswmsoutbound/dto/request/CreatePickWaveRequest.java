package com.enterprise.cswmsoutbound.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;
import java.time.LocalDate;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CreatePickWaveRequest {

    @NotBlank @Size(max = 50)
    private String waveNumber;

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

    @NotBlank @Size(max = 50)
    private String sku;

    @NotBlank @Size(max = 200)
    private String toyDescription;

    @NotNull @Min(1)
    private Integer totalQuantity;

    @Size(max = 20)
    private String pickZone;

    @NotNull
    private LocalDate requiredShipDate;

    @NotBlank
    private String createdBy;

    private String notes;

    /** Bin locations to pick from */
    private List<BinSource> binSources;

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class BinSource {
        @NotBlank private String  warehouseZone;
        @NotBlank private String  warehouseAisle;
        @NotBlank private String  warehouseBin;
        @NotNull  @Min(1) private Integer quantityToPick;
    }
}
