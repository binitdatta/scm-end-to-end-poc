package com.enterprise.csoms.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;
import java.time.LocalDate;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CreateStoreOrderRequest {

    @NotBlank @Size(max = 50)
    private String orderNumber;

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
    private Integer quantityRequested;

    @NotNull
    private LocalDate requestedDeliveryDate;

    @NotBlank
    private String createdBy;

    private String notes;
}
